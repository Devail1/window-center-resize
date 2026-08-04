#Requires AutoHotkey v2.0
#Include "_harness.ahk"
; Loads the settings window's file-level helpers. Including this file does NOT create or show
; a GUI — it only defines APP_TITLE, PreserveHotkey and ShowSettingsWindow.
#Include "..\src\gui\SettingsWindow.ahk"

; --- The data-loss guard -------------------------------------------------------------------
; The native Hotkey control cannot hold a Win-key combination: "#Up" assigned to it reads back
; as an empty string, silently. Without a guard, a user whose settings.ini says "#Up" opens
; Settings (blank field), presses Save, and their hotkey is gone. This is the assertion that
; stands between them and that.
AssertEqual(PreserveHotkey("", "#Up"), "#Up"
          , "THE ONE THAT MATTERS: an empty read-back keeps the loaded Win-key hotkey")
AssertEqual(PreserveHotkey("", "#+Left"), "#+Left"
          , "any Win combination survives, not just #Up")

; The control also reads back empty for anything else it cannot parse, and the INI is
; hand-editable — a preserved junk value is then rejected by IsValidHotkey on Save, which
; tells the user. Losing it silently would not.
AssertEqual(PreserveHotkey("", "totalgarbage!!"), "totalgarbage!!"
          , "an unparseable hand-edited value is preserved, not silently dropped")

; A non-empty read-back is the user's actual choice and must win.
AssertEqual(PreserveHotkey("+^c", "#Up"), "+^c"
          , "a real capture overrides the loaded value")
AssertEqual(PreserveHotkey("F9", "^+c"), "F9"
          , "a modifier-less capture overrides the loaded value")

; Modifier order is NORMALIZED by the control (^+c reads back +^c). Both bind identically,
; so the normalised form is written through unchanged — no normalisation layer of our own.
AssertEqual(PreserveHotkey("+^c", "^+c"), "+^c"
          , "reordered modifiers are written through as-is")

; Whitespace-only is empty for this purpose.
AssertEqual(PreserveHotkey("   ", "#Up"), "#Up"
          , "a whitespace-only read-back counts as empty")
AssertEqual(PreserveHotkey(" !x ", "#Up"), "!x"
          , "a captured value is trimmed")

; Nothing loaded and nothing captured stays empty — IsValidHotkey rejects it on Save.
AssertEqual(PreserveHotkey("", ""), ""
          , "empty in, empty out — the guard invents nothing")

; --- FIX 1: the title is spelled once, with ONE ampersand ----------------------------------
AssertEqual(APP_TITLE, "Window Center & Resizer"
          , "the title bar text carries a single ampersand")

; --- Closure integrity ---------------------------------------------------------------------
; _Populate records the loaded value and _Save reads it back. They are separate nested
; functions sharing one enclosing scope. If AutoHotkey gave each its own copy, the guard above
; would be handed an empty loaded value and would preserve nothing. This proves the sharing.
_ClosurePair() {
    loaded := ""
    _Set(v) {
        loaded := v
    }
    _Get() {
        return loaded
    }
    ; An ARRAY, not an object with named properties: obj.fn(x) is a METHOD call in AHK v2 and
    ; would pass the object itself as an extra first argument.
    return [_Set, _Get]
}
pair := _ClosurePair()
setLoaded := pair[1], getLoaded := pair[2]
setLoaded("#Up")
AssertEqual(getLoaded(), "#Up"
          , "sibling nested functions share the enclosing scope's variable")

ReportAndExit()
