# Changelog

## Unreleased

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
