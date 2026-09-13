#Requires AutoHotkey v2.0

; Pure. Given a monitor WORK AREA rect and percentages, return the centered target rect.
; Sizing and centering both derive from the SAME rect — this is what fixes the
; primary-vs-current monitor bug and the full-screen-vs-work-area bug.
CenteredRect(waLeft, waTop, waWidth, waHeight, widthPct, heightPct) {
    w := Round(waWidth  * widthPct  / 100)
    h := Round(waHeight * heightPct / 100)
    x := waLeft + Round((waWidth  - w) / 2)
    y := waTop  + Round((waHeight - h) / 2)
    return { x: x, y: y, w: w, h: h }
}

; Pure. A position is an ANCHOR plus a size, and this resolves it against a WORK AREA rect.
;
; pos.ax / pos.ay run 0..100 across the SLACK — the part of the work area the window does not
; occupy — so 0 is flush left/top, 100 is flush right/bottom, and 50 is centred whatever the
; window's size turns out to be. A full-size window has no slack, and every anchor collapses
; to the same flush position, which is correct rather than a special case.
;
; pos.w / pos.h of 0 mean "keep the size the window already has", supplied as curW/curH. That
; is what lets Center be a position: 50/50/0/0 moves a window to the middle without touching
; its size, which is exactly what CenterActiveWindow has always done.
;
; Sizing and anchoring both derive from the SAME rect, for the same reason CenteredRect does —
; it is what keeps a window sized off one monitor from being placed on another.
AnchoredRect(waLeft, waTop, waWidth, waHeight, pos, curW, curH) {
    w := (pos.w > 0) ? Round(waWidth  * pos.w / 100) : curW
    h := (pos.h > 0) ? Round(waHeight * pos.h / 100) : curH
    x := waLeft + Round((waWidth  - w) * pos.ax / 100)
    y := waTop  + Round((waHeight - h) * pos.ay / 100)
    return { x: x, y: y, w: w, h: h }
}
