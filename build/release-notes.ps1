# build/release-notes.ps1 - emits the GitHub release body for a version.
#
# The release page used to be hand-written, which made it a second copy of CHANGELOG.md kept in
# step by hand. Two texts saying the same thing drift, and this one is public: Softpedia renders
# the CHANGELOG into its "What's New" panel, so a release page that disagrees with it is a
# visible contradiction rather than untidiness.
#
# So the changelog is the source and this generates the rest. Nothing to synchronise, because
# there is only one text. The install block is version-independent and lives here; the hashes
# are computed from the artifacts on disk, so what is published cannot disagree with what was
# built.
#
#   powershell -ExecutionPolicy Bypass -File build\release-notes.ps1 -Version 2.2.0
param([Parameter(Mandatory=$true)][string]$Version)
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$lines = [System.IO.File]::ReadAllLines((Join-Path $root "CHANGELOG.md"))

# Take everything under "## <Version>" up to the next "## " heading.
$start = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match ('^##\s+' + [regex]::Escape($Version) + '\s*$')) { $start = $i + 1; break }
}
if ($start -lt 0) {
    throw "CHANGELOG.md has no '## $Version' section. Write the changelog entry before releasing."
}
# Only the LEDE - everything before the section's first "### " subheading. The full entry is one
# click away and duplicating it here made the release page longer than the changelog it copied.
# This is also why the lede has to carry the most important thing: Softpedia truncates the
# CHANGELOG into its "What's New" panel, so the opening lines are what most people read in both
# places. Write them accordingly.
$body = New-Object System.Collections.Generic.List[string]
for ($i = $start; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^##\s+\S' -or $lines[$i] -match '^###\s+\S') { break }
    $body.Add($lines[$i])
}
$notes = ($body -join "`n").Trim()
if ($notes -eq "") {
    throw ("The '## $Version' section in CHANGELOG.md has no lede - it starts straight at a " +
           "'###' subheading. The release page would have no summary. Write an opening " +
           "paragraph that says what changed for the user.")
}

# GitHub heading anchors: lowercased, non-alphanumerics dropped. "2.2.0" -> "220".
$anchor = ($Version.ToLower() -replace '[^a-z0-9 -]', '') -replace ' ', '-'

$zip = Join-Path $root "dist\Window-Center-Resize-portable.zip"
$exe = Join-Path $root "dist\portable\WindowCenterResizer.exe"
$ahk = Join-Path $root "dist\portable\WindowCenterResizer.ahk"
foreach ($f in @($zip, $exe, $ahk)) {
    if (-not (Test-Path $f)) { throw "Not built: $f. Run build-portable.ps1 first." }
}
$hZip = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
$hExe = (Get-FileHash $exe -Algorithm SHA256).Hash.ToLower()
$hAhk = (Get-FileHash $ahk -Algorithm SHA256).Hash.ToLower()

@"
$notes

**[Full changelog for $Version](https://github.com/Devail1/window-center-resize/blob/main/CHANGELOG.md#$anchor)**

## Installing

1. Download ``Window-Center-Resize-portable.zip``.
2. Extract it to a folder you intend to keep - not your Downloads folder.
3. Run ``WindowCenterResizer.exe``.

There is no installer. ⛔ Keep the extracted files together: they are two halves of one program,
and on its own the ``.exe`` will only tell you "Script file not found."

## Verifying this download

``````
Window-Center-Resize-portable.zip  $hZip
WindowCenterResizer.exe            $hExe
WindowCenterResizer.ahk            $hAhk
``````

The ``.exe`` hash is the useful one: it is the AutoHotkey v2 interpreter exactly as the
AutoHotkey project publishes it, so you can verify it against them rather than taking this
project's word for anything. The zip's own hash is not reproducible, because zip archives store
timestamps.
"@
