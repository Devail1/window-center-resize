#Requires AutoHotkey v2.0
#Include "..\src\lib\WindowOps.ahk"
^+F12:: MsgBox("resize 50/50 -> " ApplyRectToActiveWindow(50, 50))
^+F11:: MsgBox("center      -> " CenterActiveWindow())
