# Antivirus baseline — compiled AutoHotkey v2 binaries

Purpose: compiled AHK binaries are heuristically flagged by some engines. This file records a
known-good baseline so a future detection can be compared against it rather than panicked over.

## 2026-08-03 — hello-world baseline

| | |
|---|---|
| AutoHotkey version | 2.0.26 (installed via `winget`, per-user at `%LOCALAPPDATA%\Programs\AutoHotkey`) |
| Compiler | `Ahk2Exe.exe`, `/compress 0` (**no UPX** — UPX materially worsens false positives) |
| Base | `AutoHotkey64.exe` (1.21 MB) |
| Output | `build/hello.exe`, 1,272,832 bytes (1.21 MB) for an empty script |
| SHA-256 | `50ca8671f8613840c4621530655c87b3428ada32dae2f088d4daf6a213d9d6d8` |

### Results

- **Windows Defender (local, real-time): PASS.** The binary compiled, executed
  (`hello-from-ahk`, exit 0), and was **not quarantined** before or after execution.
- **VirusTotal: PENDING** — awaiting manual upload. Gate: 0–2 detections is normal background
  noise for compiled AHK and passes; a Defender block or widespread detections **stops the plan**
  and forces a stack rethink (code-signing certificate, or a different language).

### Note on size

1.21 MB is the **floor**, not the app — a compiled AHK binary is the interpreter plus the script.
This measurement is why the project's size gate moved from 1 MB to 2 MB.
