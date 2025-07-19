#SingleInstance
#NoTrayIcon
#Include "%A_ScriptDir%\JXON.ahk"  ; Include the JSON library

; Add debug output
logFile := A_AppData . "\window-center-resize\autohotkey.log"
FileAppend("AutoHotkey script starting...`n", logFile)

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
    result := Join("", hotkeys*)
    FileAppend("Converted hotkey: " key " -> " result "`n", logFile)
    return result
}

jsonFilePath := A_AppData . "\window-center-resize\settings.json"

; Initialize global variables
global legacyToggleSizes := []
global currentPresetId := ""
global hotkeyToPresetMap := Map()  ; Map to store hotkey string to preset ID mapping
global hotkeyToGroupMap := Map()   ; Map to store hotkey string to group ID mapping

; Preset functions are now handled by closures in the hotkey registration

; Check if file exists
if !FileExist(jsonFilePath) {
    FileAppend("Settings file not found at: " jsonFilePath "`n", logFile)
    MsgBox("Settings file not found at: " jsonFilePath, "Error", "IconX")
    ExitApp
}

; Read JSON file
try {
    jsonContent := Fileread(jsonFilePath)
    if (jsonContent = "") {
        FileAppend("Settings file is empty: " jsonFilePath "`n", logFile)
        MsgBox("Settings file is empty: " jsonFilePath, "Error", "IconX")
        ExitApp
    }
} catch {
    FileAppend("Error reading settings file: " A_LastError "`n", logFile)
    MsgBox("Error reading settings file: " A_LastError, "Error", "IconX")
    ExitApp
}

; Parse JSON content
try {
    json := jxon_load(&jsonContent)
} catch {
    FileAppend("Error parsing JSON: " A_LastError "`n", logFile)
    MsgBox("Error parsing JSON: " A_LastError "`n`nContent: " jsonContent, "Error", "IconX")
    ExitApp
}

; Validate required fields
if !json.Has("presets") || !json.Has("toggleGroups") || !json.Has("settings") {
    FileAppend("Settings file is missing required fields`n", logFile)
    MsgBox("Settings file is missing required fields", "Error", "IconX")
    ExitApp
}

; Extract settings
presets := json["presets"]
toggleGroups := json["toggleGroups"]
appSettings := json["settings"]

FileAppend("Found " presets.Length " presets and " toggleGroups.Length " toggle groups`n", logFile)

; Register hotkeys for enabled presets
for each, preset in presets {
    FileAppend("Processing preset: " preset["name"] " - enabled=" preset["enabled"] " shortcut='" preset["shortcut"] "'`n",
        logFile)
    if (preset["enabled"] && preset["shortcut"] != "") {
        hotkeyStr := convertHotkeysJsToHotHotkeys(preset["shortcut"])
        FileAppend("Converted shortcut: '" preset["shortcut"] "' -> '" hotkeyStr "'`n", logFile)
        if (hotkeyStr != "") {
            FileAppend("Loading preset: " preset["name"] " - x=" preset["x"] " y=" preset["y"] " w=" preset["width"] " h=" preset[
                "height"] "`n", logFile)
            try {
                ; First try to remove any existing hotkey to avoid conflicts
                try {
                    Hotkey(hotkeyStr, "Off")
                } catch {
                    ; Ignore errors if hotkey wasn't registered
                }

                ; Store the mapping in the global map
                hotkeyToPresetMap.Set(hotkeyStr, preset["id"])

                ; Register the hotkey with a function that looks up the preset ID from the map
                Hotkey(hotkeyStr, ApplyPresetByHotkey, "On")

                FileAppend("Registered hotkey: " hotkeyStr " for preset: " preset["name"] " (ID: " preset["id"] ")`n",
                    logFile)
            } catch {
                FileAppend("Failed to register hotkey " hotkeyStr ": " A_LastError "`n", logFile)
            }
        } else {
            FileAppend("Failed to convert shortcut for preset: " preset["name"] "`n", logFile)
        }
    } else {
        FileAppend("Skipping preset: " preset["name"] " - enabled=" preset["enabled"] " shortcut='" preset["shortcut"] "'`n",
            logFile)
    }
}

; Register hotkeys for enabled toggle groups
for each, group in toggleGroups {
    if (group["enabled"] && group["shortcut"] != "") {
        hotkeyStr := convertHotkeysJsToHotHotkeys(group["shortcut"])
        if (hotkeyStr != "") {
            try {
                ; First try to remove any existing hotkey to avoid conflicts
                try {
                    Hotkey(hotkeyStr, "Off")
                } catch {
                    ; Ignore errors if hotkey wasn't registered
                }

                ; Store the mapping in the global map
                hotkeyToGroupMap.Set(hotkeyStr, group["id"])

                ; Register the hotkey with a function that looks up the group ID from the map
                Hotkey(hotkeyStr, CycleToggleGroupByHotkey, "On")
                FileAppend("Registered hotkey: " hotkeyStr " for toggle group: " group["name"] "`n", logFile)
            } catch {
                FileAppend("Failed to register hotkey " hotkeyStr ": " A_LastError "`n", logFile)
            }
        }
    }
}

; Legacy support - check if legacy settings exist and register them
; Only register legacy hotkeys if they don't conflict with preset hotkeys
if (json.Has("legacy")) {
    legacy := json["legacy"]

    if (legacy.Has("centerWindow") && legacy["centerWindow"].Has("keybinding")) {
        centerWindowKey := convertHotkeysJsToHotHotkeys(legacy["centerWindow"]["keybinding"])
        if (centerWindowKey != "") {
            ; Check if this hotkey is already used by a preset
            isUsedByPreset := false
            for each, preset in presets {
                if (preset["enabled"] && preset["shortcut"] != "") {
                    presetHotkey := convertHotkeysJsToHotHotkeys(preset["shortcut"])
                    if (presetHotkey = centerWindowKey) {
                        isUsedByPreset := true
                        FileAppend("Skipping legacy center hotkey " centerWindowKey " - already used by preset: " preset[
                            "name"] "`n", logFile)
                        break
                    }
                }
            }

            if (!isUsedByPreset) {
                try {
                    ; First try to remove any existing hotkey to avoid conflicts
                    try {
                        Hotkey(centerWindowKey, "Off")
                    } catch {
                        ; Ignore errors if hotkey wasn't registered
                    }

                    Hotkey(centerWindowKey, CenterWindow, "On")
                    FileAppend("Registered legacy center hotkey: " centerWindowKey "`n", logFile)
                } catch {
                    FileAppend("Failed to register legacy center hotkey " centerWindowKey ": " A_LastError "`n",
                        logFile)
                }
            }
        }
    }

    if (legacy.Has("resizeWindow") && legacy["resizeWindow"].Has("keybinding")) {
        resizeWindowKey := convertHotkeysJsToHotHotkeys(legacy["resizeWindow"]["keybinding"])
        if (resizeWindowKey != "") {
            ; Check if this hotkey is already used by a preset
            isUsedByPreset := false
            for each, preset in presets {
                if (preset["enabled"] && preset["shortcut"] != "") {
                    presetHotkey := convertHotkeysJsToHotHotkeys(preset["shortcut"])
                    if (presetHotkey = resizeWindowKey) {
                        isUsedByPreset := true
                        FileAppend("Skipping legacy resize hotkey " resizeWindowKey " - already used by preset: " preset[
                            "name"] "`n", logFile)
                        break
                    }
                }
            }

            if (!isUsedByPreset) {
                global legacyToggleSizes := legacy["resizeWindow"]["windowSizePercentages"]
                try {
                    ; First try to remove any existing hotkey to avoid conflicts
                    try {
                        Hotkey(resizeWindowKey, "Off")
                    } catch {
                        ; Ignore errors if hotkey wasn't registered
                    }

                    Hotkey(resizeWindowKey, LegacyResizeWindow, "On")
                    FileAppend("Registered legacy resize hotkey: " resizeWindowKey "`n", logFile)
                } catch {
                    FileAppend("Failed to register legacy resize hotkey " resizeWindowKey ": " A_LastError "`n",
                        logFile)
                }
            }
        }
    }
}

FileAppend("AutoHotkey script loaded successfully`n", logFile)

; Check for command line arguments
if (A_Args.Length > 0) {
    command := A_Args[1]
    FileAppend("Command line argument received: " command "`n", logFile)

    if (InStr(command, "APPLY_PRESET:")) {
        presetId := SubStr(command, 14)  ; Remove "APPLY_PRESET:" prefix
        ApplyPresetById(presetId)
        ExitApp
    }
}

; Function to apply a preset
ApplyPreset(preset) {
    FileAppend("ApplyPreset called for: " preset["name"] " - x=" preset["x"] " y=" preset["y"] " w=" preset["width"] " h=" preset[
        "height"] "`n", logFile)

    if (!appSettings["resizingEnabled"] && !appSettings["positioningEnabled"]) {
        FileAppend("Resizing and positioning disabled, returning`n", logFile)
        return
    }

    hwnd := WinExist("A")  ; Get handle to active window
    if (hwnd) {
        FileAppend("Found active window, applying preset`n", logFile)
        try {
            if (preset["unit"] = "%") {
                CenterAndResizeWindow("A", preset["width"], preset["height"], preset["x"], preset["y"])
            } else {
                ; For pixel values, we need to calculate percentages based on monitor size
                mon := GetNearestMonitorInfo(hwnd)
                widthPercent := (preset["width"] / mon.WAWidth) * 100
                heightPercent := (preset["height"] / mon.WAHeight) * 100
                xPercent := (preset["x"] / mon.WAWidth) * 100
                yPercent := (preset["y"] / mon.WAHeight) * 100
                CenterAndResizeWindow("A", widthPercent, heightPercent, xPercent, yPercent)
            }
            FileAppend("Preset applied successfully: " preset["name"] "`n", logFile)
        } catch {
            FileAppend("Error applying preset " preset["name"] ": " A_LastError "`n", logFile)
        }

        if (appSettings["showNotifications"]) {
            ; Show a brief notification (you can implement this as needed)
            ; ToolTip("Applied preset: " preset["name"])
        }
    } else {
        FileAppend("No active window found`n", logFile)
    }
}

; Function to apply a preset by ID
ApplyPresetById(presetId := "") {
    global currentPresetId

    ; If no presetId provided, use the global currentPresetId
    if (presetId = "") {
        presetId := currentPresetId
    }

    FileAppend("ApplyPresetById called for ID: " presetId "`n", logFile)

    ; Find the preset by ID
    for each, preset in presets {
        if (preset["id"] = presetId) {
            FileAppend("Found preset: " preset["name"] "`n", logFile)
            ApplyPreset(preset)
            return
        }
    }

    FileAppend("Preset with ID " presetId " not found`n", logFile)
}

; Function to cycle through a toggle group
CycleToggleGroup(group) {
    if (!appSettings["resizingEnabled"] && !appSettings["positioningEnabled"]) {
        return
    }

    ; Find the current preset in the group
    currentPresetId := group["presetIds"][group["currentIndex"] + 1]  ; +1 because AutoHotkey arrays are 1-indexed

    ; Find the preset data
    currentPreset := ""
    for each, preset in presets {
        if (preset["id"] = currentPresetId) {
            currentPreset := preset
            break
        }
    }

    if (currentPreset) {
        ApplyPreset(currentPreset)

        ; Update the current index for next cycle
        group["currentIndex"] := Mod(group["currentIndex"] + 1, group["presetIds"].Length)

        ; Save the updated group state back to the settings file
        SaveGroupState(group)
    }
}

; Function to cycle through a toggle group by ID
CycleToggleGroupById(groupId) {
    if (!appSettings["resizingEnabled"] && !appSettings["positioningEnabled"]) {
        return
    }

    ; Find the group by ID
    targetGroup := ""
    for each, group in toggleGroups {
        if (group["id"] = groupId) {
            targetGroup := group
            break
        }
    }

    if (targetGroup) {
        CycleToggleGroup(targetGroup)
    } else {
        FileAppend("Toggle group with ID " groupId " not found`n", logFile)
    }
}

; Function to apply preset by hotkey string (looks up preset ID from map)
ApplyPresetByHotkey(thisHotkey) {
    global hotkeyToPresetMap

    if (hotkeyToPresetMap.Has(thisHotkey)) {
        presetId := hotkeyToPresetMap.Get(thisHotkey)
        FileAppend("ApplyPresetByHotkey: hotkey=" thisHotkey " -> presetId=" presetId "`n", logFile)
        ApplyPresetById(presetId)
    } else {
        FileAppend("ApplyPresetByHotkey: no preset found for hotkey " thisHotkey "`n", logFile)
    }
}

; Function to cycle toggle group by hotkey string (looks up group ID from map)
CycleToggleGroupByHotkey(thisHotkey) {
    global hotkeyToGroupMap

    if (hotkeyToGroupMap.Has(thisHotkey)) {
        groupId := hotkeyToGroupMap.Get(thisHotkey)
        FileAppend("CycleToggleGroupByHotkey: hotkey=" thisHotkey " -> groupId=" groupId "`n", logFile)
        CycleToggleGroupById(groupId)
    } else {
        FileAppend("CycleToggleGroupByHotkey: no group found for hotkey " thisHotkey "`n", logFile)
    }
}

; Function to save group state back to settings file
SaveGroupState(updatedGroup) {
    try {
        ; Read current settings
        jsonContent := Fileread(jsonFilePath)
        json := jxon_load(&jsonContent)

        ; Update the specific group
        for index, group in json["toggleGroups"] {
            if (group["id"] = updatedGroup["id"]) {
                json["toggleGroups"][index] := updatedGroup
                break
            }
        }

        ; Write back to file
        FileDelete(jsonFilePath)
        FileAppend(jxon_dump(json, 4), jsonFilePath)
    } catch {
        ; Silently fail - this is not critical
    }
}

; Legacy resize window function
LegacyResizeWindow(WinTitle) {
    static size := 1
    global legacyToggleSizes

    ; Check if legacyToggleSizes is empty or not initialized
    if (!legacyToggleSizes || legacyToggleSizes.Length = 0) {
        FileAppend("Legacy resize window called but no sizes configured`n", logFile)
        return
    }

    size++

    if (size > legacyToggleSizes.Length)  ; Reset size to 1 if it exceeds array length
        size := 1

    hwnd := WinExist("A")  ; Get handle to active window

    if (hwnd) {
        preset := legacyToggleSizes[size]
        ; Get x and y directly from the preset object
        xPos := preset.Has("x") ? preset["x"] : 50
        yPos := preset.Has("y") ? preset["y"] : 50
        CenterAndResizeWindow("A", preset["width"], preset["height"], xPos, yPos)
    }
}

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
        } catch {
            HandleWindowError(Error(A_LastError))
        }
    } else {
        ; MsgBox("Window not found.")
    }
}

ResizeWindow(WinTitle) {
    static size := 1
    global legacyToggleSizes

    size++

    if (size > legacyToggleSizes.Length)  ; Reset size to 1 if it exceeds array length
        size := 1

    hwnd := WinExist("A")  ; Get handle to active window

    if (hwnd) {
        preset := legacyToggleSizes[size]
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

        ; Calculate position based on percentages - treat them as absolute positions within the work area
        ; XPercentage = 0 means left edge, 100 means right edge
        ; YPercentage = 0 means top edge, 100 means bottom edge
        NewX := mon.WALeft + (mon.WAWidth * XPercentage / 100)
        NewY := mon.WATop + (mon.WAHeight * YPercentage / 100)

        ; Ensure window stays within screen bounds
        NewX := Max(mon.WALeft, Min(NewX, mon.WARight - NewWidth))
        NewY := Max(mon.WATop, Min(NewY, mon.WABottom - NewHeight))

        FileAppend("Moving window to: X=" NewX " Y=" NewY " W=" NewWidth " H=" NewHeight " (from percentages: X=" XPercentage " Y=" YPercentage " W=" WidthPercentage " H=" HeightPercentage ")`n",
            logFile)

        try {
            WinMove(NewX, NewY, NewWidth, NewHeight, hwnd)
        } catch {
            HandleWindowError(Error(A_LastError))
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
            ".*(\d+)$", "$1"), Left: L := NumGet(MONITORINFOEX, 4, "int"), Top: T := NumGet(MONITORINFOEX, 8, "int"
            ),
            Right: R := NumGet(MONITORINFOEX, 12, "int"), Bottom: B := NumGet(MONITORINFOEX, 16, "int"), WALeft: WL :=
                NumGet(MONITORINFOEX, 20, "int"), WATop: WT := NumGet(MONITORINFOEX, 24, "int"), WARight: WR :=
                NumGet(
                    MONITORINFOEX, 28, "int"), WABottom: WB := NumGet(MONITORINFOEX, 32, "int"), Width: Width := R -
                L,
            Height: Height := B - T, WAWidth: WR - WL, WAHeight: WB - WT, Primary: NumGet(MONITORINFOEX, 36, "uint"
            )
        }
    }
    throw Error("GetMonitorInfo: " A_LastError, -1)
}
