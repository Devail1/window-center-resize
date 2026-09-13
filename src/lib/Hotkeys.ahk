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

; The form of a hotkey used ONLY for deciding whether two of them are the same key.
;
; ⛔ AutoHotkey hotkey names are CASE-INSENSITIVE: ^+c and ^+C are one key, and registering both
; means the second silently replaces the first — the precise failure every duplicate check here
; exists to prevent. A case-sensitive comparison waves that pair through. Leading and trailing
; whitespace is not a second key either, and the INI is hand-editable, so it is trimmed.
;
; The ORIGINAL string is what gets registered and written back; this is for comparison only.
NormalizeHotkeyName(hk) {
    s := StrLower(Trim(hk))
    if (s = "")
        return ""
    ; ⛔ A direction prefix BINDS to the modifier that follows it, so <^+c (left-ctrl + shift)
    ; and ^<+c (ctrl + left-shift) are genuinely different keys. Canonicalising their order
    ; would invent an equivalence and refuse a save that is perfectly legal, so these are
    ; compared exactly as written. Erring toward "not the same key" is the safe direction here:
    ; the failure it risks is a clash reported late, not a binding silently destroyed.
    if (InStr(s, "<") || InStr(s, ">"))
        return s
    ; ⛔ Modifier ORDER is not meaning: ^+c and +^c are one key. The native Hotkey control
    ; renders one and reads back the other, so without this a row rewrote its own stored value
    ; just by being selected, and two rows holding one key in different orders passed the clash
    ; check.
    mods := "", rest := ""
    loop parse s {
        if (rest = "" && InStr("^!+#*~$", A_LoopField))
            mods .= A_LoopField
        else
            rest .= A_LoopField
    }
    canon := ""
    for m in ["#", "^", "!", "+", "*", "~", "$"] {
        if InStr(mods, m)
            canon .= m
    }
    return canon . rest
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
        seen[NormalizeHotkeyName(r)] := true
        plan.Push({ key: r, action: "resize", index: 0 })
    }
    for i, p in s["positions"] {
        k := NormalizeHotkeyName(p.hotkey)
        if (k = "" || seen.Has(k) || !IsValidHotkey(p.hotkey))
            continue
        seen[k] := true
        plan.Push({ key: p.hotkey, action: "position", index: i })
    }
    return plan
}

; Finds the FIRST pair of bindings that are the same key, or "" if there is no such pair.
;
; PlanHotkeyRegistration drops a duplicate so the running app still works, which is the right
; behaviour at runtime and the wrong one in a settings window: the user typed two things and
; one of them would quietly never happen. The window refuses the save instead, and needs to
; name both rows to say why — hence a structured result rather than a boolean.
;
; The claim order matches the plan's on purpose. Resize is claimed first, so when a position
; collides with it the POSITION is the one reported as losing the key, which is what actually
; happens.
;
; An empty hotkey is not a clash. A row added but not yet bound is a legal state — making it
; illegal would turn adding a position into a modal argument.
FindHotkeyConflict(resizeHotkey, positions) {
    seen := Map()
    r := NormalizeHotkeyName(resizeHotkey)
    if (r != "")
        seen[r] := { kind: "resize", index: 0 }
    for i, p in positions {
        k := NormalizeHotkeyName(p.hotkey)
        if (k = "")
            continue
        if (seen.Has(k)) {
            f := seen[k]
            return { key:        Trim(p.hotkey)
                   , firstKind:  f.kind
                   , firstIndex: f.index
                   , secondKind: "position"
                   , secondIndex: i }
        }
        seen[k] := { kind: "position", index: i }
    }
    return ""
}
