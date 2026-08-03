; tests/manual_settings_gui.ahk
#Requires AutoHotkey v2.0
#Include "..\src\gui\SettingsWindow.ahk"
ShowSettingsWindow(A_ScriptDir "\..\settings.ini", (s) => MsgBox("saved: " s["centerHotkey"]))
