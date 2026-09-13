# Changelog

## 2.3.0

**Centring is now one of several named positions, and you set where they go by dragging.**

A position is a name, a hotkey, and a place on the screen. You set that place by dragging a
window around a picture of your own screen in the settings window — no coordinates, no
percentages to work out. A position can move a window without touching its size, or give it a
size as a percentage of the screen.

**Nothing about upgrading changes a key you already press.** A settings file written by 2.2.0 or
earlier has no positions in it, and the first run turns its Center hotkey into a position called
Center — carrying *your* binding, not the shipped default. One position ships, so no new
system-wide hotkey is claimed on your machine without you asking for it.

The resize cycle is untouched: the same key, the same three presets, and it still re-centres the
window as it resizes. `settings.ini` gains a `[Positions]` section and keeps everything else,
including `[Hotkeys] Center`, so downgrading to 2.2.0 still finds the key it expects.

### Added

- **Named positions.** Up to eight, each with its own name and hotkey. The settings window shows
  them as a list you edit in place.
- **A picture of your screen**, with the taskbar drawn where your taskbar actually is, and a
  window you drag and resize inside it. The numbers it produces are shown beneath it.
- **"Keep the window's current size"**, which is what lets a position move a window without
  resizing it — and what makes "align it left but leave it the size it is" a position rather
  than a compromise.

### Changed

- The Center hotkey field is gone from the settings window, because Center is now the first
  position and is edited there like any other.
- The settings window refuses to save two actions that share a hotkey, and says which two. It
  used to be possible to bind one key twice, in which case only one of them ever ran.
- Clicking empty space in the settings window lets go of whatever field has focus.

### Fixed

- Hotkeys that differ only in the ORDER of their modifiers, or in case, are now recognised as
  the same key. `^+c` and `+^c` are one binding, and binding both silently destroyed the first.

## 2.2.0

**Old download links no longer work, and that is deliberate.**
`releases/latest/download/Window-Center-Resize.exe` is gone; the download is now
`Window-Center-Resize-portable.zip`. That URL served a compiled executable which Windows
Defender had begun quarantining on sight, so serving it would have meant handing people a file
their antivirus deletes. If a copy of 2.1.0 or earlier was quarantined, download this release
instead — there is nothing to restore or exclude.

The app itself is unchanged: same hotkeys, same presets, same settings file. What changed is the
shape of the download — the AutoHotkey interpreter, unmodified, with the program beside it as a
plain script you can read before running it.

### Distribution

- **The compiled executable is gone, because Windows Defender had started deleting it.** On
  2026-09-12 Microsoft's cloud classifier scored the unchanged 2.1.0 binary as
  `Trojan:Win32/Wacatac.B!ml`, which Defender treats as Severe and quarantines on sight.
  Chrome deletes such a file mid-download, so the release was effectively unobtainable —
  including by its own author, which is how this was noticed.
- **The fix is structural, not cosmetic.** AutoHotkey's compiler welds a script into a copy of
  the interpreter, and that shape — not the code in it — is what the classifiers score, because
  it is also how a great deal of real malware is packaged. Measured against the same Microsoft
  engine build, both files unsigned: the stock interpreter is **0 of 70**, the compiled release
  **3 of 71**. They differ by 17,920 bytes. This release ships the interpreter untouched and
  keeps the script next to it, so there is no modified binary to score. The portable zip scans
  **0 of 75**, Microsoft undetected.
- **Old download links are broken on purpose.** `releases/latest/download/Window-Center-Resize.exe`
  no longer exists. It served the compiled build, and serving it knowingly would hand people a
  file their antivirus deletes. Software directories and mirrors that copied that URL will 404
  until they are updated.
- **The download is smaller:** 630 KB, down from 1.23 MB, because a script compresses far
  better than an executable does.
- **The `.exe` now shows AutoHotkey's icon rather than this project's.** An icon is stored
  inside the executable, so applying ours would modify the file and reinstate the detection.
  The tray icon is unaffected.

### Fixed

- **Restart as administrator** relaunches correctly when running as a script. It previously
  passed a bare `.ahk` path to Windows, which would have opened whichever AutoHotkey was
  *installed* — or a "how do you want to open this file" dialog on a machine with none —
  instead of the interpreter shipped in the folder.
- The tray icon is loaded from `icon.ico` beside the script, so it is correct in a release
  folder as well as in a source checkout.

### Licence

- **The project is now licensed under the GNU General Public License, version 2**, changed from
  MIT. A compiled AutoHotkey executable contains the AutoHotkey interpreter, which is GPLv2, so
  every release already shipped GPL code inside the binary; the licences now match. Practically
  this means anyone distributing a modified version must publish their source under the same
  terms. Using the app, at home or at work, is unaffected.
- **Releases up to and including 2.1.0 stay MIT** and remain available under it. A licence change
  applies going forward and cannot be applied retroactively to copies already distributed.
- The README now credits AutoHotkey and PCRE, which it previously omitted.

## 2.1.0

This is a presentation release — the interface has been refreshed. The only interaction
change is where keyboard focus starts — see below.

### Interface

- **Settings window redesigned.** Each section now has a bold heading with a short grey
  caption underneath, instead of an inline sentence, and the Hotkeys and Size-presets rows
  share one column grid with more space between labels and their fields. The window itself
  is narrower, and body text is slightly larger than in 2.0.0.
- **Reset separated from Save and Close.** Reset now sits alone at the bottom left; Close
  and Save are grouped at the bottom right, with **Save** as the default button. The
  window also opens with focus on Save instead of a hotkey field, so Enter saves right
  away.
- Hotkeys, presets, saving and validation are unchanged.

## 2.0.0

Complete rewrite. The app was an Electron application; it is now a single compiled
AutoHotkey v2 executable.

### The rewrite

- **64 MB → 1.23 MB.** One portable `.exe`, roughly 52x smaller than the Electron build.
- **No runtime.** Nothing to install, no Chromium, no Node — just the executable.
- Settings live in **`settings.ini` beside the executable** (previously `settings.json` in
  the user profile). The app is portable: move the exe and it starts with defaults; two
  copies in two folders run independently.

### Bug fixes

- **Secondary-monitor sizing.** Resizing a window on a second monitor sized it from one
  monitor and centred it on another. Sizing and centring now derive from the same rect.
- **Taskbar overflow.** Windows were sized against the full screen but centred within the
  work area, so a maximised-size preset ran under the taskbar. Everything now uses the
  work area.
- **Fractional pixels.** Percentage maths produced non-integer coordinates, which Windows
  rounded inconsistently. All geometry is rounded explicitly.
- **Unreachable first preset.** The size cycle started at preset 2, so the first preset
  could never be selected by the first keypress. The cycle now starts before preset 1.
- **[#12](https://github.com/Devail1/window-center-resize/issues/12) — elevated windows.**
  A window owned by an elevated process (Task Manager, for example) cannot be moved by a
  non-elevated app. This used to surface as a raw error. It is now explained in plain
  language, with a tray menu item to restart as administrator.

### Other changes

- **Manual update check** from the tray menu. It reads the latest published version number
  and offers to open the releases page in your browser. It never downloads anything.
- **Settings simplified** — the tabs are gone. One window: two hotkeys and three size
  presets, with **Save**, **Reset** and **Close**.
- **Shortcuts are captured, not typed.** Click a hotkey field and press the combination —
  it is shown as keys, not as `^+c`. Windows-key combinations cannot be captured by that
  field; set those in `settings.ini` and the settings window leaves them alone rather than
  overwriting them.
- **Reset** puts the default hotkeys and presets back into the window. Nothing is written
  until you press Save, so a reset can be abandoned with Close.
- The title bar read `Window Center && Resizer`. It reads `Window Center & Resizer`.

## 1.0.2

The Electron releases up to and including 1.0.2 are recorded in the git history at
<https://github.com/Devail1/window-center-resize/commits/main>.
