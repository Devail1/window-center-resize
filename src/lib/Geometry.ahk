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
