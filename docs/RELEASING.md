# Releasing

The procedure for cutting a release of Window Center & Resizer. Every step below exists
because skipping it breaks something for existing users.

## 1. Stop any running instance

`build.ps1` fails fast if `WindowCenterResizer.exe` is running. That check is deliberate:
Ahk2Exe cannot overwrite a locked target and does **not** error — it blocks indefinitely,
which reads as a broken toolchain rather than "your app is open."

Exit the app from its tray icon before building.

## 2. Build once

```
powershell -ExecutionPolicy Bypass -File build\build.ps1
```

This produces `dist\WindowCenterResizer.exe` and enforces the size gate.

**Build once.** See step 4 — do not rebuild after scanning.

## 3. Attach the binary under BOTH names

Upload the *same* file twice, under two asset names:

| Asset name | Why |
| --- | --- |
| `Window-Center-Resize.exe` | The README, and every directory listing and mirror that copied it, links to `releases/latest/download/Window-Center-Resize.exe`. That URL resolves against whatever release is currently latest, so publishing a release **without** this asset name 404s every existing link, including on the software directories. |
| `WindowCenterResizer.exe` | The name the build produces and the name users see in their tray and task manager. |

Never drop `Window-Center-Resize.exe`, however awkward the name is. It is load-bearing for
an existing userbase.

## 4. Scan that exact file on VirusTotal, publish that hash

⚠️ **The binary is not byte-reproducible.** Ahk2Exe embeds a build timestamp, so two builds
of identical source have the same byte length and a different SHA-256.

Therefore: build once → scan **that** file → upload **that** file → publish **that** hash.
Rebuilding at any point after scanning invalidates the published hash and it will not match
what people download.

This matters more than usual here: the binary is unsigned and has zero reputation, so at
least one engine flags it generically. Record the result in `build/av-baseline.md`.

## 5. Tag format — three numeric segments only

⛔ **Never publish a prerelease tag or a four-segment version tag to this repo.**

`CompareVersions` in `src/lib/UpdateCheck.ahk` parses at most three segments and coerces a
non-numeric segment to `0`. Consequently:

- `2.0.0-beta` compares **equal** to `2.0.0`
- `2.0.0.1` compares **equal** to `2.0.0`

In both cases every installed copy of the app would report "You're up to date" against a
release that is genuinely newer, and the update check would silently stop working.

Use plain `v2.0.0`, `v2.0.1`, `v2.1.0`.
