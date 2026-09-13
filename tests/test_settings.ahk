#Requires AutoHotkey v2.0
#Include "_harness.ahk"
#Include "..\src\lib\Settings.ahk"

tmp := A_Temp "\wcr_test_settings.ini"
if FileExist(tmp)
    FileDelete(tmp)

; Missing file yields defaults, and the defaults match the shipped 1.x behaviour.
d := SettingsLoad(tmp)
AssertEqual(d["centerHotkey"], "^+c", "default center hotkey")
AssertEqual(d["resizeHotkey"], "F9",  "default resize hotkey")
AssertEqual(d["sizes"].Length,  3,    "three default sizes")
AssertEqual(d["sizes"][1].w,    50,   "first preset width")
AssertEqual(d["sizes"][3].h,    90,   "third preset height")

; Round-trip.
d["centerHotkey"] := "^!x"
d["sizes"][2] := { w: 60, h: 70 }
SettingsSave(tmp, d)
r := SettingsLoad(tmp)
AssertEqual(r["centerHotkey"], "^!x", "round-tripped center hotkey")
AssertEqual(r["sizes"][2].w,   60,    "round-tripped preset width")
AssertEqual(r["sizes"][2].h,   70,    "round-tripped preset height")
AssertEqual(r["resizeHotkey"], "F9",  "untouched key survives a round trip")

; Clamping.
AssertEqual(ClampPercent(150),   100, "over-max clamps to 100")
AssertEqual(ClampPercent(0),      10, "under-min clamps to 10")
AssertEqual(ClampPercent("abc"),  50, "non-numeric falls back to 50")
AssertEqual(ClampPercent("75"),   75, "numeric string is accepted")
AssertEqual(ClampPercent(66.7),   67, "fractional rounds")

; --- Named positions -----------------------------------------------------------------------
; A position is an ANCHOR plus a size, not a rectangle: ax/ay place the window (0 = left/top,
; 50 = centred, 100 = right/bottom) and w/h are percentages of the work area, where 0 means
; "keep whatever size the window already has". That is what lets the shipped Center action —
; move to the middle, do not resize — be expressed as a position without changing behaviour.
d2 := SettingsDefaults()
AssertEqual(d2.Has("positions"), true, "defaults carry a positions list")
; Exactly one position ships: Center. Shipping Left half and Right half too would claim two
; global hotkeys on an upgrading machine that nobody asked for, and Center on its own is not a
; placeholder — it is the app's existing behaviour, now expressed in the new model.
AssertEqual(d2["positions"].Length, 1, "one position ships by default")
AssertEqual(d2["positions"][1].name,   "Center", "the default position is Center")
AssertEqual(d2["positions"][1].hotkey, "^+c",    "it carries the shipped Center hotkey")
AssertEqual(d2["positions"][1].ax, 50, "Center anchors horizontally centred")
AssertEqual(d2["positions"][1].ay, 50, "Center anchors vertically centred")
AssertEqual(d2["positions"][1].w,  0,  "Center does NOT resize: zero width means keep")
AssertEqual(d2["positions"][1].h,  0,  "Center does NOT resize: zero height means keep")

; The list is variable-length, so it round-trips through a COUNT rather than a fixed loop.
d2["positions"] := [ { name: "A", hotkey: "^!1", ax: 0,  ay: 0,   w: 30, h: 40 }
                   , { name: "B", hotkey: "^!2", ax: 50, ay: 100, w: 0,  h: 0  }
                   , { name: "C", hotkey: "",    ax: 100, ay: 50, w: 60, h: 70 } ]
SettingsSave(tmp, d2)
r2 := SettingsLoad(tmp)
AssertEqual(r2["positions"].Length,   3,   "three positions round-trip")
AssertEqual(r2["positions"][2].name,  "B", "name round-trips")
AssertEqual(r2["positions"][2].ax,    50,  "anchor round-trips")
AssertEqual(r2["positions"][2].ay,    100, "bottom anchor round-trips")
AssertEqual(r2["positions"][2].w,     0,   "keep-size zero survives; it must NOT clamp to 10")
AssertEqual(r2["positions"][3].hotkey, "", "an unbound position is legal and stays unbound")

; Shrinking the list must REMOVE the sections it dropped. ROADMAP.md records the bug this
; guards: an orphaned entry left behind in the INI reappears as a row on the next start, so
; a deleted position comes back from the dead.
d2["positions"] := [ { name: "Only", hotkey: "^!9", ax: 0, ay: 0, w: 20, h: 20 } ]
SettingsSave(tmp, d2)
r3 := SettingsLoad(tmp)
AssertEqual(r3["positions"].Length, 1, "shrinking the list keeps only what is left")
AssertEqual(IniRead(tmp, "Position3", "Name", "<gone>"), "<gone>"
          , "a dropped position's section is deleted, not orphaned")

; A 2.2.0 file has no [Positions] at all. Everything it does have must survive untouched —
; this is the upgrade path for every install already in the wild.
old22 := A_Temp "\wcr_test_settings_22.ini"
if FileExist(old22)
    FileDelete(old22)
FileAppend("[Hotkeys]`nCenter=^!k`nResize=F11`n[Sizes]`nWidth1=35`nHeight1=45`n"
         . "Width2=75`nHeight2=75`nWidth3=90`nHeight3=90`n", old22)
u := SettingsLoad(old22)
AssertEqual(u["centerHotkey"], "^!k", "a 2.2.0 Center hotkey survives the upgrade")
AssertEqual(u["resizeHotkey"], "F11", "a 2.2.0 Resize hotkey survives the upgrade")
AssertEqual(u["sizes"][1].w,   35,    "a 2.2.0 size preset survives the upgrade")
AssertEqual(u["positions"].Length, 1, "a file with no [Positions] gets the one default")
; The upgrader rebound Center to ^!k years ago. The migrated position has to carry THEIR key,
; not the shipped one, or their centring shortcut silently stops working on upgrade.
AssertEqual(u["positions"][1].hotkey, "^!k", "migration carries the user's own Center hotkey")
FileDelete(old22)

; A hand-edited or corrupt Count must not become a loop bound. The file is text and the app
; invites people to edit it, so "Count=500000" has to be harmless rather than a hang on start.
huge := A_Temp "\wcr_test_settings_huge.ini"
if FileExist(huge)
    FileDelete(huge)
FileAppend("[Positions]`nCount=5000`n[Position1]`nName=Real`nHotkey=^!1`nAX=0`nAY=0`nW=30`nH=30`n"
         , huge)
h := SettingsLoad(huge)
AssertEqual(h["positions"].Length, 32, "an absurd Count is capped rather than looped over")
AssertEqual(h["positions"][1].name, "Real", "the positions that do exist still load")
FileDelete(huge)

FileDelete(tmp)
ReportAndExit()
