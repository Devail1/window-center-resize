#Requires AutoHotkey v2.0

; Validates by asking AutoHotkey itself: register the hotkey disabled, then remove it.
; A malformed key name throws, which is exactly the condition we want to detect.
IsValidHotkey(hk) {
    if (hk = "")
        return false
    ; Strip modifier symbols; something must remain.
    bare := RegExReplace(hk, "[\^\+\!\#\<\>\*\~\$]", "")
    if (bare = "")
        return false
    try {
        Hotkey(hk, (*) => 0, "Off")
        Hotkey(hk, "Off")
        return true
    } catch {
        return false
    }
}
