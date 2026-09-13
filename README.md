<div align="left">
  <img align="left" src="assets/icon.png" alt="Logo" width="70" height="70">
  <h3 style="margin-left:100px;">Window Center & Resizer</h3>

  <div>
    <img src="https://img.shields.io/badge/license-GPLv2-green.svg" alt="License">
    <img src="https://img.shields.io/github/release/Devail1/window-center-resize.svg?color=purple" alt="GitHub release">
    <img src="https://img.shields.io/github/downloads/Devail1/window-center-resize/total?color=blue&label=downloads" alt="Downloads">
    <a href="https://github.com/Devail1/window-center-resize/actions/workflows/test.yml"><img src="https://github.com/Devail1/window-center-resize/actions/workflows/test.yml/badge.svg" alt="Tests"></a>
  <h3>The Open-Source Utility for Centering and Resizing Windows</h3>
  <p><a href="https://devail1.github.io/window-center-resize/"><strong>devail1.github.io/window-center-resize</strong></a></p>
</div>

<hr/>

<img src="assets/settings-window.png" alt="The settings window" width="348">

## Features

Window Center & Resizer is a utility application for Windows that allows you to easily center and resize windows on your desktop using customizable keyboard shortcuts. It is a **630 KB download** — nothing to install, and no runtime to bring along.

- **Named positions**: Put the active window where you want it, with one keystroke. A position is a name, a hotkey, and a place on the screen — and you set that place by dragging a window inside a picture of your own screen, rather than by typing coordinates. Centring is one of these, and it is the one that ships.
- **Keep the size, or set it**: A position can move a window without touching its size, or give it a size as a percentage of the screen. "Put this on the left but leave it as big as it is" is a position, not a compromise.
- **Resize cycle**: A separate key cycles the active window through three size presets, given as a percentage of the screen's work area. The defaults are 50%, 75% and 90%, all editable. It re-centres the window as it goes, exactly as it always has.
- **Customizable keybinds**: Every position carries its own hotkey, and the resize key is yours to choose.

## Installation

1. Download **[Window-Center-Resize-portable.zip](https://github.com/devail1/window-center-resize/releases/latest/download/Window-Center-Resize-portable.zip)** from the latest release.
2. Extract it to a folder you intend to keep — your Documents, a tools folder, a USB stick. Not your Downloads folder, and not a temporary one.
3. Run `WindowCenterResizer.exe`.

There is no installer. The app runs from wherever you put it and writes nothing outside its own folder.

⛔ **Keep the extracted files together in one folder.** The `.exe` and the `.ahk` beside it are two halves of the same program — see below. Move the folder, not its contents.

### Why the download is a zip with two files in it

Because the single `.exe` this project used to ship got quarantined by Windows Defender, and a zip of two files does not.

Up to and including 2.1.0, releases were built with AutoHotkey's compiler, `Ahk2Exe`. That tool does not produce a normal program: it takes a copy of the AutoHotkey interpreter and welds your script into it as a resource. Appending a script to the AutoHotkey interpreter is also a genuinely common way to ship malware, so Defender's machine-learning classifiers score that *shape* — not the code inside it, which they never read.

Measured on 2026-09-12, both files unsigned, against the same Microsoft engine build:

| | Stock `AutoHotkey64.exe` | The compiled 2.1.0 release |
|---|---|---|
| Microsoft | **undetected** | `Trojan:Win32/Wacatac.B!ml` |
| All engines | **0 of 70** | 3 of 71 |
| Size | 1,272,832 bytes | 1,290,240 bytes |

The two differ by 17,920 bytes — 1.4% of the file. Everything else is byte-for-byte the same binary Microsoft considers clean. The 1.4% is what `Ahk2Exe` adds, and it is the whole difference between a download that works and one Chrome deletes before it finishes.

So this release stops adding it. The zip contains:

| File | What it is |
|---|---|
| `WindowCenterResizer.exe` | The stock AutoHotkey v2 interpreter, **byte-identical** to the one published by AutoHotkey. Renamed, and nothing else — renaming does not change a file's contents, and reputation follows contents. |
| `WindowCenterResizer.ahk` | This program, in plain text. The interpreter runs the script that shares its name. |
| `icon.ico` | The tray icon. |

Check it rather than believing it. Both links are live, so they show what the engines say
**today** rather than what they said when this was written:

- [`WindowCenterResizer.exe`](https://www.virustotal.com/gui/file/a2a54b8abc476d7671d4de0771bb54bf5f2373d79ff6871d0ba6a62c3b88ae00) — the interpreter. This is the useful one: it is AutoHotkey's own binary, so you can verify it against [the AutoHotkey project](https://www.autohotkey.com/) instead of taking anything here on trust.
- [`Window-Center-Resize-portable.zip` 2.2.0](https://www.virustotal.com/gui/file/4a95d0284cc4792c463c387b0f299ee9c199dd9d12646cbbe010138a7e68d09c) — the download itself, 0 of 75 when published.

⚠️ A scan result is a snapshot of the scanners, not a property of the file. This project has
watched an unchanged binary be re-scored twice, once into a class Defender quarantines — which
is why there is a link here and not a badge claiming a number.

Three consequences worth knowing before you download it:

- **The `.exe` shows AutoHotkey's green H icon, not this project's.** An icon lives inside the executable, so giving it ours would modify the file, change its identity, and bring the detection straight back. The tray icon is correct — that one is set at runtime. A cosmetic cost, paid deliberately.
- **`WindowCenterResizer.exe` on its own does nothing.** Separated from its `.ahk` it reports *"Script file not found."* That is the interpreter telling you it has no program to run.
- **You can read the entire program before running it**, which was never true of the compiled builds. It is the same code as [`src/`](src/), flattened into one file by [`build/build-portable.ps1`](build/build-portable.ps1).

⛔ **Old download links are dead, deliberately.** Anything pointing at `releases/latest/download/Window-Center-Resize.exe` — older README copies, software directories, mirrors — will 404 from 2.2.0 onward. That URL served the compiled build, and continuing to serve it would mean knowingly handing people a file their antivirus deletes. A broken link is the better failure.

If you have a copy of 2.1.0 or earlier that Windows quarantined, delete it and download this release instead; there is nothing to restore or exclude.

## Usage

1. **Center Window** — press the centering shortcut (default `Ctrl+Shift+C`) to center the active window without changing its size.
2. **Resize Window** — press the resize shortcut (default `F9`) to cycle through the size presets.
3. **Customization** — open **Settings** from the tray icon, or edit `settings.ini` next to the executable.

To change a shortcut, click its field in Settings and press the keys you want — the combination is captured as you press it. **Windows-key combinations are the one exception:** the field cannot capture them, so set those by editing `settings.ini` directly, using AutoHotkey syntax (`#` is Win, `^` Ctrl, `+` Shift, `!` Alt — for example `Center=#Up`). A Win-key shortcut set that way is kept, not overwritten, if you later open and save Settings.

### Starting with Windows

The shortcuts only work while the app is running, so most people want it to start with Windows. Put a **shortcut to** the executable in your Startup folder:

1. Press <kbd>Win</kbd> + <kbd>R</kbd>, type `shell:startup`, and press Enter. That opens your own Startup folder. Use `shell:common startup` instead for every user on the machine — that folder needs administrator rights to write to.
2. Drag `WindowCenterResizer.exe` into that folder **with the right mouse button**, release, and choose **Create shortcuts here** from the menu that appears.

⛔ **Put a shortcut in that folder, not the executable itself.** Moving the `.exe` out of its folder separates it from `WindowCenterResizer.ahk`, and it will start with *"Script file not found."* instead of running — and even if you moved the whole folder's contents, it would leave your `settings.ini` behind and start with default hotkeys and presets, silently, because a missing settings file is not treated as a problem. Leave the folder where it is and point a shortcut at it.

The shortcut does not need a **Start in** folder set: the app locates `settings.ini` relative to the executable, not to the working directory, so it finds its settings wherever it is launched from.

### Windows running as administrator

A program that runs as administrator — Task Manager, an elevated terminal — cannot be moved by a program that does not. If you press a shortcut on one of those, the app will say so and offer **Restart as administrator** from the tray menu.

Anything launched from the Startup folder runs without administrator rights, so a copy started that way is subject to the same limit on every boot. If you want it elevated from the start instead, create a Task Scheduler task that runs it at logon with **Run with highest privileges** — the Startup folder cannot do that.

### Portability

The app is portable and keeps `settings.ini` **next to the executable**. Three consequences worth knowing:

- The app is its folder, not its `.exe`. Copy the whole folder to move it — to another machine, or onto a USB stick — and it carries its settings with it.
- Moving the executable alone gives you *"Script file not found."*; moving the executable and the script but not `settings.ini` starts it with defaults.
- Two copies in two folders run independently, each with its own settings.

## Building from source

Requires [AutoHotkey v2](https://www.autohotkey.com/). There is no other build chain and no runtime dependencies.

```
powershell -ExecutionPolicy Bypass -File build\build-portable.ps1
```

This writes the distributable folder to `dist\portable\` and zips it to `dist\Window-Center-Resize-portable.zip`. The build flattens the `#Include` tree in [`src/`](src/) into one script and copies the AutoHotkey interpreter beside it.

It **refuses to build** unless the interpreter it is about to ship is the exact AutoHotkey release recorded in [`build/interpreter.pin`](build/interpreter.pin) — by version *and* by SHA-256. That is the property the whole packaging rests on, so it is checked rather than assumed, and CI re-derives the same hash from AutoHotkey's official release download on every push. If you have a different AutoHotkey installed, the build tells you so instead of quietly shipping it.

You can also just run the app straight from the sources with `AutoHotkey64.exe src\main.ahk`, with no build step at all.

## Inspiration

This project is inspired by the window centering helper freeware by [Kamil Szymborski](https://kamilszymborski.github.io/). Window Center & Resizer offers a modern approach to window management with additional features and extensive customization capabilities.

## Contributing

Contributions are welcome! If you have any suggestions, bug reports, or feature requests, please open an issue on the GitHub repository or submit a pull request.

## License

Copyright © 2024–2026 Liav Edry. Licensed under the **GNU General Public License, version 2** — see the [LICENSE](LICENSE) file for the full text.

Every release of this app ships [AutoHotkey](https://www.autohotkey.com/), which is itself GPLv2 — up to 2.1.0 welded into the executable by the compiler, and from 2.2.0 as the interpreter binary sitting beside the script. Either way it is redistribution, so matching the licence keeps the download coherent.

**Releases up to and including 2.1.0 were published under the MIT licence and remain available under it.** The change applies from 2.2.0 onward; it does not and cannot affect copies already distributed.

## Acknowledgements

Built with [AutoHotkey v2](https://www.autohotkey.com/) by Steve Gray, Chris Mallett and contributors, licensed under the GNU GPL version 2. `WindowCenterResizer.exe` in the download **is** the AutoHotkey interpreter, unmodified; its source is available from the [AutoHotkey repository](https://github.com/AutoHotkey/AutoHotkey). AutoHotkey bundles [PCRE](https://www.pcre.org/) by the University of Cambridge, used under the BSD licence.

The icon is [`square-dot`](https://lucide.dev/icons/square-dot) from [Lucide](https://lucide.dev), used under the [ISC License](https://github.com/lucide-icons/lucide/blob/main/LICENSE).

Versions 1.x were built on [electron-react-boilerplate](https://github.com/electron-react-boilerplate/electron-react-boilerplate). Version 2.0.0 is a ground-up rewrite in AutoHotkey v2 and no longer contains any of that code.
