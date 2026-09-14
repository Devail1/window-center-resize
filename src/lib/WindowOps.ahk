#Requires AutoHotkey v2.0
#Include "Geometry.ahk"
#Include "Monitors.ahk"

; Issue #12: a non-elevated process cannot move a window owned by an elevated
; process. WinMove throws OSError 5 (Access denied). We detect that specific case
; and report it, rather than surfacing a raw error dialog.
_MoveTo(hwnd, r) {
    try {
        WinMove(r.x, r.y, r.w, r.h, hwnd)
        return "ok"
    } catch OSError as e {
        return (e.Number = 5) ? "elevated" : "error"
    } catch {
        ; OSError and TargetError are SIBLINGS in AHK v2 — both direct subclasses of Error —
        ; so `catch OSError` does NOT catch the TargetError WinMove throws when the target
        ; window has gone away. That happens whenever a hotkey is pressed as the active
        ; window is closing, which is the most likely failure of all.
        return "error"
    }
}

; ⛔ The hotkeys act on whatever is ACTIVE, and this app's own settings window is a window like
; any other - so pressing the resize key while it has focus made the app resize its own settings
; screen. Measured: a 1920x1032 work area and preset 1 gave a 960x516 settings window with its
; controls cut off at the bottom. Worse than untidy, it is a DEAD END: that window deliberately
; has no sizing border, so there is no way to drag it back; it stays wrong until reopened.
;
; Compared by PROCESS rather than against the settings Gui's handle, so this file keeps knowing
; nothing about the GUI layer, and message boxes and any future window are covered by the same
; guard.
_IsOwnWindow(hwnd) {
    pid := 0
    DllCall("GetWindowThreadProcessId", "ptr", hwnd, "uint*", &pid)
    return pid = DllCall("GetCurrentProcessId", "uint")
}

ApplyRectToActiveWindow(widthPct, heightPct) {
    hwnd := WinExist("A")
    if !hwnd
        return "no-window"
    if _IsOwnWindow(hwnd)
        return "own-window"
    wa := GetNearestMonitorWorkArea(hwnd)
    r  := CenteredRect(wa.left, wa.top, wa.width, wa.height, widthPct, heightPct)
    status := _MoveTo(hwnd, r)
    if (status != "ok")
        return status
    ; A window that enforces a MINIMUM SIZE keeps the requested top-left and clamps w/h
    ; upward, so the centre computed for the REQUESTED size leaves it visibly off-centre
    ; (e.g. a 25% preset on 1920px = 480px applied to Chrome, whose minimum is ~500px).
    ; Re-measure what was actually achieved and correct once. No loop.
    try {
        WinGetPos(, , &aw, &ah, hwnd)
    } catch {
        return "ok"        ; the window did move; it may simply have gone away since
    }
    if (aw != r.w || ah != r.h) {
        c := { x: wa.left + Round((wa.width  - aw) / 2)
             , y: wa.top  + Round((wa.height - ah) / 2)
             , w: aw, h: ah }
        _MoveTo(hwnd, c)   ; if the corrective move fails, the window still moved
    }
    return "ok"
}

; Applies a named position. This REPLACES CenterActiveWindow rather than sitting beside it:
; centring is the position { ax: 50, ay: 50, w: 0, h: 0 }, so keeping a separate function
; would be two implementations of one operation, and only one of them would get fixed.
ApplyPositionToActiveWindow(pos) {
    hwnd := WinExist("A")
    if !hwnd
        return "no-window"
    if _IsOwnWindow(hwnd)                  ; see _IsOwnWindow
        return "own-window"
    ; The window's current size is needed BEFORE the move: a zero width or height in the
    ; position means "keep what it has", and after the move it is too late to ask.
    try {
        WinGetPos(, , &cw, &ch, hwnd)
    } catch {
        return "error"
    }
    wa := GetNearestMonitorWorkArea(hwnd)
    r  := AnchoredRect(wa.left, wa.top, wa.width, wa.height, pos, cw, ch)
    status := _MoveTo(hwnd, r)
    if (status != "ok")
        return status
    ; Same minimum-size correction ApplyRectToActiveWindow does, and the reason it cannot be
    ; copied from there: that one re-CENTRES. A window that clamps its width upward — Chrome
    ; below ~500px — would land in the middle of the screen after asking for the left edge,
    ; on exactly the apps most likely to clamp. Re-anchor instead, at the achieved size, using
    ; the position's own anchor.
    try {
        WinGetPos(, , &aw, &ah, hwnd)
    } catch {
        return "ok"        ; the window did move; it may simply have gone away since
    }
    if (aw != r.w || ah != r.h) {
        c := AnchoredRect(wa.left, wa.top, wa.width, wa.height
                        , { ax: pos.ax, ay: pos.ay, w: 0, h: 0 }, aw, ah)
        _MoveTo(hwnd, c)   ; if the corrective move fails, the window still moved
    }
    return "ok"
}
