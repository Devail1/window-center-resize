#Requires AutoHotkey v2.0
#Include "_harness.ahk"
#Include "..\src\lib\Geometry.ahk"

; A 1920x1080 monitor at origin with a 40px taskbar: work area 1920x1040 at (0,0).
r := CenteredRect(0, 0, 1920, 1040, 50, 50)
AssertEqual(r.w, 960,  "50% width of a 1920 work area")
AssertEqual(r.h, 520,  "50% height of a 1040 work area")
AssertEqual(r.x, 480,  "centered x")
AssertEqual(r.y, 260,  "centered y")

; Bug A: a secondary monitor at a different offset AND resolution must size off ITS OWN
; work area, not the primary's. Secondary 1280x1024 at x=1920.
r2 := CenteredRect(1920, 0, 1280, 1024, 50, 50)
AssertEqual(r2.w, 640,  "secondary monitor sizes off its own width")
AssertEqual(r2.h, 512,  "secondary monitor sizes off its own height")
AssertEqual(r2.x, 2240, "secondary monitor centers horizontally within its own bounds")
AssertEqual(r2.y, 256,  "secondary monitor centers vertically within its own bounds")

; Bug B: at 100% the rect must exactly fill the work area and never exceed it.
r3 := CenteredRect(0, 0, 1920, 1040, 100, 100)
AssertEqual(r3.w, 1920, "100% width fills work area exactly")
AssertEqual(r3.h, 1040, "100% height fills work area exactly")
AssertEqual(r3.x, 0,    "100% x is flush left")
AssertEqual(r3.y, 0,    "100% y is flush top")

; Bug C: odd arithmetic must produce integers, never fractional pixels.
;   1365 * 33/100 = 450.45 -> 450      (1365-450)/2 = 457.5 -> 458
;    767 * 33/100 = 253.11 -> 253      ( 767-253)/2 = 257
r4 := CenteredRect(0, 0, 1365, 767, 33, 33)
AssertEqual(r4.w, 450, "width rounds to a whole pixel")
AssertEqual(r4.h, 253, "height rounds to a whole pixel")
AssertEqual(r4.x, 458, "x rounds to a whole pixel")
AssertEqual(r4.y, 257, "y rounds to a whole pixel")

; A non-zero work-area top (taskbar docked to the top of the screen).
r5 := CenteredRect(0, 40, 1920, 1040, 50, 50)
AssertEqual(r5.y, 300, "y accounts for a non-zero work-area top")

; --- Anchored rectangles --------------------------------------------------------------------
; A position is an anchor plus a size. ax/ay run 0..100 across the SLACK in the work area —
; the space the window does not occupy — so 0 is flush left/top, 100 is flush right/bottom,
; and 50 is centred whatever the window's size. w/h of 0 means "keep the size it has", which
; is the only way the Center action can be a position without starting to resize windows.

; Center, expressed as a position: identical to what CenterActiveWindow does today.
a1 := AnchoredRect(0, 0, 1920, 1040, { ax: 50, ay: 50, w: 0, h: 0 }, 800, 600)
AssertEqual(a1.w, 800, "zero width keeps the window's current width")
AssertEqual(a1.h, 600, "zero height keeps the window's current height")
AssertEqual(a1.x, 560, "a 50 anchor centres horizontally")
AssertEqual(a1.y, 220, "a 50 anchor centres vertically")

; Left half and right half.
a2 := AnchoredRect(0, 0, 1920, 1040, { ax: 0, ay: 50, w: 50, h: 100 }, 800, 600)
AssertEqual(a2.x, 0,    "a 0 anchor is flush against the left edge")
AssertEqual(a2.w, 960,  "a sized position ignores the window's current width")
AssertEqual(a2.h, 1040, "100% height fills the work area")
AssertEqual(a2.y, 0,    "a full-height window has no slack to anchor within")

a3 := AnchoredRect(0, 0, 1920, 1040, { ax: 100, ay: 50, w: 50, h: 100 }, 800, 600)
AssertEqual(a3.x, 960, "a 100 anchor is flush against the right edge")

; Mixed: keep the width, set the height. Issue #13's "align left but keep my size" is this
; with w and h both zero.
a4 := AnchoredRect(0, 0, 1920, 1040, { ax: 0, ay: 100, w: 0, h: 50 }, 800, 600)
AssertEqual(a4.w, 800, "one axis can keep its size while the other is set")
AssertEqual(a4.h, 520, "the sized axis still comes from the work area")
AssertEqual(a4.y, 520, "a 100 anchor is flush against the bottom edge")

; The work-area offset is honoured the same way CenteredRect honours it.
a5 := AnchoredRect(1920, 40, 1280, 1024, { ax: 0, ay: 0, w: 50, h: 50 }, 800, 600)
AssertEqual(a5.x, 1920, "a secondary monitor anchors within its own bounds")
AssertEqual(a5.y, 40,   "a non-zero work-area top is the flush-top position")

; Whole pixels only, exactly as CenteredRect: 1365*33/100 = 450.45 -> 450, and the remaining
; slack of 915 at a 33 anchor is 301.95 -> 302.
a6 := AnchoredRect(0, 0, 1365, 767, { ax: 33, ay: 50, w: 33, h: 33 }, 100, 100)
AssertEqual(a6.w, 450, "anchored width rounds to a whole pixel")
AssertEqual(a6.x, 302, "anchored x rounds to a whole pixel")

; --- The inverse: a rectangle back to an anchor ----------------------------------------------
; The editor drags a rectangle around a PICTURE of the screen and has to write an anchor back.
; The picture is just another work area, so the same AnchoredRect does the forward direction
; and this does the reverse.

; It must invert AnchoredRect exactly, at MANY picture sizes. Not a nicety: percent -> pixels
; -> percent is NOT the identity, because both directions round. h 60% of a 242px picture is
; 145, leaving slack 97, so ay 50 places at Round(48.5) = 49 and naively reads back as
; Round(50.5) = 51 -- a stored 50 drifting to 51 with the user never touching that axis.
; Measured on a 150% picture during the editor spike.
cases := [ { ax:   0, ay:  50, w:  50, h: 100 }
         , { ax: 100, ay:  50, w:  33, h: 100 }
         , { ax:  50, ay:  50, w:  60, h:  60 }
         , { ax:   0, ay:   0, w:  25, h:  25 }
         , { ax: 100, ay: 100, w:  25, h:  25 }
         , { ax:  50, ay:  50, w: 100, h: 100 } ]
drift := 0
for pw in [300, 330, 375, 420, 450, 480, 525, 600, 240, 270] {
    ph := Round(pw * 161 / 300)
    for c in cases {
        fwd := AnchoredRect(0, 0, pw, ph, c, 40, 40)
        back := AnchorFromRect(0, 0, pw, ph, fwd, c, 40, 40)
        if (back.ax != c.ax || back.ay != c.ay || back.w != c.w || back.h != c.h)
            drift += 1
    }
}
AssertEqual(drift, 0, "anchor survives percent -> pixels -> percent at every picture size")

; A rectangle that is EXACTLY what prev describes returns prev untouched. This is what makes
; the round trip stable, and it is also what stops a drag on one axis rewriting the other.
p0 := { ax: 50, ay: 50, w: 0, h: 0 }
f0 := AnchoredRect(0, 0, 300, 161, p0, 120, 89)
b0 := AnchorFromRect(0, 0, 300, 161, f0, p0, 120, 89)
AssertEqual(b0.w, 0, "a keep-current-size position stays keep-size when nothing moved")
AssertEqual(b0.h, 0, "keep-size survives on the other axis too")
AssertEqual(b0.ax, 50, "an unmoved anchor is returned unchanged")

; Moving it for real DOES convert keep-size into a concrete size -- the user just chose one.
b1 := AnchorFromRect(0, 0, 300, 161, { x: 0, y: 0, w: 150, h: 161 }, p0, 120, 89)
AssertEqual(b1.w, 50, "a real resize writes a concrete width")
AssertEqual(b1.h, 100, "a real resize writes a concrete height")

; No slack means no anchor to read: a full-width box could be at any anchor, so the previous
; one is kept rather than being reset to zero by a division that cannot be done.
b2 := AnchorFromRect(0, 0, 300, 161, { x: 0, y: 0, w: 300, h: 80 }, { ax: 70, ay: 20, w: 100, h: 50 }, 40, 40)
AssertEqual(b2.ax, 70, "a full-width box keeps the anchor it had")

; The COMPUTE path, with prev deliberately unrelated so the stability guard cannot fire. Without
; this the drift test above would be satisfied by the guard alone and the arithmetic would go
; untested.
b3 := AnchorFromRect(0, 0, 300, 160, { x: 75, y: 0, w: 150, h: 160 }
                   , { ax: 0, ay: 0, w: 10, h: 10 }, 40, 40)
AssertEqual(b3.ax, 50, "computed anchor: half the slack is a 50 anchor")
AssertEqual(b3.w,  50, "computed width is a percentage of the work area")
AssertEqual(b3.h, 100, "computed height is a percentage of the work area")

; --- Snapping --------------------------------------------------------------------------------
; Position and size do not share a grid. Position wants to LAND on the few placements anyone
; means; size is a continuum whose useful values are not evenly spaced.
AssertEqual(SnapAnchorPct(51, 2), 52, "an anchor snaps to its grid")
AssertEqual(SnapAnchorPct(50.9, 2), 50, "an anchor snaps down as readily as up")
AssertEqual(SnapAnchorPct(-8, 2), 0, "an anchor below the range clamps to flush")
AssertEqual(SnapAnchorPct(140, 2), 100, "an anchor above the range clamps to flush")
AssertEqual(SnapAnchorPct(37, 0), 37, "a zero step means no grid at all")

; Size: a 1% grid with magnets at the fractions people actually ask for. The magnet must beat
; the RAW value, not the rounded one -- compared against a 1% grid, rounding is always within
; half a percent and a magnet up to the radius away could never win, so the pull did nothing.
MAG := [25, 33, 50, 67, 75, 100]
AssertEqual(SnapSizePct(48, 1, MAG, 2), 50, "a size inside the pull radius takes the magnet")
AssertEqual(SnapSizePct(52, 1, MAG, 2), 50, "the magnet pulls from above as well")
AssertEqual(SnapSizePct(44, 1, MAG, 2), 44, "a size outside the pull radius keeps its own value")
AssertEqual(SnapSizePct(34, 1, MAG, 2), 33, "a third is reachable, which no uniform grid gives")
AssertEqual(SnapSizePct(47, 5, MAG, 2), 45, "a coarse grid ignores magnets entirely")
AssertEqual(SnapSizePct(48.4, 1, [], 2), 48, "with no magnets it is just the grid")

; ⭐ The magnet must be measured against the RAW percentage, not the rounded one. 47.6 is 2.4
; away from the 50 magnet and must NOT take it, but Round(47.6) is 48, which is 2 away and
; would. A mutation that rounded first survived every integer case above — which is the whole
; reason this assertion exists.
AssertEqual(SnapSizePct(47.6, 1, MAG, 2), 48, "a magnet is measured from the raw value, not the rounded one")

ReportAndExit()
