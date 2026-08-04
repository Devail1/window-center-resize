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
            "header", "FFFFFF"
        )
    }
    ; Light is also the fallback for any unrecognised mode. A settings window that throws
    ; because of a colour name is worse than one that is the wrong colour.
    return Map(
        "bg",     "F3F3F3",
        "text",   "1A1A1A",
        "hint",   "5D5D5D",
        "header", "101010"
    )
}

; Segoe UI Variable ships with Windows 11 ONLY, and this app supports Windows 10 as well.
; AHK's SetFont with a family that is not installed does NOT error — Windows silently
; substitutes — so it would look right on a Windows 11 machine and wrong for every Windows 10
; user, with no signal at all. Hence an actual presence check rather than an OS-version proxy.
ResolveUiFont(preferred, fallback) {
    return (_FaceActuallyUsed(preferred) = preferred) ? preferred : fallback
}

; GetTextFace reports the face the GDI mapper ACTUALLY resolved, which is what exposes
; substitution. GetObject on the HFONT would return the face we ASKED for and can never
; detect this — do not swap it in.
_FaceActuallyUsed(request) {
    g := Gui()                          ; created, never shown; destroyed below
    g.SetFont("s10", request)
    t := g.Add("Text", "w10", "M")
    hFont := SendMessage(0x0031, 0, 0, , "ahk_id " t.Hwnd)     ; WM_GETFONT
    hdc := DllCall("GetDC", "ptr", t.Hwnd, "ptr")
    old := DllCall("gdi32\SelectObject", "ptr", hdc, "ptr", hFont, "ptr")
    buf := Buffer(64 * 2, 0)
    DllCall("gdi32\GetTextFaceW", "ptr", hdc, "int", 64, "ptr", buf)
    DllCall("gdi32\SelectObject", "ptr", hdc, "ptr", old)
    DllCall("ReleaseDC", "ptr", t.Hwnd, "ptr", hdc)
    g.Destroy()
    return StrGet(buf, "UTF-16")
}
