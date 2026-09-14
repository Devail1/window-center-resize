#Requires AutoHotkey v2.0
#Include "_harness.ahk"
#Include "..\src\lib\WindowOps.ahk"

; The hotkeys act on whatever window is ACTIVE, and this app's own settings window is a window
; like any other - so pressing the resize key while it had focus made the app resize its OWN
; settings screen. Reported from the field 2026-09-14: a 1920x1032 work area and preset 1 left a
; 960x516 settings window with its controls cut off, and no way back, because that window has no
; sizing border to drag.
;
; MANUAL, not CI: needs a desktop with a real active window. It creates its own throwaway window
; and never touches anyone else's, and it does not drive the keyboard.
;
;   AutoHotkey64.exe tests\manual_ownwindow.ahk

; A window belonging to THIS process - which is what the app's settings window is to the app.
g := Gui("+Resize", "WCR OWN WINDOW TEST")
g.Add("Text", , "own-window guard test")
g.Show("x40 y40 w520 h360")
if !WinWaitActive("WCR OWN WINDOW TEST", , 5) {
    FileAppend("ABORT: the test window never became active, so 'the active window' below would"
             . "`n       be something else entirely. Rerun with the desktop idle.`n", "*")
    ExitApp(1)
}
WinGetPos(&bx, &by, &bw, &bh, g.Hwnd)

; Both entry points must refuse, and must refuse by NAME - a plain "error" would be reported to
; the user as a failure, which this is not.
AssertEqual(ApplyRectToActiveWindow(50, 50), "own-window"
          , "the resize cycle refuses this app's own window")
AssertEqual(ApplyPositionToActiveWindow({ ax: 0, ay: 50, w: 50, h: 100 }), "own-window"
          , "a named position refuses this app's own window")

; THE ONE THAT MATTERS: refusing has to mean the window was not touched. A guard that returns the
; right string after having already moved the window would read as a pass here and still ruin the
; settings screen.
WinGetPos(&ax, &ay, &aw, &ah, g.Hwnd)
AssertEqual(ax "," ay "," aw "," ah, bx "," by "," bw "," bh
          , "the refused window was not moved or resized at all")

; VACUITY GUARD. If _IsOwnWindow matched everything, every assertion above would pass while the
; feature was dead. A window belonging to ANOTHER process must not be seen as our own.
;
; An EXISTING foreign window is used rather than launching one: starting Notepad turned out not
; to be dependable (it is a Store app on this machine and never appeared), and a skipped vacuity
; guard is the failure mode this guard exists to prevent. The desktop always has windows.
me := DllCall("GetCurrentProcessId", "uint")
other := 0
for h in WinGetList() {
    pid := 0
    DllCall("GetWindowThreadProcessId", "ptr", h, "uint*", &pid)
    if (pid != me) {
        other := h
        break
    }
}
AssertEqual(other > 0, true, "found a window owned by another process to test against")
if (other)
    AssertEqual(_IsOwnWindow(other), false
              , "VACUITY GUARD: another process's window is NOT treated as our own")

AssertEqual(_IsOwnWindow(g.Hwnd), true, "our own window IS recognised as ours")

g.Destroy()
ReportAndExit()
