#SingleInstance
#NoTrayIcon

; Simple test script to verify hotkeys work
^!C::
MsgBox("Ctrl+Alt+C pressed!")
return

^!L::
MsgBox("Ctrl+Alt+L pressed!")
return

^!R::
MsgBox("Ctrl+Alt+R pressed!")
return

F9::
MsgBox("F9 pressed!")
return

MsgBox("Test script loaded. Press Ctrl+Alt+C, Ctrl+Alt+L, Ctrl+Alt+R, or F9 to test.")
