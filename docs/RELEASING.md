# Releasing

The procedure for cutting a release of Window Center & Resizer. Every step below exists
because skipping it breaks something for existing users.

⚠️ **This procedure changed at 2.2.0.** Releases are no longer a compiled `.exe`. If you are
reading this expecting `Ahk2Exe`, read *Why the download is a zip* in the README first, and
`build/av-baseline.md` for the measurements behind the change.

## 1. Stop any running instance

`build-portable.ps1` fails fast if `WindowCenterResizer.exe` is running, because a running
instance holds a handle on the output path and the copy would fail partway through, leaving a
half-written folder.

Exit the app from its tray icon before building.

## 2. Build once

```
powershell -ExecutionPolicy Bypass -File build\build-portable.ps1
```

This writes `dist\portable\` and zips it to `dist\Window-Center-Resize-portable.zip`. It
flattens the `#Include` tree in `src\` into one script, copies the installed AutoHotkey
interpreter beside it, and **throws if the copied interpreter's SHA-256 does not match the
installed one.**

⛔ **Never add an icon or a version resource to the shipped `.exe`.** Either one modifies the
file, which is the entire thing this build exists to avoid. The `.exe` showing AutoHotkey's
green H is not a bug to fix; it is the cost that buys a download that works.

### The interpreter you ship is a release decision

`build-portable.ps1` copies whichever AutoHotkey v2 is installed on the build machine. That
binary's *reputation* is what keeps the download clean, and reputation accrues with
prevalence, so:

- ⛔ **Do not ship a just-released AutoHotkey version.** A fresh interpreter build has the same
  zero-prevalence problem the compiled exe had. Let a version circulate before shipping it.
- Record the interpreter version **and hash** in `build/av-baseline.md` with every release, and
  check the hash on VirusTotal before publishing (step 4). It is a third-party binary that can
  be re-scored without anything in this repo changing — exactly what happened to 2.1.0.
- CI pins `AHK_VERSION` in `.github/workflows/test.yml`. Keep the shipped interpreter and the
  tested one on the same version, or the suite is not testing what users run.

## 3. Attach the zip, and generate the notes

Upload `dist\Window-Center-Resize-portable.zip` as `Window-Center-Resize-portable.zip`.

⛔ **Do not hand-write the release page.** It was hand-written up to 2.2.0, which made it a second
copy of `CHANGELOG.md` kept in step by hand — and this copy is public, because Softpedia renders
the CHANGELOG into its *What's New* panel. Two public texts saying the same thing drift, and the
disagreement is visible. Generate it:

```
powershell -ExecutionPolicy Bypass -File build\release-notes.ps1 -Version 2.2.0 > dist\notes.md
gh release create v2.2.0 dist\Window-Center-Resize-portable.zip ^
   --title "2.2.0 - short factual phrase" --notes-file dist\notes.md
```

The generator takes the `## <version>` section of `CHANGELOG.md` verbatim, appends the
version-independent install block, and computes the hashes **from the artifacts on disk** — so
what is published cannot disagree with what was built. It refuses to run if the CHANGELOG has no
section for the version, and `tests/test_docs_sync.ahk` fails on the same condition so you find
out before the tag is pushed rather than after.

**Titles are `<version> - short factual phrase`**, no `v` prefix — matching `2.0.0 - one portable
exe, 64 MB smaller` and `2.1.0 - settings window refreshed`. Lead with what changed for the user.
⛔ Keep antivirus wording out of the title: it propagates to the directory listings and invites
exactly the association the 2.2.0 work existed to remove.

⛔ **Do not resurrect the `Window-Center-Resize.exe` asset name.** Up to 2.1.0 that name was
load-bearing: the README, every software directory and every mirror linked to
`releases/latest/download/Window-Center-Resize.exe`, and RELEASING previously insisted it must
never be dropped. It was dropped at 2.2.0 on a deliberate decision — those links now 404,
which is the intended outcome. The only file that URL could serve is the compiled build, and
that build is quarantined on arrival. **A broken link is better than knowingly shipping people
a file their antivirus deletes**, which was the reasoning; do not re-add the asset to "fix" the
directories. Update the directory listings instead.

## 4. Scan what you are about to publish

Scan the zip on VirusTotal and publish that hash, and separately confirm the interpreter hash
is still clean.

```
vt scan file dist/Window-Center-Resize-portable.zip    # prints an analysis id
vt analysis <id>                                       # poll until status: "completed"
vt file <interpreter-sha256>                           # the shipped AutoHotkey64.exe
```

Record both in `build/av-baseline.md`, and **refresh the two VirusTotal links in the README**
(*Why the download is a zip with two files in it*). The zip link pins a specific release's hash
and goes stale every release; the interpreter link only changes when the shipped AutoHotkey
version does. ⛔ Links, never a badge — a badge claiming a detection count is a safety claim
that silently becomes false the next time an engine re-scores, which this project has watched
happen twice on unchanged bytes.

⛔ **Build once, scan that file, upload that file, publish that hash.** This was good practice
for the compiled exe, which was byte-reproducible; for the zip it is the only thing that works.
`Compress-Archive` stores modification times and the script is rewritten every build, so **two
builds from identical source produce different zip hashes** (measured 2026-09-12). A rebuild at
any point after scanning invalidates the published hash and it will not match what people
download. The *contents* are reproducible — the flattened script hashes identically across
builds — so publish the script and interpreter hashes alongside the zip's if you want a figure
anyone can verify for themselves.

**What carries over from the compiled era, and still applies:**

- ⛔ **A clean scan at publish time does not keep.** Measured twice on 2.1.0: Microsoft
  re-scored the *unchanged* hash from a PUA prefix Defender ignores to `Trojan:Win32/Phonzy.A!ml`
  and later `Trojan:Win32/Wacatac.B!ml`, both Severe, with the aggregate count sitting still at
  3/71 throughout. **The count is not a sufficient gate statistic — read Microsoft's class.**
- ⛔ **Do not iterate an artifact against these heuristics.** Seventy-odd non-deterministic
  engines, one scan per attempt, nothing to reason about. A lower number on the next attempt is
  noise.

**What has changed, and it is the point of 2.2.0:** the old procedure scanned a binary this
project created, and could only hope for a good draw. There is no such binary any more. The
shipped `.exe` is a third-party file with its own established reputation, and the script is
plain text. So the scan is a regression check rather than a gamble — and the question it
answers has moved from *"was this a good roll?"* to *"is the shipped interpreter still the
stock one, and is it still clean?"*

**The gate.** Any detection on the zip, or any Microsoft detection on the interpreter, stops
the release. Unlike the compiled builds — which failed their gate twice and shipped anyway on
an explicit decision — this one is expected to pass cleanly, so a failure means something
genuinely changed and is worth stopping for.

## 5. Tag format — three numeric segments only

⛔ **Never publish a prerelease tag or a four-segment version tag to this repo.**

`CompareVersions` in `src/lib/UpdateCheck.ahk` parses at most three segments and coerces a
non-numeric segment to `0`. Consequently:

- `2.0.0-beta` compares **equal** to `2.0.0`
- `2.0.0.1` compares **equal** to `2.0.0`

In both cases every installed copy of the app would report "You're up to date" against a
release that is genuinely newer, and the update check would silently stop working.

Use plain `v2.0.0`, `v2.0.1`, `v2.1.0`.

## 6. Update the directory listings

Softpedia and MajorGeeks host their own copies and link their own URLs. From 2.2.0 their
download links point at an asset that no longer exists, and their listed size (1.23 MB / 2 MB)
is wrong. Submit an update to each. MajorGeeks re-scans with Bitdefender and ESET; both were
clean on the compiled build and should stay clean here.
