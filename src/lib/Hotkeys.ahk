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
    ; A bare SINGLE PRINTABLE CHARACTER with no modifier (e.g. "c") registers `c::`, which
    ; suppresses the native keypress SYSTEM-WIDE — including inside the settings box where
    ; the user would type "^+c" to undo it — and it persists to the INI, so a restart
    ; reapplies it. Reject it. NAMED keys are unaffected because their names are longer than
    ; one character: F9 (the DEFAULT resize hotkey), Up, PrintScreen all stay valid without
    ; a modifier.
    if (StrLen(bare) = 1 && !RegExMatch(hk, "[\^\+\!\#]"))
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

; Decides WHAT to register, without registering anything. Pure, so the rule survives being
; tested; the caller only walks the result and calls Hotkey().
;
; It exists because AHK v2 cannot unregister a hotkey and re-registering one silently replaces
; the earlier binding's callback. With one Center key and one Resize key a collision needed a
; hand-edited file. With a list of positions it needs only two rows that agree, so the rule is
; written down: the FIRST claim on a key keeps it and everything after is dropped.
;
; Resize is claimed BEFORE the positions, and that order is the whole point rather than an
; implementation detail. Positions are a list the user edits and re-orders; the resize key is
; one long-standing binding they have muscle memory for. Claiming positions first would let a
; row somebody just added take F9 and silently end the size cycle, with nothing on screen to
; say why it stopped working.
PlanHotkeyRegistration(s) {
    plan := []
    seen := Map()
    r := s["resizeHotkey"]
    if (r != "" && IsValidHotkey(r)) {
        seen[r] := true
        plan.Push({ key: r, action: "resize", index: 0 })
    }
    for i, p in s["positions"] {
        if (p.hotkey = "" || seen.Has(p.hotkey) || !IsValidHotkey(p.hotkey))
            continue
        seen[p.hotkey] := true
        plan.Push({ key: p.hotkey, action: "position", index: i })
    }
    return plan
}
