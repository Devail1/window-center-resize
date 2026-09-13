#Requires AutoHotkey v2.0

; Returns the WORK AREA (taskbar excluded) of the monitor nearest the given window.
GetNearestMonitorWorkArea(hwnd) {
    static MONITOR_DEFAULTTONEAREST := 0x00000002
    hMon := DllCall("MonitorFromWindow", "ptr", hwnd, "uint", MONITOR_DEFAULTTONEAREST, "ptr")
    mi := Buffer(104, 0)
    NumPut("uint", 104, mi)
    if !DllCall("user32\GetMonitorInfo", "ptr", hMon, "ptr", mi)
        return { left: 0, top: 0, width: A_ScreenWidth, height: A_ScreenHeight
               , monLeft: 0, monTop: 0, monWidth: A_ScreenWidth, monHeight: A_ScreenHeight }
    ; MONITORINFOEX: rcMonitor at offset 4 (16 bytes), rcWork at offset 20 (16 bytes).
    ml := NumGet(mi,  4, "int"), mt := NumGet(mi,  8, "int")
    mr := NumGet(mi, 12, "int"), mb := NumGet(mi, 16, "int")
    wl := NumGet(mi, 20, "int"), wt := NumGet(mi, 24, "int")
    wr := NumGet(mi, 28, "int"), wb := NumGet(mi, 32, "int")
    ; The FULL monitor comes back alongside the work area, additively, so nothing that only
    ; wanted the work area has to change. The editor needs both: it draws the whole screen, and
    ; the difference between the two is where the taskbar is.
    return { left: wl, top: wt, width: wr - wl, height: wb - wt
           , monLeft: ml, monTop: mt, monWidth: mr - ml, monHeight: mb - mt }
}
