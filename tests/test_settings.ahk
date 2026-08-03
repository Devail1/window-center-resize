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

FileDelete(tmp)
ReportAndExit()
