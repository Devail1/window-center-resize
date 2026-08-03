#Requires AutoHotkey v2.0

; A context that is never active. Validation registers inside it so the probe cannot
; collide with any real binding.
_HotkeyProbeContext(*) => false

; Validates by asking AutoHotkey itself: register the hotkey disabled in an isolated context.
; AHK v2 has no API to unregister a hotkey, so a probe in the default context would
; permanently overwrite a live binding's callback and leave it disabled. Isolation via HotIf
; ensures the probe creates a variant that is absent from the default context.
; A malformed key name throws, which is exactly the condition we want to detect.
IsValidHotkey(hk) {
    if (hk = "")
        return false
    ; Strip modifier symbols; something must remain.
    bare := RegExReplace(hk, "[\^\+\!\#\<\>\*\~\$]", "")
    if (bare = "")
        return false
    try {
        HotIf(_HotkeyProbeContext)
        Hotkey(hk, (*) => 0, "Off")
        HotIf()
        return true
    } catch {
        HotIf()
        return false
    }
}
