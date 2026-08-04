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

ApplyRectToActiveWindow(widthPct, heightPct) {
    hwnd := WinExist("A")
    if !hwnd
        return "no-window"
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

CenterActiveWindow() {
    hwnd := WinExist("A")
    if !hwnd
        return "no-window"
    ; WinGetPos throws TargetError if the window has closed since WinExist — same trigger
    ; as _MoveTo's bare catch, so guard it the same way.
    try {
        WinGetPos(&x, &y, &w, &h, hwnd)
    } catch {
        return "error"
    }
    wa := GetNearestMonitorWorkArea(hwnd)
    r := { x: wa.left + Round((wa.width  - w) / 2)
         , y: wa.top  + Round((wa.height - h) / 2)
         , w: w, h: h }
    return _MoveTo(hwnd, r)
}
