#SingleInstance
#NoTrayIcon
#Include "%A_ScriptDir%\JXON.ahk"  ; Include the JSON library

Join(sep, params*) {
    str := ''
    for index, param in params
        str .= sep . param
    return SubStr(str, StrLen(sep) + 1)
}

hotkeysJsToHotHotkeys := Map("shift", "+", "ctrl", "^", "alt", "!", "meta", "#")

; Function to convert hotkeys-js keys to HotHotkeys syntax
convertHotkeysJsToHotHotkeys(key) {
    keys := StrSplit(key, "+")  ; Split key by "+"

    hotkeys := []
    for each, k in keys {
        k := StrLower(Trim(k))
        if (hotkeysJsToHotHotkeys.Has(k))
            hotkeys.push(hotkeysJsToHotHotkeys.Get(k))
        else
            hotkeys.push(StrUpper(k))
    }
    return Join("", hotkeys*)
}

jsonFilePath := A_AppData . "\window-center-resize\settings.json"

; Check if file exists
if !FileExist(jsonFilePath) {
    MsgBox("Settings file not found at: " jsonFilePath, "Error", "IconX")
    ExitApp
}

; Read JSON file
try {
    jsonContent := Fileread(jsonFilePath)
    if (jsonContent = "") {
        MsgBox("Settings file is empty: " jsonFilePath, "Error", "IconX")
        ExitApp
    }
} catch Error as err {
    MsgBox("Error reading settings file: " err.message, "Error", "IconX")
    ExitApp
}

; Parse JSON content
try {
    json := jxon_load(&jsonContent)
} catch Error as err {
    MsgBox("Error parsing JSON: " err.message "`n`nContent: " jsonContent, "Error", "IconX")
    ExitApp
}

; Validate required fields
if !json.Has("centerWindow") || !json.Has("resizeWindow") {
    MsgBox("Settings file is missing required fields", "Error", "IconX")
    ExitApp
}

centerWindowObj := json["centerWindow"]
resizeWindowObj := json["resizeWindow"]
global toggleSizes := resizeWindowObj["windowSizePercentages"]

; Extract values from JSON
centerWindowKey := convertHotkeysJsToHotHotkeys(centerWindowObj["keybinding"])
resizeWindowKey := convertHotkeysJsToHotHotkeys(resizeWindowObj["keybinding"])

; Define hotkeys if keybinding exists
if (centerWindowKey != "")
    Hotkey(centerWindowKey, CenterWindow, "On")
if (resizeWindowKey != "")
    Hotkey(resizeWindowKey, ResizeWindow, "On")

; Add this function before CenterWindow
HandleWindowError(err) {
    if InStr(err.Message, "Access is denied") {
        MsgBox("Unable to move window - Access denied. The target window may be running with elevated privileges.",
            "Access Denied", "IconX")
    } else if InStr(err.Message, "Window not found") {
        MsgBox("Unable to find the target window. It may have been closed.", "Window Not Found", "IconX")
    } else if InStr(err.Message, "Invalid window handle") {
        MsgBox("Invalid window handle. The window may have been closed or is not accessible.", "Invalid Window",
            "IconX")
    } else {
        MsgBox("An unexpected error occurred: " err.Message, "Error", "IconX")
    }
}

CenterWindow(WinTitle) {
    hwnd := WinExist("A")  ; Check if window exists

    if (hwnd) {
        mon := GetNearestMonitorInfo(hwnd)

        WinGetPos(&WinX, &WinY, &Width, &Height, hwnd)  ; Get current window position and size

        NewX := mon.WALeft + (mon.WAWidth - Width) / 2  ; Calculate centered X position on current monitor
        NewY := mon.WATop + (mon.WAHeight - Height) / 2  ; Calculate centered Y position on current monitor

        try {
            WinMove(NewX, NewY, Width, Height, hwnd)  ; Move window to the center
        } catch Error as err {
            HandleWindowError(err)
        }
    } else {
        ; MsgBox("Window not found.")
    }
}

ResizeWindow(WinTitle) {
    static size := 1
    global toggleSizes

    size++

    if (size > toggleSizes.Length)  ; Reset size to 1 if it exceeds array length
        size := 1

    hwnd := WinExist("A")  ; Get handle to active window

    if (hwnd) {
        preset := toggleSizes[size]
        ; Get x and y directly from the preset object
        xPos := preset.Has("x") ? preset["x"] : 50
        yPos := preset.Has("y") ? preset["y"] : 50
        CenterAndResizeWindow("A", preset["width"], preset["height"], xPos, yPos)
    }
}

CenterAndResizeWindow(WinTitle, WidthPercentage, HeightPercentage, XPercentage := 50, YPercentage := 50) {
    hwnd := WinExist(WinTitle)  ; Check if window exists

    if (hwnd) {
        mon := GetNearestMonitorInfo(hwnd)

        ; Calculate new dimensions
        NewWidth := (mon.WAWidth * WidthPercentage / 100)
        NewHeight := (mon.WAHeight * HeightPercentage / 100)

        ; Calculate position based on percentages - now treating them as relative positions from edges
        NewX := mon.WALeft + (mon.WAWidth - NewWidth) * (XPercentage / 100)
        NewY := mon.WATop + (mon.WAHeight - NewHeight) * (YPercentage / 100)

        ; Ensure window stays within screen bounds
        NewX := Max(mon.WALeft, Min(NewX, mon.WARight - NewWidth))
        NewY := Max(mon.WATop, Min(NewY, mon.WABottom - NewHeight))

        try {
            WinMove(NewX, NewY, NewWidth, NewHeight, hwnd)
        } catch Error as err {
            HandleWindowError(err)
        }
    }
}

GetNearestMonitorInfo(winTitle) {
    static MONITOR_DEFAULTTONEAREST := 0x00000002
    hwnd := WinExist(winTitle)
    hMonitor := DllCall("MonitorFromWindow", "ptr", hwnd, "uint", MONITOR_DEFAULTTONEAREST, "ptr")
    NumPut("uint", 104, MONITORINFOEX := Buffer(104))
    if (DllCall("user32\GetMonitorInfo", "ptr", hMonitor, "ptr", MONITORINFOEX)) {
        return { Handle: hMonitor, Name: Name := StrGet(MONITORINFOEX.ptr + 40, 32), Number: RegExReplace(Name,
            ".*(\d+)$", "$1"), Left: L := NumGet(MONITORINFOEX, 4, "int"), Top: T := NumGet(MONITORINFOEX, 8, "int"),
            Right: R := NumGet(MONITORINFOEX, 12, "int"), Bottom: B := NumGet(MONITORINFOEX, 16, "int"), WALeft: WL :=
                NumGet(MONITORINFOEX, 20, "int"), WATop: WT := NumGet(MONITORINFOEX, 24, "int"), WARight: WR := NumGet(
                    MONITORINFOEX, 28, "int"), WABottom: WB := NumGet(MONITORINFOEX, 32, "int"), Width: Width := R - L,
            Height: Height := B - T, WAWidth: WR - WL, WAHeight: WB - WT, Primary: NumGet(MONITORINFOEX, 36, "uint")
        }
    }
    throw Error("GetMonitorInfo: " A_LastError, -1)
}
