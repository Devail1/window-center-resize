# build/build-portable.ps1 — builds the portable, NON-compiled distribution.
#
# Why this exists instead of build.ps1's compiled exe: Ahk2Exe welds the script into a copy
# of AutoHotkey64.exe as a resource. That 1.4% modification is what Defender's ML classifiers
# score as a script dropper, because appending a script to the AutoHotkey interpreter is a
# genuinely common malware technique. Measured 2026-09-12, same Microsoft engine build:
#
#   stock AutoHotkey64.exe          0/70,  Microsoft undetected
#   compiled WindowCenterResizer    3/71,  Microsoft Trojan:Win32/Wacatac.B!ml
#
# Both unsigned, 17,920 bytes apart. So this build ships the interpreter BYTE-IDENTICAL and
# keeps the script beside it as plain text. The exe inherits the stock binary's reputation
# because it IS the stock binary — reputation is keyed on hash, and renaming does not
# change bytes.
#
# ⛔ Never patch the icon or version resource into this exe. Either one changes the hash and
# forfeits the entire reason the build exists. The tray icon is set at runtime instead; see
# the TraySetIcon block at the bottom of src\main.ahk.
$ErrorActionPreference = "Stop"

$root    = Split-Path -Parent $PSScriptRoot
$stock   = "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
$outDir  = Join-Path $root "dist\portable"
$outExe  = Join-Path $outDir "WindowCenterResizer.exe"
$outAhk  = Join-Path $outDir "WindowCenterResizer.ahk"
$outIco  = Join-Path $outDir "icon.ico"
$outZip  = Join-Path $root "dist\Window-Center-Resize-portable.zip"

if (-not (Test-Path $stock)) {
    throw "AutoHotkey v2 interpreter not found at $stock. Install AutoHotkey v2 first."
}

# build/interpreter.pin is the single source of truth for which AutoHotkey release this project
# ships and tests against. Without this check the build copies whatever is installed locally
# while CI keeps testing the version IT pins — so one `winget upgrade` would ship an interpreter
# no test ever ran against, silently. Worse here than the usual untested-dependency problem: a
# just-released AutoHotkey has near-zero prevalence, which is the exact condition that got the
# 2.1.0 binary quarantined.
$pinFile = Join-Path $PSScriptRoot "interpreter.pin"
if (-not (Test-Path $pinFile)) { throw "Missing $pinFile" }
$pin = @{}
foreach ($line in [System.IO.File]::ReadAllLines($pinFile)) {
    if ($line -match '^\s*([a-z0-9]+)\s*=\s*(\S+)\s*$') { $pin[$Matches[1]] = $Matches[2] }
}
foreach ($k in @("version", "sha256")) {
    if (-not $pin.ContainsKey($k)) { throw "interpreter.pin has no '$k=' line" }
}

$installed = (Get-Item $stock).VersionInfo.FileVersion
if ($installed -ne $pin["version"]) {
    throw ("INTERPRETER PIN FAILED: installed AutoHotkey is $installed, but this project pins " +
           "$($pin['version']) (build\interpreter.pin). CI tests against the pinned version, so " +
           "shipping $installed would ship an interpreter nothing has tested. Either reinstall " +
           "$($pin['version']), or bump the pin deliberately - see docs\RELEASING.md step 2, and " +
           "note that a recently released version starts with no reputation.")
}

$pinnedHash = $pin["sha256"].ToLower()
$stockHash  = (Get-FileHash $stock -Algorithm SHA256).Hash.ToLower()
if ($stockHash -ne $pinnedHash) {
    throw ("INTERPRETER PIN FAILED: the installed AutoHotkey $installed hashes to $stockHash, " +
           "but the pin records $pinnedHash. The local install is not the binary the AutoHotkey " +
           "project published for this version. Reinstall from " +
           "https://github.com/AutoHotkey/AutoHotkey/releases/tag/v$($pin['version'])")
}

# A running instance holds an open handle on dist\portable\WindowCenterResizer.exe, so
# Copy-Item fails partway through and leaves the output folder half-written. Say which
# process, rather than surfacing an access-denied error about a path nobody recognises.
$running = Get-Process -Name "WindowCenterResizer" -ErrorAction SilentlyContinue
if ($running) {
    throw ("Cannot build: WindowCenterResizer.exe is running (PID {0}). " -f ($running.Id -join ", ")) +
          "Exit it from the tray, then rebuild."
}

# Flatten #Include into one script. AHK inserts an include's text at the #Include line and
# skips a file it has already included, so reproducing both rules here produces a script
# byte-equivalent in behaviour to what the interpreter would have assembled itself.
$script:seen = @{}
function Expand-Includes {
    param([string]$Path, [bool]$IsRoot = $false)

    $full = (Resolve-Path $Path).Path
    if ($script:seen.ContainsKey($full)) { return @() }   # #Include, not #IncludeAgain
    $script:seen[$full] = $true

    $dir = Split-Path -Parent $full
    $out = New-Object System.Collections.Generic.List[string]

    foreach ($line in [System.IO.File]::ReadAllLines($full)) {
        if ($line -match '^\s*#Include\s+"(.+)"\s*$') {
            # @() around the call: PowerShell unrolls a returned empty array to $null, and an
            # already-included file legitimately returns nothing.
            $sub = @(Expand-Includes (Join-Path $dir $Matches[1]))
            if ($sub.Count) { $out.AddRange([string[]]$sub) }
        }
        elseif (-not $IsRoot -and $line -match '^\s*#Requires\s') {
            # One #Requires at the top of the assembled script is enough.
        }
        else {
            $out.Add($line)
        }
    }
    return $out.ToArray()
}

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$lines = @(Expand-Includes (Join-Path $root "src\main.ahk") $true)
# UTF-8 *with* BOM: AHK v2 reads a BOM-less file as UTF-8 too, but the repo's sources carry
# one and the em dashes in the comments are not worth risking on that.
[System.IO.File]::WriteAllLines($outAhk, $lines, (New-Object System.Text.UTF8Encoding $true))

# The flattener only recognises #Include "quoted-path". AutoHotkey also accepts unquoted
# paths and <library> form, and either would be copied through verbatim - producing a script
# that looks built, zips cleanly, and fails at launch on a user's machine with a load-time
# error. Catch it here instead.
$leftover = $lines | Select-String -Pattern '^\s*#Include' -CaseSensitive:$false
if ($leftover) {
    throw "FLATTEN GATE FAILED: #Include survived into the output, so a source file was not " +
          "inlined. Unhandled directive(s): " + ($leftover -join "; ")
}

Copy-Item $stock  $outExe -Force
Copy-Item (Join-Path $root "assets\icon.ico") $outIco -Force

# THE gate. If these hashes ever differ, the shipped exe is no longer the binary Microsoft
# has a clean verdict on, and this whole build is pointless.
$shipHash = (Get-FileHash $outExe -Algorithm SHA256).Hash.ToLower()
if ($shipHash -ne $stockHash) {
    throw "INTERPRETER GATE FAILED: shipped exe $shipHash does not match stock $stockHash"
}

if (Test-Path $outZip) { Remove-Item $outZip -Force }
Compress-Archive -Path "$outDir\*" -DestinationPath $outZip

Write-Host ("Script    {0}  ({1} lines, {2:N0} bytes)" -f $outAhk, $lines.Count, (Get-Item $outAhk).Length)
Write-Host ("Exe       {0}  ({1:N0} bytes)" -f $outExe, (Get-Item $outExe).Length)
Write-Host ("SHA-256   {0}" -f $shipHash)
Write-Host ("Interpreter gate passed — shipped exe is AutoHotkey {0}, byte-identical to the release the AutoHotkey project published." -f $pin["version"])
Write-Host ("Zip       {0}  ({1:N0} bytes)" -f $outZip, (Get-Item $outZip).Length)
