#Requires AutoHotkey v2.0
#Include "..\src\lib\UpdateCheck.ahk"
MsgBox("latest tag: [" FetchLatestVersion() "]")
ExitApp()
