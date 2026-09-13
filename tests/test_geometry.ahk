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

ReportAndExit()
