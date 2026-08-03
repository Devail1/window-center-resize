#Requires AutoHotkey v2.0
#Include "..\tests\_harness.ahk"
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
AssertEqual(r2.x, 2240, "secondary monitor centers within its own bounds")

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

ReportAndExit()
