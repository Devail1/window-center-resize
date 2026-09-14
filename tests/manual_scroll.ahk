#Requires AutoHotkey v2.0
#Include "_harness.ahk"
#Include "..\src\gui\SettingsWindow.ahk"

; The window sizes itself to its content, and the content grows with the positions list: 695px for
; one position, +26px per row after that, so the 8-position cap wants 877px. That fits a 1080p work
; area and does NOT fit a 768px laptop - and the window has no sizing border to drag, so a window
; taller than the screen would be a dead end with no way to reach Save.
;
; It is clamped to the work area now, and scrolls only when clamped. No screen here is short enough
; to produce that naturally, so SETTINGS_MAX_HEIGHT forces it.
;
; MANUAL, not CI: needs a desktop. Does not touch the keyboard or any other window.
;
;   AutoHotkey64.exe tests\manual_scroll.ahk

ini := A_ScriptDir "\_scroll.ini"
try FileDelete(ini)

; Read through GetScrollInfo, so the scrollbar is checked the way Windows sees it rather than from
; a variable this test would be marking its own homework with.
_ScrollRange(hwnd) {
    static SB_VERT := 1, SIF_ALL := 0x17
    si := Buffer(28, 0)
    NumPut("uint", 28, si, 0)
    NumPut("uint", SIF_ALL, si, 4)
    if !DllCall("GetScrollInfo", "ptr", hwnd, "int", SB_VERT, "ptr", si)
        return -1
    return NumGet(si, 12, "int")             ; nMax
}

; The picture's slot is an ordinary child of the window, so its screen position is a direct
; readout of how far the content has scrolled.
_SlotY() {
    WinGetPos(, &y, , , "ahk_id " _spSlot.Hwnd)
    return y
}

; --- VACUITY GUARD FIRST: a window that fits must not scroll ------------------------------------
; Checked before the clamped case on purpose. A clamp that fired on every screen would satisfy
; every assertion further down while putting a scrollbar on a window that fits, and that is the
; regression most worth catching.
SETTINGS_MAX_HEIGHT := 0
ShowSettingsWindow(ini, (s) => 0)
Sleep(400)
hwnd := _settingsGui.Hwnd
WinGetPos(, , , &natural, "ahk_id " hwnd)

AssertEqual(_ScrollRange(hwnd), 0, "a window that fits has no scroll range at all")
restY := _SlotY()
PostMessage(0x0115, 3, 0, , "ahk_id " hwnd)                   ; WM_VSCROLL, SB_PAGEDOWN
Sleep(350)
AssertEqual(_SlotY(), restY, "VACUITY GUARD: a window that fits does not scroll")

; --- clamped: the content is taller than the window is allowed to be ----------------------------
SETTINGS_MAX_HEIGHT := 420
_settingsShowFitted()
Sleep(400)

WinGetPos(, , , &clamped, "ahk_id " hwnd)
AssertEqual(clamped < natural, true
          , "the clamp made the window shorter (" natural " -> " clamped ")")
AssertEqual(clamped <= 420 + 40, true, "the window is clamped to the allowed height (" clamped ")")
range := _ScrollRange(hwnd)
AssertEqual(range > 0, true, "the scrollbar covers the overflow (nMax " range ")")

; THE ONE THAT MATTERS. Without this the clamp has merely hidden the bottom of the window and put
; a decorative scrollbar next to it - Save would be unreachable, which is the whole problem.
before := _SlotY()
PostMessage(0x0115, 3, 0, , "ahk_id " hwnd)                   ; SB_PAGEDOWN
Sleep(400)
after := _SlotY()
AssertEqual(after < before, true
          , "scrolling down moved the content up (" before " -> " after ")")

; And it must come back, or the top becomes the unreachable part instead.
PostMessage(0x0115, 2, 0, , "ahk_id " hwnd)                   ; SB_PAGEUP
Sleep(400)
AssertEqual(_SlotY(), before, "scrolling back up restores the original position")

; Returning to a normal screen height must put the window back and take the scrollbar away.
SETTINGS_MAX_HEIGHT := 0
_settingsShowFitted()
Sleep(400)
WinGetPos(, , , &restored, "ahk_id " hwnd)
AssertEqual(restored, natural, "clearing the clamp restores the natural height")
AssertEqual(_ScrollRange(hwnd), 0, "clearing the clamp removes the scroll range")

try FileDelete(ini)
try _spGui.Destroy()
Sleep(200)
ReportAndExit()
