#Requires AutoHotkey v2.0
#Include "_harness.ahk"
#Include "..\src\lib\Hotkeys.ahk"

AssertEqual(IsValidHotkey("^+c"),  true,  "ctrl+shift+c is valid")
AssertEqual(IsValidHotkey("F9"),   true,  "a bare function key is valid")
AssertEqual(IsValidHotkey("^!x"),  true,  "ctrl+alt+x is valid")
AssertEqual(IsValidHotkey("#Up"),  true,  "win+Up is valid")
AssertEqual(IsValidHotkey(""),     false, "empty string is invalid")
AssertEqual(IsValidHotkey("^"),    false, "modifiers alone are invalid")
AssertEqual(IsValidHotkey("^+!#"), false, "only modifiers is invalid")
AssertEqual(IsValidHotkey("NotAKey"), false, "an unknown key name is invalid")

ReportAndExit()
