; tests/manual_editor_spike_drive.ahk
;
; THROWAWAY, and the companion to manual_editor_spike.ahk — delete both together.
;
; It drives the spike with SYNTHETIC MOUSE INPUT so the drag questions can be answered without
; a human at the keyboard. Start the spike first, then run this against it:
;
;   AHK=/mnt/c/Users/97254/AppData/Local/Programs/AutoHotkey/v2/AutoHotkey64.exe
;   timeout 140 "$AHK" /ErrorStdOut 'C:\dev\window-center-resize\tests\manual_editor_spike.ahk' &
;   sleep 3
;   timeout 110 "$AHK" /ErrorStdOut 'C:\dev\window-center-resize\tests\manual_editor_spike_drive.ahk'
;
; ⛔ Two traps, both measured here, both of which make a WORKING mechanism look broken:
;
;   1. ControlClick does NOT fire these Gui buttons. It reports success and nothing happens.
;      Every button press below goes through the real cursor instead — see ClickButton().
;   2. The child Gui is a CHILD window, so it is not in WinGetList and cannot be reached by
;      WinTitle. It is found with FindWindowEx under the parent.
;
; The drag endpoints are NOT exact: the modal move loop anchors on wherever the cursor is when
; it starts, and with posted input that is a few steps in. Read the SNAP (is the result on the
; 5% grid?), not the absolute pixel.

#Requires AutoHotkey v2.0
CoordMode "Mouse", "Screen"
SetWinDelay 50
out := ""
Say(s) {
    global out
    out .= s "`n"
}

if !WinWait("Editor drag spike", , 10) {
    FileAppend("spike window never appeared`n", "*")
    ExitApp
}
g := WinGetID("Editor drag spike")
WinActivate(g)
Sleep 500

; the draggable child Gui is a child window, so it is not in WinGetList
box := DllCall("FindWindowEx", "ptr", g, "ptr", 0, "str", "AutoHotkeyGUI", "ptr", 0, "ptr")
if (!box) {
    FileAppend("child BOX gui not found under parent`n", "*")
    ExitApp
}
; ControlClick does NOT fire these buttons — measured. A real synthetic click does, so every
; button press below goes through the actual cursor.
ClickButton(g, ctrl) {
    ControlGetPos(&bx, &by, &bw, &bh, ctrl, "ahk_id " g)
    pt := Buffer(8, 0)
    NumPut("int", bx, pt, 0), NumPut("int", by, pt, 4)
    DllCall("ClientToScreen", "ptr", g, "ptr", pt)
    MouseMove NumGet(pt, 0, "int") + bw // 2, NumGet(pt, 4, "int") + bh // 2, 0
    Sleep 150
    Click
    Sleep 500
}

BoxRect() {
    global box
    WinGetPos(&x, &y, &w, &h, "ahk_id " box)
    return { x: x, y: y, w: w, h: h }
}
Fmt(r) => r.w "x" r.h " @" r.x "," r.y

r0 := BoxRect()
Say("BOX found. start " Fmt(r0))

; --- Q1a: does the HTCAPTION move loop actually move it? ------------------------------
cx := r0.x + r0.w // 2, cy := r0.y + r0.h // 2
MouseMove cx, cy, 0
Sleep 200
Click "down"
Sleep 200
loop 12 {                       ; move in steps so the modal loop sees WM_MOUSEMOVE
    MouseMove cx + A_Index * 6, cy + A_Index * 2, 0
    Sleep 25
}
Sleep 200
Click "up"
Sleep 400
r1 := BoxRect()
Say("Q1a drag(+72,+24) -> " Fmt(r1) "   moved " (r1.x - r0.x) "," (r1.y - r0.y)
  . (r1.x = r0.x && r1.y = r0.y ? "   *** DID NOT MOVE ***" : "   OK"))
Say("     live: " ControlGetText("Static4", "ahk_id " g))

; --- Q1b: is the invisible sizing border grabbable (mode A, system frame)? ------------
r := BoxRect()
ex := r.x + r.w - 2, ey := r.y + r.h // 2        ; 2px inside the right edge
MouseMove ex, ey, 0
Sleep 200
Click "down"
Sleep 200
loop 12 {
    MouseMove ex + A_Index * 5, ey, 0
    Sleep 25
}
Sleep 200
Click "up"
Sleep 400
r2 := BoxRect()
Say("Q1b right-edge drag(+60) -> " Fmt(r2) "   width " r.w " -> " r2.w
  . (r2.w = r.w ? "   *** NOT RESIZABLE at 2px inset ***" : "   OK"))

; --- Q2 / Q3 in mode A ---------------------------------------------------------------
ClickButton(g, "Button6")
Sleep 700
Say("")
Say("---- report, MODE A ----")
Say(ControlGetText("Edit1", "ahk_id " g))

; --- flip to mode B and repeat the two drags -----------------------------------------
ClickButton(g, "Button5")
Sleep 500
r := BoxRect()
cx := r.x + r.w // 2, cy := r.y + r.h // 2
MouseMove cx, cy, 0
Sleep 200
Click "down"
Sleep 200
loop 12 {
    MouseMove cx - A_Index * 6, cy + A_Index * 2, 0
    Sleep 25
}
Sleep 200
Click "up"
Sleep 400
r3 := BoxRect()
Say("")
Say("Q1c mode B drag(-72,+24) -> " Fmt(r3) "   moved " (r3.x - r.x) "," (r3.y - r.y)
  . (r3.x = r.x && r3.y = r.y ? "   *** DID NOT MOVE ***" : "   OK"))

r := BoxRect()
ex := r.x + r.w - 3, ey := r.y + r.h // 2
MouseMove ex, ey, 0
Sleep 200
Click "down"
Sleep 200
loop 12 {
    MouseMove ex - A_Index * 5, ey, 0
    Sleep 25
}
Sleep 200
Click "up"
Sleep 400
r4 := BoxRect()
Say("Q1d mode B right-edge drag(-60) -> " Fmt(r4) "   width " r.w " -> " r4.w
  . (r4.w = r.w ? "   *** NOT RESIZABLE ***" : "   OK"))

ClickButton(g, "Button6")
Sleep 700
Say("")
Say("---- report, after MODE B ----")
Say(ControlGetText("Edit1", "ahk_id " g))

FileAppend(out, "*")
