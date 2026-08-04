<div align="left">
  <img align="left" src="https://raw.githubusercontent.com/Devail1/window-center-resize/main/assets/icon.png" alt="Logo" width="70" height="70">
  <h3 style="margin-left:100px;">Window Center & Resizer</h3>

  <div>
    <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
    <img src="https://img.shields.io/github/release/Devail1/window-center-resize.svg?color=purple" alt="GitHub release">
    <a href="https://snyk.io/test/github/Devail1/window-center-resize">
      <img src="https://snyk.io/test/github/Devail1/window-center-resize/badge.svg" alt="Known Vulnerabilities">
    </a>
  <h3>The Open-Source Utility for Centering and Resizing Windows</h3>
</div>

<hr/>

  <img align="top" src="https://res.cloudinary.com/di41jhirl/image/upload/v1722415826/mb3jp3gaherwkgme6vi4.png" alt="Center Window" style="width: 49%;"/>
  <img src="https://res.cloudinary.com/di41jhirl/image/upload/v1722415826/fpcyvkh9llcwvrexelbz.png" alt="Resize Window" style="width: 49%;"/>

## Features
Window Center & Resizer is a utility application for Windows that allows you to easily center and resize windows on your desktop using customizable keyboard shortcuts. It is a single portable executable — around 1.6 MB, with nothing to install and no runtime to bring along.

- **Center Window**: Quickly center the active window on your screen.
- **Resize Window**: Resize the active window to predefined sizes (small, medium, large) with customizable keyboard shortcuts.
- **Customizable Keybinds**: Easily configure your preferred key combinations for centering and resizing windows.

## Installation

To use Window Center & Resizer, [download](https://github.com/devail1/window-center-resize/releases/latest/download/Window-Center-Resize.exe) the latest release from the [GitHub repository](https://github.com/devail1/window-center-resize) and run the executable file.

## Usage

1. **Center Window**: Press the specified key combination to center the active window.
2. **Resize Window**: Press the specified key combination to resize the active window to small, medium, or large sizes.
3. **Customization**: Open **Settings** from the tray icon, or edit the `settings.ini` file that sits next to the executable.

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

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.
