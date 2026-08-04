# build/build.ps1 — compiles to a single portable exe. No UPX (antivirus false positives).
$ErrorActionPreference = "Stop"
$root     = Split-Path -Parent $PSScriptRoot
$ahk2exe  = "$env:LOCALAPPDATA\Programs\AutoHotkey\Compiler\Ahk2Exe.exe"
$base     = "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
$outDir   = Join-Path $root "dist"
$outExe   = Join-Path $outDir "WindowCenterResizer.exe"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# Fail fast if the target is running. Ahk2Exe cannot overwrite a locked file and does not
# error - it blocks indefinitely, which looks like a broken toolchain rather than "your app
# is open". Observed 2026-08-04: a test instance left running hung the build until killed.
$running = Get-Process -Name "WindowCenterResizer" -ErrorAction SilentlyContinue
if ($running) {
    throw ("Cannot build: WindowCenterResizer.exe is running (PID {0}). " -f ($running.Id -join ", ")) +
          "Exit it from the tray, then rebuild."
}

& $ahk2exe /in (Join-Path $root "src\main.ahk") `
           /out $outExe `
           /base $base `
           /icon (Join-Path $root "assets\icon.ico") `
           /compress 0

# Ahk2Exe.exe can return control before the output file is fully flushed to disk
# (observed: Test-Path false immediately after the call, file present moments later).
# Poll briefly rather than fail on that race.
$waited = 0
while (-not (Test-Path $outExe) -and $waited -lt 5000) {
    Start-Sleep -Milliseconds 250
    $waited += 250
}
if (-not (Test-Path $outExe)) { throw "Compilation produced no output" }

$sizeMB = (Get-Item $outExe).Length / 1MB
Write-Host ("Built {0} — {1:N2} MB" -f $outExe, $sizeMB)
if ($sizeMB -gt 2.0) { throw ("SIZE GATE FAILED: {0:N2} MB exceeds the 2 MB target" -f $sizeMB) }
Write-Host "Size gate passed."
