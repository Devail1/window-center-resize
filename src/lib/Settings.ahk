#Requires AutoHotkey v2.0

SettingsDefaults() {
    return Map(
        "centerHotkey", "^+c",
        "resizeHotkey", "F9",
        "sizes", [ {w: 50, h: 50}, {w: 75, h: 75}, {w: 90, h: 90} ],
        ; A position is an ANCHOR plus a size, never a rectangle. ax/ay place the window in
        ; the work area (0 = left/top, 50 = centred, 100 = right/bottom); w/h are percentages
        ; of the work area, and 0 on an axis means "keep the size the window already has".
        ;
        ; That zero is what keeps the shipped Center action honest. Center moves a window to
        ; the middle WITHOUT resizing it, so expressing it as a rectangle would silently start
        ; resizing every window of every user who upgrades. As an anchor it is exactly
        ; ax 50, ay 50, w 0, h 0 — the same operation, written down.
        ; Exactly one position ships. Shipping a Left half and a Right half as well would
        ; register two new system-wide hotkeys on every machine that upgrades, chosen by us,
        ; without being asked. Center is not a placeholder either: zero width and height mean
        ; "keep the window's size", so this single entry IS the app's existing Center action.
        "positions", [ { name: "Center", hotkey: "^+c", ax: 50, ay: 50, w: 0, h: 0 } ]
    )
}

ClampPercent(value) {
    if !IsNumber(value)
        return 50
    n := Round(value + 0)
    if (n > 100)
        return 100
    if (n < 10)
        return 10
    return n
}

; Anchors span the full 0..100 range — 0 and 100 are the left and right edges, and both are
; ordinary values, so this cannot reuse ClampPercent's 10..100 floor.
ClampAnchor(value) {
    if !IsNumber(value)
        return 50
    n := Round(value + 0)
    if (n < 0)
        return 0
    if (n > 100)
        return 100
    return n
}

; A position's size, where 0 is a legal value meaning "keep the size the window already has".
; Anything else goes through the same 10..100 clamp as a size preset. A garbage value becomes
; 0 rather than a guessed percentage: keeping the user's current size is the one outcome that
; cannot resize a window to something nobody asked for.
ClampSize(value) {
    if !IsNumber(value)
        return 0
    n := Round(value + 0)
    if (n <= 0)
        return 0
    return ClampPercent(n)
}

SettingsLoad(iniPath) {
    s := SettingsDefaults()
    if !FileExist(iniPath)
        return s

    s["centerHotkey"] := IniRead(iniPath, "Hotkeys", "Center", s["centerHotkey"])
    s["resizeHotkey"] := IniRead(iniPath, "Hotkeys", "Resize", s["resizeHotkey"])

    sizes := []
    loop 3 {
        dw := s["sizes"][A_Index].w
        dh := s["sizes"][A_Index].h
        w := ClampPercent(IniRead(iniPath, "Sizes", "Width"  . A_Index, dw))
        h := ClampPercent(IniRead(iniPath, "Sizes", "Height" . A_Index, dh))
        sizes.Push({ w: w, h: h })
    }
    s["sizes"] := sizes

    ; Count is authoritative. Probing "until a section is missing" would silently truncate a
    ; hand-edited file at the first gap, and an unbounded loop would hang on a typo, so the
    ; count is validated and capped before it is used as a loop bound. The settings window
    ; caps the list far lower; this bound only has to make a hostile file harmless.
    count := IniRead(iniPath, "Positions", "Count", "")
    if (IsInteger(count)) {
        n := Integer(count)
        if (n < 0)
            n := 0
        if (n > 32)
            n := 32
        positions := []
        loop n {
            sec := "Position" . A_Index
            positions.Push({ name:   IniRead(iniPath, sec, "Name",   "")
                           , hotkey: IniRead(iniPath, sec, "Hotkey", "")
                           , ax:     ClampAnchor(IniRead(iniPath, sec, "AX", 50))
                           , ay:     ClampAnchor(IniRead(iniPath, sec, "AY", 50))
                           , w:      ClampSize(IniRead(iniPath, sec, "W", 0))
                           , h:      ClampSize(IniRead(iniPath, sec, "H", 0)) })
        }
        s["positions"] := positions
    } else {
        ; No [Positions] section: this is a file written before positions existed. The user may
        ; have rebound Center years ago, and that binding is the one they press — so the
        ; migrated position inherits it rather than the shipped default, which would leave them
        ; pressing a key that no longer does anything.
        s["positions"][1].hotkey := s["centerHotkey"]
    }
    return s
}

SettingsSave(iniPath, s) {
    IniWrite(s["centerHotkey"], iniPath, "Hotkeys", "Center")
    IniWrite(s["resizeHotkey"], iniPath, "Hotkeys", "Resize")
    loop 3 {
        IniWrite(s["sizes"][A_Index].w, iniPath, "Sizes", "Width"  . A_Index)
        IniWrite(s["sizes"][A_Index].h, iniPath, "Sizes", "Height" . A_Index)
    }

    ; What WAS on disk, read before the new count overwrites it — the only way to know which
    ; sections this save is dropping.
    oldCount := IniRead(iniPath, "Positions", "Count", "")
    old := IsInteger(oldCount) ? Integer(oldCount) : 0
    if (old > 32)
        old := 32

    IniWrite(s["positions"].Length, iniPath, "Positions", "Count")
    for i, p in s["positions"] {
        sec := "Position" . i
        IniWrite(p.name,   iniPath, sec, "Name")
        IniWrite(p.hotkey, iniPath, sec, "Hotkey")
        IniWrite(p.ax,     iniPath, sec, "AX")
        IniWrite(p.ay,     iniPath, sec, "AY")
        IniWrite(p.w,      iniPath, sec, "W")
        IniWrite(p.h,      iniPath, sec, "H")
    }

    ; Lowering Count alone would leave the dropped sections sitting in the file. They are
    ; invisible until someone raises Count again — by hand, or by adding a position — at which
    ; point a position the user deleted returns, wearing its old name and hotkey.
    i := s["positions"].Length + 1
    while (i <= old) {
        try IniDelete(iniPath, "Position" . i)
        i += 1
    }
}
