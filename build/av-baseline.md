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

### VirusTotal result — 2026-08-03

**3 of ~70 engines. All generic ML / behavioural. No specific-family detection.**

| Engine | Verdict |
|---|---|
| Microsoft | `Trojan:Win32/Wacatac.B!ml` |
| Skyhigh (SWG) | `BehavesLike.Win64.Dropper.th` |
| Zillya | `Trojan.GenKryptik.Win64.70405` |

**Undetected by every major vendor:** Kaspersky, BitDefender, ESET, Sophos, Symantec,
Avast, AVG, McAfee, TrendMicro, Malwarebytes, CrowdStrike, SentinelOne, Palo Alto, GData,
Fortinet, DrWeb, Emsisoft, Google, Elastic, DeepInstinct.

**Diagnosis.** `!ml` denotes a machine-learning heuristic; `Wacatac.B!ml` is Microsoft's
best-known generic signature and a frequent false positive on unsigned binaries that embed
an interpreter. Verified: the **official `AutoHotkey64.exe` is itself unsigned**, so the
compile does not break a signature — the trigger is *unsigned + zero reputation*, not
AutoHotkey specifically. ⭐ **Switching implementation language would NOT fix this** — a
fresh unsigned binary of any language trips the same heuristics. Code signing is the fix.

**Counter-evidence that matters most:** local Windows Defender real-time protection did
**not** block or quarantine this binary. It compiled, executed (`hello-from-ahk`, exit 0),
and stayed on disk. VirusTotal's Microsoft engine is more aggressive than real-time
protection.

**GATE VERDICT: conditional FAIL against the pre-registered threshold** (0–2 detections,
Defender clean). Not silently redefined after the fact.

**DECISION — Liav, 2026-08-03: proceed and ship free 2.0.0 unsigned.** Rationale: the free
flagship exists to test whether *directory submission* works, not to earn money; the
directories list many AHK tools; local Defender does not act. Accepted risk: some users may
see a Defender warning, and the current Electron build has no AV issue at all — so this is a
genuine regression on that one axis, traded for a 50x size reduction.

**Consequent actions:**
1. Submit a false-positive report to Microsoft — https://www.microsoft.com/en-us/wdsi/filesubmission
   (submit as a software developer, "incorrectly detected"). Free; often clears within days.
2. **Re-scan the REAL binary at Task 8.** This stub is not the product; the score may differ.
3. ⛔ **Code signing is now REQUIRED before any PAID product**, promoted from "confirm
   eligibility". Azure Trusted Signing ($9.99/mo) is US/Canada-gated and likely unavailable
   in Israel → a CA certificate at roughly $200–600/year. Verify Israeli eligibility before
   committing to utility #2.

### VirusTotal — THE REAL BINARY, 2026-08-04

`dist/WindowCenterResizer.exe`, 1.57 MB
SHA-256 `378895686239aeac2d3fab93a9cf56bbeda38b6f7025f9abd0b9d2af4dbec469`

**1 of 70. Microsoft: UNDETECTED.**

| Engine | Verdict |
|---|---|
| Skyhigh (SWG) | `BehavesLike.Win64.Dropper.th` |
| **Microsoft** | **Undetected** |
| Everything else (Kaspersky, BitDefender, ESET, Sophos, Symantec, CrowdStrike, SentinelOne, …) | Undetected |

⭐ **The real product scores BETTER than the hello-world stub** (3/70 including
`Trojan:Win32/Wacatac.B!ml`). Microsoft went from a detection to clean once the binary
contained the real icon and 348 lines of actual code — the empty stub read as more
suspicious to Defender's ML than the finished app does.

✅ **GATE PASSES.** The pre-registered threshold was 0–2 detections with Defender clean.
The stub failed it (3, Microsoft flagging); the shipping artifact passes it (1, Microsoft
clean). Not a waiver and not a redefinition — the artifact changed. ⭐ **Lesson: scan the
thing you ship, not a proxy for it.**

Standing: the single remaining hit is one behavioural/ML engine on an unsigned binary.
Code signing remains **required before any paid product** (see above), but is not blocking
this free release.

### VirusTotal — the 2.0.0 release binary, 2026-08-04

`dist/WindowCenterResizer.exe`, 1,289,216 bytes
SHA-256 `b2adcd403b945fbbb14d7c997cdd820608a14ea712974965e7a6d6865290dd65`

**4 of 70.** All generic ML/heuristic; no named malware family.

| Engine | Verdict |
|---|---|
| Microsoft | `Trojan:Win32/Wacatac.C!ml` |
| Malwarebytes | `Malware.Heuristic.2099` |
| Skyhigh (SWG) | `BehavesLike.Win64.Dropper.th` |
| Zillya | `Trojan.GenKryptik.Win64.70405` |

**The number moves with the binary** — three scans, three results:
stub **3/70** → build with the old Electron icon **1/70** → this build **4/70**.
⭐ That is why the rule is *scan the artifact you upload*, not a proxy for it. Publishing the
1/70 build's reputation alongside a 4/70 file would have been a false claim.

**Hypothesis tested and FALSIFIED.** I suspected the PNG-compressed icon frames raised the
resource section's entropy. Measured: PNG frames 7.829 bits/byte, BMP frames 7.863 — the BMP
variant is marginally *higher*. The candidate was discarded unscanned rather than spending a
scan on a disproven idea. ⛔ **Do not iterate the binary against these heuristics** — 70
non-deterministic engines, one scan per attempt, no mechanism to reason about. That is
cargo-culting, not debugging.

**Counter-evidence, and it is the load-bearing one:** local Windows Defender has
`RealTimeProtectionEnabled = True` and **no detection recorded for this file**, on a machine
where the binary has been built and run repeatedly. VirusTotal's Microsoft engine is far more
aggressive than the Defender a user actually runs.

**GATE VERDICT: FAILS the pre-registered threshold** (0–2 detections, Defender clean). Recorded
as a failure, not redefined.

**DECISION — Liav, 2026-08-04: publish anyway.** Reasoning, stated so it can be judged later:
the gate was a *proxy* for "will users be blocked", and direct measurement of that says no; all
four hits are generic ML with no family attribution; every other major vendor is clean; the
source is public and independently buildable; and the product is free, so no one is paying for
a warning. ⛔ **The root cause is unsigned + zero reputation. Code signing remains REQUIRED
before any paid product** — that is not deferred by this decision, only unblocked for a free one.

**Action taken:** false-positive reports to be submitted to Microsoft and Malwarebytes.
