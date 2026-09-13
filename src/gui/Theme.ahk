#Requires AutoHotkey v2.0

; Every colour in the settings window resolves through here. No colour literal belongs at a
; control site — that is what makes a second theme a map rather than a rewrite of every Add().
;
; Values are BARE RRGGBB: Gui.BackColor and the 'c' font option both reject a leading # or 0x.
Theme(mode) {
    if (mode = "dark") {
        return Map(
            "bg",     "202020",
            "text",   "F2F2F2",
            "hint",   "A6A6A6",
            "header", "FFFFFF",
            ; The picture of the screen, and the box inside it. They must never be the same
            ; value: painted alike, the box is invisible and the picture reads as fully
            ; selected.
            "screen", "2B2B2B",
            "accent", "4C8DF6",
            "fill",   "3A4658"
        )
    }
    ; Light is also the fallback for any unrecognised mode. A settings window that throws
    ; because of a colour name is worse than one that is the wrong colour.
    return Map(
        "bg",     "F3F3F3",
        "text",   "1A1A1A",
        "hint",   "5D5D5D",
        "header", "101010",
        "screen", "FFFFFF",
        "accent", "3B82F6",
        "fill",   "FDFDFE"
    )
}
