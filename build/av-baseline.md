# Antivirus baseline — AutoHotkey v2 distribution

Purpose: record every antivirus measurement this project has taken, so a future detection can be
compared against a baseline rather than panicked over.

⚠️ **Read the last section first.** Sections are in chronological order and the early ones are
wrong in ways the later ones correct — most importantly, everything before 2026-09-12 assumes the
product is a **compiled** binary and reasons about how to get a good antivirus roll for one. It is
no longer compiled, and that reasoning no longer applies. The history is kept because the
measurements are real and the mistakes are instructive, not because the conclusions still hold.

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

### VirusTotal — the 2.1.0 release binary, 2026-08-06

`dist/WindowCenterResizer.exe`, 1,290,240 bytes
SHA-256 `9fed2a6acbd9fa3d8647124b6fabe4cb82fa43a6a6a76b9c33e662b29e570553`
Scanned with `vt-cli` 1.3.1 (`vt scan file`), first submission of this hash — VirusTotal had
not seen it before, so this is a fresh analysis and not a cached verdict.

**3 of 71 engines that returned a verdict** (67 undetected, 3 malicious, 1 engine error —
Ikarus; 4 further engines reported the type as unsupported). All generic ML/heuristic; no
named malware family.

| Engine | Verdict |
|---|---|
| Microsoft | `Program:Win32/Wacapew.C!ml` |
| Malwarebytes | `Malware.Heuristic.2099` |
| Skyhigh (SWG) | `BehavesLike.Win64.Dropper.th` |
| Zillya | **Undetected** (flagged 2.0.0, clean here) |

**Better than the binary that actually shipped as 2.0.0** (4/70), and Microsoft's
classification moved down a severity class: `Trojan:Win32/Wacatac.C!ml` → `Program:Win32/
Wacapew.C!ml`. `Program:` is Microsoft's potentially-unwanted-application prefix, not a trojan
verdict — it is the label Defender gives unsigned installers and packers generically. ⛔ This
is **not** evidence that anything was fixed: the count moves with the binary on every scan
(stub 3/70 → old-icon build 1/70 → 2.0.0 build 4/70 → this build 3/71) and nothing in this
release touched packaging. It is one more draw from the same distribution, and a slightly
better one.

**Counter-evidence, the load-bearing one, re-measured today:** local Windows Defender has
`RealTimeProtectionEnabled = True` and **no threat detection recorded for this file**, which
has been on disk since it was compiled. Neither copy was quarantined.

**GATE VERDICT: FAILS the pre-registered threshold** (0–2 detections, Defender clean).
Recorded as a failure, not redefined — the same verdict 2.0.0 received at 4/70.

**Precedent, not a new decision:** Liav's 2026-08-04 ruling on the 2.0.0 gate failure applies
unchanged here, and this artifact is strictly better than the one that ruling cleared. ⛔ Code
signing remains **REQUIRED before any paid product**; this release is free.

⚠️ **Superseded six days later — see the next section.** The two claims above that read as
reassuring ("moved down a severity class", "no threat detection recorded") were both true when
measured and are both false now, on the same bytes.

### 2026-08-12 — POST-PUBLISH ESCALATION on the unchanged 2.1.0 hash

⛔⛔ **A scan result is a snapshot of the SCANNERS, not a property of the binary.** Every
section above this one records a *pre-publish* scan, which quietly assumes the result belongs
to the artifact and therefore keeps. It does not. `9fed2a6a…` was never modified — both
release assets still carry `updatedAt 2026-08-06T09:25:13Z` and 1,290,240 bytes — and
Microsoft re-scored it anyway, six days after publish, from a class Defender ignores to one it
acts on.

| When | Microsoft engine | Verdict | Defender enforces? |
|---|---|---|---|
| 2026-08-06 12:14 IDT — first submission | — | `Program:Win32/Wacapew.C!ml` | no (`Program:` = PUA prefix) |
| **2026-08-11 23:00 IDT — reanalysis** | **1.26070** | **`Trojan:Win32/Phonzy.A!ml`** | **YES — Severe, auto-quarantine** |

Aggregate is unchanged at **3 of 71** (67 undetected, 1 failure, 4 type-unsupported), so the
count did not move — only the class did. ⛔ **The count is therefore not a sufficient gate
statistic.** A gate reading "0–2 detections" would have scored this event as no change at all,
while distribution was breaking.

**It is a reputation call, not a content match.** VirusTotal's own aggregate label for the hash
is `trojan.phonzy/reputation` and `reputation: 0`. All three detections are generic rather than
identifications: Microsoft's `!ml` suffix marks a machine-learning classification, Sophos
reports `Generic Reputation PUA`, Malwarebytes `Malware.Heuristic.2099`.

⚠️ **Do not restate this as "no engine names a family."** Earlier sections of this file use that
phrasing and it no longer holds — `Phonzy.A` *is* a family label in Microsoft's taxonomy. The
defensible claim is about **method** (`!ml` / `Heuristic` / `Generic Reputation` = classifier
output, not a signature match on a known sample), not about the absence of a name. ⛔ Likewise
do not cite the sandbox verdict as exoneration: there is exactly one on record (C2AE) and it
reads `UNKNOWN_VERDICT`, which is an absence of evidence, not evidence of absence.

⭐ **Measured 2026-08-12 — signing is not sufficient, and prevalence is the variable doing the
work.** `Get-AuthenticodeSignature` on the local AutoHotkey 2.0 install returns `NotSigned` for
all three of `v2\AutoHotkey64.exe`, `UX\AutoHotkeyUX.exe` and `Compiler\Ahk2Exe.exe`. So the
interpreter this project is built on is **unsigned and unflagged**, while a binary made of that
same interpreter is flagged. The difference between them is installed prevalence, not a
certificate. ⚠️ This qualifies the claim in `docs/RELEASING.md` step 4 that "code signing is
the only real fix" — it is the only lever *available to purchase*, which is not the same thing,
and a cert on a utility with 150 downloads buys a publisher identity with no reputation
attached to it yet.

**Observed off the build box.** The quarantine fired on a machine whose Windows profile is
`C:\Users\ledry`; this repo's build machine is `C:\Users\97254` and has no such profile. So it
is a cloud-side verdict reaching real downloads, not a local cache artifact on the developer's
own PC.

⛔ **Do NOT rebuild to dodge it.** The verdict is driven by low prevalence on an unsigned
binary, so a fresh hash starts at reputation 0 and is a *worse* draw, not a better one. This is
the same ⛔ already recorded in `docs/RELEASING.md` step 4, now with a direct measurement
behind it.

**The remedy that exists and was declined:** a false-positive submission to
<https://www.microsoft.com/en-us/wdsi/filesubmission> under the **Software developer** persona
corrects the cloud verdict for all users within roughly a day, with no rebuild and no new
release. **Liav declined to submit on 2026-08-12.** Recorded as a decision, not an oversight —
so a future session does not "discover" the option and re-litigate it. The two levers that
change what Defender *does* are that submission and a signing certificate; both are declined,
therefore the standing posture is to document the false positive and give blocked users a
source-based route (README → *If Windows flags the download*), not to fight the detection.

**Watch signal:** the Softpedia and MajorGeeks listings re-scan independently (MajorGeeks with
Bitdefender + ESET). A PUA-class label survives that; a Trojan-class one may not. A pulled
listing — not the download count — is the signal that this stopped being cosmetic.

### 2026-09-12 — IT STOPPED BEING COSMETIC, AND THE FIX WAS STRUCTURAL

⭐⭐ **The compiled distribution is retired.** Everything above this section is the record of a
project trying to get a good roll out of a slot machine. This section is the one where it stopped
playing.

**What happened.** Liav could not download his own release. Chrome reported *"Failed - Virus
detected"* and deleted the file mid-download, from the canonical
`releases/latest/download/Window-Center-Resize.exe` URL. Defender's own log, on the build
machine:

```
InitialDetectionTime : 9/12/2026 12:55:00 PM
ThreatID             : 2147772962          (Trojan:Win32/Wacatac.B!ml)
Resources            : C:\Users\97254\Downloads\Window-Center-Resize (1).exe
                       <- release-assets.githubusercontent.com
```

⛔ **On the build machine.** The 2026-08-12 entry noted the quarantine was observed *off* the
build box and treated that as evidence it was cloud-side rather than local. It is now both.

**Third Microsoft verdict on bytes that never changed.** `9fed2a6a…` has been re-scored twice
since publication, and the aggregate count never moved off 3:

| When | Microsoft verdict | Defender enforces? |
|---|---|---|
| 2026-08-06 | `Program:Win32/Wacapew.C!ml` | no (PUA prefix) |
| 2026-08-11 | `Trojan:Win32/Phonzy.A!ml` | yes |
| **2026-09-12** | **`Trojan:Win32/Wacatac.B!ml`** | **yes** |

#### ⭐ The measurement that ended the argument

Every earlier section reasoned about *"unsigned + zero reputation"* as one compound cause, and
concluded code signing was the only purchasable lever. That framing hid the actual variable.
Both files below are **unsigned**, scanned against the same Microsoft engine build (1.26080)
within a day of each other:

| | Stock `AutoHotkey64.exe` 2.0.26 | Compiled 2.1.0 release |
|---|---|---|
| SHA-256 | `a2a54b8abc476d7671d4de0771bb54bf5f2373d79ff6871d0ba6a62c3b88ae00` | `9fed2a6a…` |
| Microsoft | **undetected** | `Trojan:Win32/Wacatac.B!ml` |
| Aggregate | **0 / 70** | 3 / 71 |
| Signed | no | no |
| Size | 1,272,832 B | 1,290,240 B |

**17,920 bytes apart — 1.4% of the file.** The other 98.6% is byte-identical to a binary
Microsoft calls clean. ⭐ **So signing was never the variable.** What `Ahk2Exe` adds is a script
welded into a copy of the interpreter, which is precisely how a great deal of real malware is
packaged — the classifier is correct about the category and wrong about this file. The lever
that was available the whole time was *stop producing a modified binary*, and no section above
considered it.

⚠️ **This qualifies, but does not delete, the earlier claim that rebuilding is futile.** Rebuilding
the *same artifact shape* remains futile — a new hash starts at reputation 0. Changing the shape
is a different act, and it works.

#### The fix

`build/build-portable.ps1`. Ships the interpreter **byte-identical** under the app's name
(reputation follows contents, and renaming does not change contents) with the flattened script
beside it as plain text. Verified: a renamed stock interpreter launched with no arguments runs
the same-named `.ahk` next to it.

**Verification, on the enforcement path rather than on VirusTotal alone.** Both artifacts tagged
with Mark-of-the-Web (`ZoneId=3`, HostUrl a GitHub release), then force-scanned by the local
Defender on the same machine in the same minute:

| | Portable zip | Control: compiled 2.1.0 |
|---|---|---|
| `Start-MpScan` on the extracted folder | all files survive | — |
| Reading the file | fine | *"the file contains a virus or potentially unwanted software"* |
| Defender detections logged | **none** | held, unreadable |
| VirusTotal | **0 / 75**, Microsoft undetected | 3 / 71 |

Two independently built zips were scanned, on separate builds hours apart:
`eb2fbb67…` (the prototype) and `5cc9c99e…` (post version-bump), plus the flattened script
`c4686c0d…`. **All three: 0 detections, Microsoft undetected.**

⚠️ **The zip hash is NOT reproducible, and this is a change from the compiled era.** Measured
2026-09-12 — two consecutive builds from identical source:

| Artifact | Build 1 | Build 2 | |
|---|---|---|---|
| `WindowCenterResizer.ahk` | `29db3182…` | `29db3182…` | **deterministic** |
| `Window-Center-Resize-portable.zip` | `5cc9c99e…` | `6a712db9…` | **differs** |

`Compress-Archive` stores file modification times, and the script is rewritten on every build,
so the zip hash changes even when nothing else does. ⛔ `docs/RELEASING.md` previously recorded
that "the build **is** deterministic" — that was measured on the compiled exe and does not carry
over. The consequence is that *build once → scan that file → upload that file → publish that
hash* is no longer merely good practice but the only thing that can work: a rebuild cannot
reproduce a published zip hash. The three **contents** are stable and are the more useful things
to publish.

Functionally verified, not assumed: 84 unit assertions green, plus two end-to-end runs driving a
real window through the real global hotkeys (`tests/manual_e2e_portable.ahk`) — centring to
within 1px, and F9 cycling all three presets centred.

#### Decisions

**Liav, 2026-09-12: break the old download links rather than keep serving a flagged binary.**
In his words: *"i prefer they would be broken rather than people think i'm trying to put malware
on their pcs."* `RELEASING.md` step 3 had insisted for two releases that
`Window-Center-Resize.exe` must never be dropped because directories and mirrors linked it. It is
dropped at 2.2.0. ⛔ Do not re-add it.

**The WDSI false-positive submission remains declined** (standing since 2026-08-12, re-raised and
re-declined today). Consequence, stated plainly so nobody re-discovers it as a surprise: **2.1.0
and earlier stay flagged forever.** Anyone arriving on an old link gets a 404 rather than a
quarantine, and the README tells them to download the current release instead.

#### ⛔ What this does NOT fix

- **Signing is still required before any paid product.** Unchanged from every section above. This
  release is free.
- **The shipped interpreter is now a third-party dependency with its own reputation**, and it can
  be re-scored without anything in this repo changing — which is exactly what happened to 2.1.0.
  A new release must re-check the interpreter hash, and must not ship a just-released AutoHotkey
  version, whose prevalence starts low. See `docs/RELEASING.md` step 2.
- **SmartScreen is a separate mechanism** and was never the problem here. An unsigned, unknown
  binary can still raise *"Windows protected your PC"*; that is a one-click prompt, not a
  quarantine. ⚠️ Earlier sections of this file conflate the two. They are different systems with
  different triggers, and only the Defender one was deleting downloads.
