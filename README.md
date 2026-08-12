<div align="left">
  <img align="left" src="assets/icon.png" alt="Logo" width="70" height="70">
  <h3 style="margin-left:100px;">Window Center & Resizer</h3>

  <div>
    <img src="https://img.shields.io/badge/license-GPLv2-green.svg" alt="License">
    <img src="https://img.shields.io/github/release/Devail1/window-center-resize.svg?color=purple" alt="GitHub release">
    <img src="https://img.shields.io/github/downloads/Devail1/window-center-resize/total?color=blue&label=downloads" alt="Downloads">
  <h3>The Open-Source Utility for Centering and Resizing Windows</h3>
  <p><a href="https://devail1.github.io/window-center-resize/"><strong>devail1.github.io/window-center-resize</strong></a></p>
</div>

<hr/>

<img src="assets/settings-window.png" alt="The settings window" width="334">

## Features

Window Center & Resizer is a utility application for Windows that allows you to easily center and resize windows on your desktop using customizable keyboard shortcuts. It is a **single portable executable of about 1.2 MB** — nothing to install, and no runtime to bring along.

- **Center Window**: Quickly center the active window on your screen.
- **Resize Window**: Cycle the active window through three size presets, given as a percentage of the screen's work area. The defaults are 50%, 75% and 90%, and all three are editable.
- **Customizable Keybinds**: Configure your preferred key combinations for centering and resizing.

## Installation

[Download](https://github.com/devail1/window-center-resize/releases/latest/download/Window-Center-Resize.exe) the latest release and run it. There is no installer — it is one executable.

### If Windows flags the download

Windows Defender may quarantine the executable, currently as `Trojan:Win32/Phonzy.A!ml`. It is a false positive, and it is a known, long-standing problem for **every** compiled AutoHotkey program rather than something specific to this one.

A compiled AutoHotkey program is the AutoHotkey interpreter with the script appended to it, so all of them share a single PE layout — the same shape a generic script dropper has. Defender's machine-learning classifiers score that shape, not the code. A hello-world AutoHotkey build that does nothing but print one line is flagged the same way; that measurement, and every antivirus scan this project has run, is recorded in [`build/av-baseline.md`](build/av-baseline.md).

The detection is reputation-based rather than a match on anything in the file. On VirusTotal, [the v2.1.0 binary](https://www.virustotal.com/gui/file/9fed2a6acbd9fa3d8647124b6fabe4cb82fa43a6a6a76b9c33e662b29e570553) is flagged by 3 of 71 engines, and all three verdicts are generic rather than identifications: Microsoft's `!ml` suffix marks a machine-learning classification, Malwarebytes reports `Malware.Heuristic.2099`, and Sophos reports `Generic Reputation PUA`. VirusTotal's own summary label for the file is `trojan.phonzy/reputation`.

The binary is unsigned, because a code-signing certificate is a recurring cost this project does not carry. It is free, and it stays free. Signing would not be the whole story anyway: AutoHotkey itself is unsigned — `Get-AuthenticodeSignature` reports `NotSigned` for the interpreter and for the compiler that builds this app — and it attracts no warnings, because it is installed widely enough to have a reputation. Prevalence, not signatures, is most of what separates a flagged binary from an unflagged one, and a utility this size will never have much of it.

Two ways forward — and since "just switch your antivirus off" is exactly what real malware would tell you, the second one is here for anyone who would rather not take the first on trust:

1. **Restore it.** Windows Security → Protection history → the entry → Actions → **Restore**, then add the executable as an exclusion.
2. **Skip the executable and run the source instead.** Install [AutoHotkey v2](https://www.autohotkey.com/), download **Source code (zip)** from the [releases page](https://github.com/Devail1/window-center-resize/releases/latest), and run `src\main.ahk`. Same application, no compiled binary anywhere in the picture — you run the mainstream AutoHotkey interpreter over plain script files you can read first.

Every line of this program is in this repository and the build is a single PowerShell script, `build\build.ps1`, so compiling it yourself and comparing hashes is also on the table.

## Usage

1. **Center Window** — press the centering shortcut (default `Ctrl+Shift+C`) to center the active window without changing its size.
2. **Resize Window** — press the resize shortcut (default `F9`) to cycle through the size presets.
3. **Customization** — open **Settings** from the tray icon, or edit `settings.ini` next to the executable.

To change a shortcut, click its field in Settings and press the keys you want — the combination is captured as you press it. **Windows-key combinations are the one exception:** the field cannot capture them, so set those by editing `settings.ini` directly, using AutoHotkey syntax (`#` is Win, `^` Ctrl, `+` Shift, `!` Alt — for example `Center=#Up`). A Win-key shortcut set that way is kept, not overwritten, if you later open and save Settings.

### Starting with Windows

The shortcuts only work while the app is running, so most people want it to start with Windows. Put a **shortcut to** the executable in your Startup folder:

1. Press <kbd>Win</kbd> + <kbd>R</kbd>, type `shell:startup`, and press Enter. That opens your own Startup folder. Use `shell:common startup` instead for every user on the machine — that folder needs administrator rights to write to.
2. Drag `WindowCenterResizer.exe` into that folder **with the right mouse button**, release, and choose **Create shortcuts here** from the menu that appears.

⛔ **Put a shortcut in that folder, not the executable itself.** The app reads `settings.ini` from whichever folder it sits in, so moving the `.exe` into Startup leaves your `settings.ini` behind and the app starts with default hotkeys and presets — silently, with no error, because a missing settings file is not treated as a problem. Leave the executable where it is.

The shortcut does not need a **Start in** folder set: the app locates `settings.ini` relative to the executable, not to the working directory, so it finds its settings wherever it is launched from.

### Windows running as administrator

A program that runs as administrator — Task Manager, an elevated terminal — cannot be moved by a program that does not. If you press a shortcut on one of those, the app will say so and offer **Restart as administrator** from the tray menu.

Anything launched from the Startup folder runs without administrator rights, so a copy started that way is subject to the same limit on every boot. If you want it elevated from the start instead, create a Task Scheduler task that runs it at logon with **Run with highest privileges** — the Startup folder cannot do that.

### Portability

The app is portable and keeps `settings.ini` **next to the executable**. Two consequences worth knowing:

- Moving the executable to a different folder starts it with default settings, because the old `settings.ini` stays behind.
- Two copies in two folders run independently, each with its own settings.

## Building from source

Requires [AutoHotkey v2](https://www.autohotkey.com/) installed **with the compiler** (Ahk2Exe). There is no other build chain and no runtime dependencies.

```
powershell -ExecutionPolicy Bypass -File build\build.ps1
```

The compiled executable is written to `dist\WindowCenterResizer.exe`.

## Inspiration

This project is inspired by the window centering helper freeware by [Kamil Szymborski](https://kamilszymborski.github.io/). Window Center & Resizer offers a modern approach to window management with additional features and extensive customization capabilities.

## Contributing

Contributions are welcome! If you have any suggestions, bug reports, or feature requests, please open an issue on the GitHub repository or submit a pull request.

## License

Copyright © 2024–2026 Liav Edry. Licensed under the **GNU General Public License, version 2** — see the [LICENSE](LICENSE) file for the full text.

A compiled AutoHotkey program is the interpreter plus the script in one executable, so every release of this app contains [AutoHotkey](https://www.autohotkey.com/), which is itself GPLv2. Matching that licence keeps the distributed binary coherent.

**Releases up to and including 2.1.0 were published under the MIT licence and remain available under it.** The change applies from 2.2.0 onward; it does not and cannot affect copies already distributed.

## Acknowledgements

Built with [AutoHotkey v2](https://www.autohotkey.com/) by Steve Gray, Chris Mallett and contributors, licensed under the GNU GPL version 2. The compiled executable includes the AutoHotkey interpreter; its source is available from the [AutoHotkey repository](https://github.com/AutoHotkey/AutoHotkey). AutoHotkey bundles [PCRE](https://www.pcre.org/) by the University of Cambridge, used under the BSD licence.

The icon is [`square-dot`](https://lucide.dev/icons/square-dot) from [Lucide](https://lucide.dev), used under the [ISC License](https://github.com/lucide-icons/lucide/blob/main/LICENSE).

Versions 1.x were built on [electron-react-boilerplate](https://github.com/electron-react-boilerplate/electron-react-boilerplate). Version 2.0.0 is a ground-up rewrite in AutoHotkey v2 and no longer contains any of that code.
