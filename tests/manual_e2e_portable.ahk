#Requires AutoHotkey v2.0
#Include "_harness.ahk"

; End-to-end check of the PORTABLE distribution - the thing users actually download - rather
; than of the functions it is built from. Launches dist\portable\WindowCenterResizer.exe,
; puts a real window on screen, presses the real global hotkeys, and measures where the
; window ended up.
;
; Why this exists: every other suite here tests src\ through direct function calls, which
; would stay green even if the distribution were unlaunchable. 2.2.0 changed how the app is
; packaged - a renamed stock interpreter finding its script by filename - and nothing in a
; unit test touches that mechanism. This does.
;
; MANUAL, not CI: it needs a desktop, a visible window and working global hotkeys. It also
; drives the real keyboard, so do not type while it runs.
;
;   AutoHotkey64.exe tests\manual_e2e_portable.ahk
;
; Deliberately does NOT reuse Geometry.ahk to decide what "centred" means. It measures the
; margins around the window that actually moved; reusing the app's own arithmetic would make
; the assertion agree with the app by construction.

root := A_ScriptDir "\.."
exe  := root "\dist\portable\WindowCenterResizer.exe"
ahk  := root "\dist\portable\WindowCenterResizer.ahk"

if (!FileExist(exe) || !FileExist(ahk)) {
    FileAppend("SKIP: no portable build at " root "\dist\portable"
             . "`n      run: powershell -ExecutionPolicy Bypass -File build\build-portable.ps1`n", "*")
    ExitApp(1)
}

; The whole point of the packaging: the shipped exe must be the stock interpreter untouched.
; If a future build starts patching an icon or a version resource into it, the app will still
; work perfectly and the download will start being deleted again - a failure no functional
; test can see. Compare against the interpreter running this script.
AssertEqual(FileGetSize(exe), FileGetSize(A_AhkPath)
          , "THE ONE THAT MATTERS: shipped exe is the same size as the stock interpreter")

; A stale instance would answer the hotkeys instead of the build under test, and the result
; would look like a pass.
try RunWait(A_ComSpec ' /c taskkill /IM WindowCenterResizer.exe /F', , "Hide")
Sleep(500)

Run(exe, , , &appPid)
Sleep(3000)
AssertEqual(ProcessExist(appPid) > 0, true, "the portable build is still running after launch")

MonitorGetWorkArea(MonitorGetPrimary(), &wl, &wt, &wr, &wb)
waW := wr - wl, waH := wb - wt

; Margins rather than coordinates, with 2px of tolerance for odd-pixel work areas and the
; Round() in CenterActiveWindow.
IsCentred(hwnd) {
    global wl, wt, wr, wb
    WinGetPos(&x, &y, &w, &h, hwnd)
    return (Abs((x - wl) - (wr - (x + w))) <= 2) && (Abs((y - wt) - (wb - (y + h))) <= 2)
}

MakeTarget(title) {
    g := Gui("+Resize", title)
    g.Add("Text", , "end-to-end target")
    g.Show("x20 y20 w600 h400")
    WinWaitActive(title, , 5)
    return g
}

; --- Centre -------------------------------------------------------------------------------
g := MakeTarget("WCR E2E CENTRE")
WinGetPos(&bx, &by, &bw, &bh, g.Hwnd)
Send("^+c")
Sleep(1500)
WinGetPos(&ax, &ay, &aw, &ah, g.Hwnd)

AssertEqual(ax != bx || ay != by, true, "Centre moved the window (the hotkey reached the app)")
AssertEqual(aw . "x" . ah, bw . "x" . bh, "Centre left the window's size alone")
AssertEqual(IsCentred(g.Hwnd), true, "Centre put the window in the middle of the work area")
g.Destroy()

; --- Resize -------------------------------------------------------------------------------
; Asserts each press lands on SOME configured preset rather than a specific one: SIZE_INDEX is
; per-instance state, so which preset comes first depends on what the instance has already
; done. Three presses must still visit three distinct presets.
g := MakeTarget("WCR E2E RESIZE")
presets := [50, 75, 90]
seen := Map()
loop 3 {
    Send("{F9}")
    Sleep(1200)
    WinGetPos(, , &w, &h, g.Hwnd)
    matched := 0
    for pct in presets {
        if (Abs(w - Floor(waW * pct / 100)) <= 2 && Abs(h - Floor(waH * pct / 100)) <= 2)
            matched := pct
    }
    AssertEqual(matched > 0, true, "F9 press " A_Index " produced a configured preset size (got " w "x" h ")")
    AssertEqual(IsCentred(g.Hwnd), true, "F9 press " A_Index " left the window centred")
    if (matched > 0)
        seen[matched] := true
}
AssertEqual(seen.Count, 3, "three F9 presses visited three distinct presets")
g.Destroy()

try ProcessClose(appPid)
ReportAndExit()
