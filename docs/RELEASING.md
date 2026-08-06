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

Scan **that exact file** on VirusTotal and publish that hash.

The build **is** deterministic: two consecutive builds from unchanged source produce an
identical SHA-256, verified 2026-08-04. (An earlier version of this file claimed the
opposite. The differing hashes it was based on came from source changes between builds, not
from the compiler.)

Determinism is not why this step is strict. ⛔ **The detection count moves with the binary,
and it is a roll rather than a floor** — measured across four scans of the same toolchain:
the hello-world stub 3/70, the build with the old icon 1/70, the shipping 2.0.0 build 4/70,
the shipping 2.1.0 build 3/71. So publishing one build's score alongside a different build's
bytes is a false claim, even when both builds came from the same commit.

Therefore: build once → scan **that** file → upload **that** file → publish **that** hash.
Rebuilding at any point after scanning invalidates the published hash and it will not match
what people download.

⛔ Do **not** iterate the binary against these heuristics. Seventy-odd non-deterministic
engines, one scan per attempt, and no mechanism to reason about — a lower number on the next
build is noise, not progress. The root cause is *unsigned + zero reputation*; code signing is
the only real fix, and it is required before any paid product.

From WSL, using `vt-cli` (installed at `~/bin/vt`, API key in `~/.vt.toml`):

```
vt scan file dist/WindowCenterResizer.exe    # prints an analysis id
vt analysis <id>                             # poll until status: "completed"
```

Record the result in `build/av-baseline.md`, including a gate verdict — the pre-registered
threshold is 0–2 detections with local Defender clean. Both shipped releases have exceeded
it and been published anyway on an explicit decision. Log that as a failure the decision
overrode, never as a passing score.

## 5. Tag format — three numeric segments only

⛔ **Never publish a prerelease tag or a four-segment version tag to this repo.**

`CompareVersions` in `src/lib/UpdateCheck.ahk` parses at most three segments and coerces a
non-numeric segment to `0`. Consequently:

- `2.0.0-beta` compares **equal** to `2.0.0`
- `2.0.0.1` compares **equal** to `2.0.0`

In both cases every installed copy of the app would report "You're up to date" against a
release that is genuinely newer, and the update check would silently stop working.

Use plain `v2.0.0`, `v2.0.1`, `v2.1.0`.
