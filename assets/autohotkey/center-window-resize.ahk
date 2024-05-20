﻿#SingleInstance
#NoTrayIcon
#Include "%A_ScriptDir%\JXON.ahk"  ; Include the JSON library

Join(sep, params*) {
  str := ''
  for index, param in params
    str .= sep . param
  return SubStr(str, StrLen(sep) + 1)
}

hotkeysJsToHotHotkeys := Map("shift", "+", "control", "^", "alt", "!", "meta", "#")

; Function to convert hotkeys-js keys to HotHotkeys syntax
ConvertHotkeysJsToHotHotkeys(key) {
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

jsonFilePath := A_AppData . "\window-snapper-resizer\settings.json"

; Read JSON file
jsonContent := Fileread(jsonFilePath)

; Parse JSON content
json := jxon_load(&jsonContent)

; Convert the map to a JSON formatted string
jsonString := jxon_dump(json, indent := 0)

; Extract values from JSON
centerWindowObj := json["centerWindow"]  ; Access "centerWindow" as an object
CenterWindowKey := ConvertHotkeysJsToHotHotkeys(centerWindowObj["keybinding"])  ; Access "keybinding" from the object
resizeWindowObj := json["resizeWindow"]  ; Access "resizeWindow" as an object
ResizeWindowKey := ConvertHotkeysJsToHotHotkeys(resizeWindowObj["keybinding"])  ; Access "keybinding" from the object
ToggleSizes := resizeWindowObj["windowSizePercentages"]  ; Access the entire array


; Define hotkeys if keybinding exists
if (CenterWindowKey != "")
  Hotkey(CenterWindowKey, CenterWindow, "On")
if (ResizeWindowKey != "")
  Hotkey(ResizeWindowKey, ResizeWindow, "On")


CenterWindow(WinTitle) {
  hwnd := WinExist("A")  ; Check if window exists

  if (hwnd) {
    mon := GetNearestMonitorInfo(hwnd)

    WinGetPos(&WinX, &WinY, &Width, &Height, hwnd)  ; Get current window position and size

    NewX := mon.WALeft + (mon.WAWidth - Width) / 2  ; Calculate centered X position on current monitor
    NewY := mon.WATop + (mon.WAHeight - Height) / 2  ; Calculate centered Y position on current monitor

    WinMove(NewX, NewY, Width, Height, hwnd)  ; Move window to the center
  } else {
    MsgBox("Window not found.")
  }
}

ResizeWindow(WinTitle) {
  static size := 1
  size := Mod(size + 1, ToggleSizes.Length) + 1

  hwnd := WinExist("A")  ; Get handle to active window

  if (hwnd) {
    CenterAndResizeWindow("A", ToggleSizes[size]["width"], ToggleSizes[size]["height"])
  } else {
    MsgBox("Active window not found.")
  }
}


CenterAndResizeWindow(WinTitle, WidthPercentage, HeightPercentage) {
  hwnd := WinExist(WinTitle)  ; Check if window exists

  if (hwnd) {
    ScreenWidth := A_ScreenWidth
    ScreenHeight := A_ScreenHeight
    mon := GetNearestMonitorInfo(hwnd)


    NewWidth := (ScreenWidth * WidthPercentage / 100)
    NewHeight := (ScreenHeight * HeightPercentage / 100)

    WinGetPos(&WinX, &WinY, &Width, &Height, hwnd)  ; Get current window position and size

    NewX := mon.WALeft + (mon.WAWidth - NewWidth) / 2 ; Calculate centered X position on current monitor
    NewY := mon.WATop + (mon.WAHeight - NewHeight) / 2 ; Calculate centered Y position on current monitor

    WinMove(NewX, NewY, NewWidth, NewHeight, hwnd)  ; Move and resize window
  } else {
    MsgBox("Window with title `"" WinTitle "`" not found.")
  }
}


GetNearestMonitorInfo(winTitle) {
  static MONITOR_DEFAULTTONEAREST := 0x00000002
  hwnd := WinExist(winTitle)
  hMonitor := DllCall("MonitorFromWindow", "ptr", hwnd, "uint", MONITOR_DEFAULTTONEAREST, "ptr")
  NumPut("uint", 104, MONITORINFOEX := Buffer(104))
  if (DllCall("user32\GetMonitorInfo", "ptr", hMonitor, "ptr", MONITORINFOEX)) {
    Return { Handle: hMonitor
      , Name: Name := StrGet(MONITORINFOEX.ptr + 40, 32)
      , Number: RegExReplace(Name, ".*(\d+)$", "$1")
      , Left: L := NumGet(MONITORINFOEX, 4, "int")
      , Top: T := NumGet(MONITORINFOEX, 8, "int")
      , Right: R := NumGet(MONITORINFOEX, 12, "int")
      , Bottom: B := NumGet(MONITORINFOEX, 16, "int")
      , WALeft: WL := NumGet(MONITORINFOEX, 20, "int")
      , WATop: WT := NumGet(MONITORINFOEX, 24, "int")
      , WARight: WR := NumGet(MONITORINFOEX, 28, "int")
      , WABottom: WB := NumGet(MONITORINFOEX, 32, "int")
      , Width: Width := R - L
      , Height: Height := B - T
      , WAWidth: WR - WL
      , WAHeight: WB - WT
      , Primary: NumGet(MONITORINFOEX, 36, "uint")
    }
  }
  throw Error("GetMonitorInfo: " A_LastError, -1)
}