#Requires AutoHotkey v2.0

; Returns the WORK AREA (taskbar excluded) of the monitor nearest the given window.
GetNearestMonitorWorkArea(hwnd) {
    static MONITOR_DEFAULTTONEAREST := 0x00000002
    hMon := DllCall("MonitorFromWindow", "ptr", hwnd, "uint", MONITOR_DEFAULTTONEAREST, "ptr")
    mi := Buffer(104, 0)
    NumPut("uint", 104, mi)
    if !DllCall("user32\GetMonitorInfo", "ptr", hMon, "ptr", mi)
        return { left: 0, top: 0, width: A_ScreenWidth, height: A_ScreenHeight }
    ; MONITORINFOEX: rcMonitor at offset 4 (16 bytes), rcWork at offset 20 (16 bytes).
    wl := NumGet(mi, 20, "int"), wt := NumGet(mi, 24, "int")
    wr := NumGet(mi, 28, "int"), wb := NumGet(mi, 32, "int")
    return { left: wl, top: wt, width: wr - wl, height: wb - wt }
}
