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
    }
}

ApplyRectToActiveWindow(widthPct, heightPct) {
    hwnd := WinExist("A")
    if !hwnd
        return "no-window"
    wa := GetNearestMonitorWorkArea(hwnd)
    r  := CenteredRect(wa.left, wa.top, wa.width, wa.height, widthPct, heightPct)
    return _MoveTo(hwnd, r)
}

CenterActiveWindow() {
    hwnd := WinExist("A")
    if !hwnd
        return "no-window"
    WinGetPos(&x, &y, &w, &h, hwnd)
    wa := GetNearestMonitorWorkArea(hwnd)
    r := { x: wa.left + Round((wa.width  - w) / 2)
         , y: wa.top  + Round((wa.height - h) / 2)
         , w: w, h: h }
    return _MoveTo(hwnd, r)
}
