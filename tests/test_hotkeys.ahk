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

; REGRESSION GUARD: AHK v2 cannot unregister a hotkey, so a validation probe registered in
; the DEFAULT context would permanently overwrite a live binding's callback and leave it
; disabled. Validation must therefore leave nothing addressable in the default context.
; Hotkey(name, "On") throws for a hotkey that does not exist in the current context.
IsValidHotkey("^+F13")
leaked := true
try
    Hotkey("^+F13", "On")
catch
    leaked := false
AssertEqual(leaked, false, "validation must not register in the default context")

ReportAndExit()
