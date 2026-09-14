#Requires AutoHotkey v2.0
#Include "_harness.ahk"
#Include "..\src\gui\SettingsWindow.ahk"
#Include "..\src\lib\WindowOps.ahk"

; The settings window is resizable, and the app is allowed to resize it like any other window -
; we are a window resizer, so our own window should not be the exception. That only holds if the
; window SURVIVES an arbitrary size, which is what this checks.
;
; It used to not survive. Pressing F9 with the settings window focused resized it to 50%x50% of
; the work area - 960x516 on a 1920x1032 screen - and the controls were simply cut off, with no
; sizing border to drag back by and nothing scrolling. That was fixed twice over: the window now
; reflows its controls to the new width, gives spare height to the picture, and scrolls whatever
; still does not fit.
;
; AutoHotkey gives you the sizing border for one option (+Resize) and nothing else: no control
; moves or stretches by itself, because there is no layout manager. Everything below is the Size
; handler's work.
;
; MANUAL, not CI: needs a desktop. Does not touch the keyboard.
;
;   AutoHotkey64.exe tests\manual_resize.ahk

ini := A_ScriptDir "\_resize.ini"
try FileDelete(ini)

_Slot() {
    WinGetPos(, , &w, &h, "ahk_id " _spSlot.Hwnd)
    return { w: w, h: h }
}
_Pic() {
    WinGetPos(&x, &y, &w, &h, "ahk_id " _spPic.Hwnd)
    return { x: x, y: y, w: w, h: h }
}
; The box must stay inside the picture at every size, or the drag is aiming at something that is
; no longer where it is drawn.
_BoxInsidePicture() {
    p := _Pic()
    WinGetPos(&bx, &by, &bw, &bh, "ahk_id " _spBox.Hwnd)
    return (bx >= p.x - 1 && by >= p.y - 1 && bx + bw <= p.x + p.w + 1 && by + bh <= p.y + p.h + 1)
}

ShowSettingsWindow(ini, (s) => 0)
if !WinWaitActive("ahk_id " _settingsGui.Hwnd, , 5) {
    FileAppend("ABORT: the settings window never became active, so 'the active window' below"
             . "`n       would be something else. Rerun with the desktop idle.`n", "*")
    ExitApp(1)
}
ScreenPictureSet({ ax: 50, ay: 50, w: 50, h: 50 }, true)
Sleep(400)

hwnd := _settingsGui.Hwnd
style := DllCall("GetWindowLongPtr", "ptr", hwnd, "int", -16, "ptr")
AssertEqual(!!(style & 0x00040000), true, "the settings window has a sizing border (+Resize)")

WinGetPos(, , &w0, &h0, "ahk_id " hwnd)
natural := _Slot()

; --- the app resizing its OWN window, which is what F9 does --------------------------------
; This returned "own-window" and did nothing while the guard existed. It is allowed now, and the
; assertions after it are what earn that.
AssertEqual(ApplyRectToActiveWindow(50, 50), "ok"
          , "the app is allowed to resize its own settings window")
Sleep(600)
WinGetPos(, , &w1, &h1, "ahk_id " hwnd)
AssertEqual(w1 != w0 || h1 != h0, true, "the window actually changed size (" w0 "x" h0 " -> " w1 "x" h1 ")")

; THE ONE THAT MATTERS. Resizing is only safe if the layout follows; otherwise this is the old
; bug with a nicer story. The slot tracks the client width minus both margins.
WinGetClientPos(, , &cw, &ch, hwnd)
AssertEqual(_Slot().w, cw - 32
          , "the layout reflowed to the new width (slot " _Slot().w ", client " cw ")")
AssertEqual(_BoxInsidePicture(), true, "the box is still inside the picture after the resize")

; Nothing may become unreachable: either it all fits, or the scrollbar covers the difference.
si := Buffer(28, 0)
NumPut("uint", 28, si, 0), NumPut("uint", 0x17, si, 4)
DllCall("GetScrollInfo", "ptr", hwnd, "int", 1, "ptr", si)
range := NumGet(si, 12, "int")
btnSaveBottom := 0
for hwnd2, c in _settingsGui {
    c.GetPos(, &cy, , &chh)
    if (cy + chh > btnSaveBottom)
        btnSaveBottom := cy + chh
}
AssertEqual(btnSaveBottom <= ch || range > 0, true
          , "content either fits or is scrollable (bottom " btnSaveBottom ", client " ch
          . ", range " range ")")

; --- a deliberately awkward set of sizes ----------------------------------------------------
for size in [[1200, 400], [360, 900], [700, 1000]] {
    WinMove(60, 60, size[1], size[2], "ahk_id " hwnd)
    Sleep(500)
    WinGetClientPos(, , &cw2, &ch2, hwnd)
    AssertEqual(_Slot().w, cw2 - 32
              , "reflow holds at " size[1] "x" size[2] " (slot " _Slot().w ", client " cw2 ")")
    AssertEqual(_BoxInsidePicture(), true, "box stays inside the picture at " size[1] "x" size[2])
}

; Spare HEIGHT goes to the picture - that is the point of making it resizable at all. Width alone
; cannot: the picture is letterboxed at the monitor's aspect ratio, so a wider slot with the same
; height has nothing to grow into.
WinMove(60, 60, 700, 1000, "ahk_id " hwnd)
Sleep(500)
AssertEqual(_Pic().h > natural.h, true
          , "a taller window makes the picture bigger (" natural.h " -> " _Pic().h ")")

; And back down, without anything being left stranded off the bottom.
WinMove(60, 60, 348, 420, "ahk_id " hwnd)
Sleep(500)
WinGetClientPos(, , , &ch3, hwnd)
DllCall("GetScrollInfo", "ptr", hwnd, "int", 1, "ptr", si)
AssertEqual(NumGet(si, 12, "int") > 0, true
          , "a window shorter than its content gets a scroll range")
AssertEqual(_BoxInsidePicture(), true, "box stays inside the picture when shrunk")

got := ScreenPictureGet()
AssertEqual(got.ax "," got.ay "," got.w "," got.h, "50,50,50,50"
          , "the position model survived the whole resize cycle untouched")

try FileDelete(ini)
try _spGui.Destroy()
Sleep(200)
ReportAndExit()
