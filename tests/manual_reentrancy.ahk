#Requires AutoHotkey v2.0
#Include "_harness.ahk"
#Include "..\src\gui\SettingsWindow.ahk"

; Regression test for the two defects found on 2026-09-13. The headless suite is structurally
; blind to both: they are about WINDOW IDENTITY and Z-ORDER, and nothing a unit test can call
; knows about either.
;
; 1. ShowSettingsWindow was RE-ENTRANT. Building the window yields to the message queue
;    (_spBox.Show() pumps WM_SIZE into _SpFitFill; _Reflow moves controls), and the tray icon's
;    default item fires on a DOUBLE-CLICK - so a second activation arrived mid-construction, got
;    past the single-instance check (not satisfied until the very end of the build) and created a
;    SECOND window. The two then shared ScreenPicture's module-level globals, the second build
;    overwrote them, and the first window's picture was never laid out: a blank rectangle with no
;    box. Measured before the fix: two "first" branch entries and two live windows, every time.
;
; 2. The centre dot and the eight handles are created AFTER _spFill, so reverse z-order put them
;    BEHIND it. The dot sits dead centre, entirely inside the fill, so it disappeared on the next
;    repaint - while WinShow went on reporting it visible.
;
; MANUAL, not CI: needs a desktop to put a real window on. It does NOT touch the keyboard or the
; tray, so it is safe to run while working - unlike manual_e2e_portable.ahk.
;
;   AutoHotkey64.exe tests\manual_reentrancy.ahk
;
; ⛔ The second activation is fired from a TIMER rather than a synthetic tray click. Posting
; AHK_NOTIFYICON by hand proved unreliable in both directions - it opened nothing on some runs and
; needed two or three posts on others - so a test built on it would report the harness, not the
; app. A timer fires while the construction is pumping messages, which is precisely the window
; the real double-click lands in.

ini := A_ScriptDir "\_reentrancy.ini"
try FileDelete(ini)

global g_firstReturned := false
global g_secondRan := false
global g_reentered := false

_SecondActivation() {
    global g_firstReturned, g_secondRan, g_reentered
    g_secondRan := true
    ; If the first call has not returned yet, this one is genuinely RE-ENTRANT - which is the
    ; only condition under which this test means anything. Recorded rather than assumed: a timer
    ; that fired too late would make every assertion below pass vacuously.
    g_reentered := !g_firstReturned
    ShowSettingsWindow(ini, (s) => 0)
}

SetTimer(_SecondActivation, -50)
ShowSettingsWindow(ini, (s) => 0)
g_firstReturned := true
Sleep(1500)

AssertEqual(g_secondRan, true, "the second activation ran at all")
AssertEqual(g_reentered, true
          , "VACUITY GUARD: the second activation arrived DURING construction")

; THE ONE THAT MATTERS. Two windows is the bug, and two windows is what the user sees.
DetectHiddenWindows(false)
AssertEqual(WinGetList(APP_TITLE).Length, 1
          , "a second activation during construction opens exactly ONE settings window")

; The picture's three layers are DECLARED at the slot's full rect and moved into their
; letterboxed places by ScreenPictureRelayout. All three still equal means the relayout never ran
; for the window that survived - the blank-picture signature.
WinGetPos(, , &sw, &sh, "ahk_id " _spSlot.Hwnd)
WinGetPos(, , &pw, &ph, "ahk_id " _spPic.Hwnd)
WinGetPos(, , &tw, &th, "ahk_id " _spTask.Hwnd)
AssertEqual(pw = sw && ph = sh, false
          , "the picture was laid out (pic " pw "x" ph " is not the slot's " sw "x" sh ")")
AssertEqual(tw = sw && th = sh, false
          , "the taskbar strip was laid out (task " tw "x" th " is not the slot's " sw "x" sh ")")

; The globals must describe the window that is actually on screen. When two builds raced, they
; described the one that had been thrown away.
AssertEqual(WinExist("ahk_id " _spGui.Hwnd) > 0, true
          , "the ScreenPicture globals point at a window that still exists")
AssertEqual(DllCall("GetParent", "ptr", _spBox.Hwnd, "ptr"), _spGui.Hwnd
          , "the box belongs to the surviving settings window")

; Z-order inside the box. FindWindowEx returns children in z-order, so the first match is the
; front-most: it must not be the fill, or the dot and the handles are buried under it.
front := DllCall("FindWindowEx", "ptr", _spBox.Hwnd, "ptr", 0, "str", "msctls_progress32"
               , "ptr", 0, "ptr")
AssertEqual(front, _spDot.Hwnd
          , "the centre dot is the front-most child of the box, not hidden behind the fill")

try FileDelete(ini)

; ⛔ Tear the window down BEFORE exiting. ExitApp destroys the box Gui after the script's globals
; have been released, so _SpNcCalcSize and _SpSize fire with _spBox unassigned and throw - which
; the harness reports as a failed run on an otherwise green test. Destroying here runs the same
; handlers while the globals are still alive, where they no-op correctly.
try _spGui.Destroy()
Sleep(200)
ReportAndExit()
