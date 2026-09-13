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

; Pure. The INVERSE of AnchoredRect: a rectangle back to the anchor that produced it.
;
; The editor drags a rectangle around a PICTURE of the screen, and the picture is just another
; work area — same arithmetic, so the same pair of functions serves both.
;
; ⛔ percent -> pixels -> percent is NOT the identity. Both directions round, and at some sizes
; the midpoint falls the wrong way: h 60% of a 242px area is 145, leaving slack 97, so ay 50
; places at Round(48.5) = 49 and reads back as Round(50.5) = 51. A position stored as 50 would
; drift to 51 with the user never having touched that axis — and since the editor reads the
; rectangle back on every drag frame, one nudge sideways would rewrite the other axis.
;
; So: if the rectangle is EXACTLY what prev already describes, prev IS the answer. Nothing
; moved, so nothing changed. That also keeps a "keep current size" position (w/h = 0) from
; being silently converted into a fixed size by a drag that never resized it.
AnchorFromRect(waLeft, waTop, waWidth, waHeight, r, prev, curW, curH) {
    was := AnchoredRect(waLeft, waTop, waWidth, waHeight, prev, curW, curH)
    if (was.x = r.x && was.y = r.y && was.w = r.w && was.h = r.h)
        return { ax: prev.ax, ay: prev.ay, w: prev.w, h: prev.h }
    ; No slack means no anchor to read: a full-width window could be at any anchor at all, so
    ; keep the one it had rather than reset it to zero with a division that cannot be done.
    slackX := waWidth - r.w, slackY := waHeight - r.h
    return { ax: (slackX > 0) ? Round((r.x - waLeft) / slackX * 100) : prev.ax
           , ay: (slackY > 0) ? Round((r.y - waTop)  / slackY * 100) : prev.ay
           , w:  Round(r.w / waWidth  * 100)
           , h:  Round(r.h / waHeight * 100) }
}

; Pure. Position and size do NOT share a grid, and that asymmetry is the design, not an
; oversight. Position wants to LAND: there are only a handful of placements anyone means
; (flush, quarter, centre) and a coarse grid makes them decisive. A step of 0 means no grid.
SnapAnchorPct(pct, step) {
    v := (step > 0) ? Round(pct / step) * step : Round(pct)
    return Max(0, Min(100, v))
}

; Pure. Size is a continuum, and the widths people ask for are NOT evenly spaced — a third is
; 33.3%, which lands on no uniform grid. So a fine grid, plus magnets at the fractions that get
; asked for, with a pull radius wider than the grid step.
;
; ⛔ The magnet must beat the RAW value, never the already-rounded one. Against a 1% grid,
; rounding is always within half a percent while a magnet may be a whole radius away, so
; comparing the two made the pull silently do nothing.
SnapSizePct(pct, step, magnets, radius) {
    found := false, best := 0, nearest := radius
    for m in magnets {
        d := Abs(m - pct)
        if (d <= nearest) {
            nearest := d
            best := m
            found := true
        }
    }
    if (found)
        return Max(0, Min(100, best))
    v := (step > 0) ? Round(pct / step) * step : Round(pct)
    return Max(0, Min(100, v))
}
