#Requires AutoHotkey v2.0
#SingleInstance Force

; Window Center & Resizer - centre and resize windows from a keyboard shortcut.
; Copyright (C) 2024-2026 Liav Edry
;
; This program is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License version 2, as published by the Free
; Software Foundation. It is distributed WITHOUT ANY WARRANTY; without even the
; implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
; the LICENSE file for the full text.
;
; Releases up to and including 2.1.0 were published under the MIT licence and
; remain available under it.

#Include "lib\Settings.ahk"
#Include "lib\Hotkeys.ahk"
#Include "lib\WindowOps.ahk"
#Include "lib\UpdateCheck.ahk"
#Include "gui\SettingsWindow.ahk"

global APP_NAME := "Window Center & Resizer"
global APP_VERSION := "2.2.0"
global INI_PATH := A_ScriptDir "\settings.ini"
; An unhandled runtime error in a GUI app is a modal AutoHotkey dialog with a line number
; on a stranger's desktop. Catch anything that escapes and say something a human can act on.
OnError(_UncaughtAppError)
_UncaughtAppError(err, mode) {
    ; A Windows error code on its own is unactionable: "(6) The handle is invalid." says what
    ; went wrong and nothing about where, so an issue reporting it cannot be investigated and
    ; the reporter cannot be asked anything useful either. Append whatever location the error
    ; object carries.
    ;
    ; Every read below is best-effort and separately guarded. A thrown value need not be an
    ; Error at all - `throw "x"` is legal - and a handler that faults while describing a fault
    ; turns a recoverable problem into AutoHotkey's own error dialog, which is the exact
    ; outcome this function exists to prevent.
    msg := "An unknown error occurred."
    try msg := err.Message
    detail := ""
    try {
        if (err.Line) {
            detail := "`n`n" (err.What ? err.What "(), " : "") "line " err.Line
            if (err.File)
                detail .= " of " RegExReplace(err.File, ".*\\")
        }
    }
    try {
        if (err.Extra != "")
            detail .= "`nSpecifically: " err.Extra
    }
    MsgBox("Something went wrong:`n`n" msg . detail
         . "`n`nThe app will keep running. If this repeats, please report it at`n"
         . "https://github.com/Devail1/window-center-resize/issues"
         , APP_NAME, "Icon!")
    return 1        ; non-zero return suppresses AutoHotkey's default error dialog
}

global SETTINGS := SettingsLoad(INI_PATH)
global SIZE_INDEX := 0        ; 0 so the FIRST press selects preset 1 (fixes Bug D)


_ReportStatus(status) {
    if (status = "no-window")
        TrayTip(APP_NAME, "No active window found.")
    else if (status = "elevated")
        MsgBox("This window is running as administrator, so it can't be moved "
             . "unless " APP_NAME " is also running as administrator.`n`n"
             . "Use the tray menu item 'Restart as administrator' if you need this."
             , APP_NAME, "Icon!")
    else if (status = "error")
        TrayTip(APP_NAME, "Windows refused to move this window.")
}

DoPosition(i, *) {
    global SETTINGS
    ; The hotkey was bound against the settings as they were at registration time. A save
    ; between then and now cannot leave a stale index pointing past the end of a shorter list.
    if (i < 1 || i > SETTINGS["positions"].Length)
        return
    _ReportStatus(ApplyPositionToActiveWindow(SETTINGS["positions"][i]))
}

DoResize(*) {
    global SIZE_INDEX, SETTINGS
    ; Advance a CANDIDATE index and only commit it once the move succeeds — otherwise three
    ; failed presses on an elevated window silently skip three presets.
    next := SIZE_INDEX + 1
    if (next > SETTINGS["sizes"].Length)
        next := 1
    p := SETTINGS["sizes"][next]
    status := ApplyRectToActiveWindow(p.w, p.h)
    if (status = "ok")
        SIZE_INDEX := next
    _ReportStatus(status)
}

RegisterHotkeys(s) {
    static prev := ""
    if (prev != "") {
        for hk in prev {
            try Hotkey(hk, "Off")
        }
    }
    live := []
    ; What to register is decided in PlanHotkeyRegistration, which is pure and tested. This
    ; loop only carries it out.
    for entry in PlanHotkeyRegistration(s) {
        Hotkey(entry.key, (entry.action = "resize") ? DoResize : DoPosition.Bind(entry.index), "On")
        live.Push(entry.key)
    }
    prev := live
}

OnSettingsSaved(s) {
    global SETTINGS, SIZE_INDEX
    SETTINGS := s
    SIZE_INDEX := 0
    RegisterHotkeys(s)
}

CheckForUpdates(*) {
    latest := FetchLatestVersion()
    if (latest = "") {
        MsgBox("Couldn't reach GitHub to check for updates.", APP_NAME, "Icon!")
        return
    }
    if (CompareVersions(latest, APP_VERSION) > 0) {
        if (MsgBox("Version " latest " is available. You have " APP_VERSION ".`n`n"
                 . "Open the download page?", APP_NAME, "YesNo Iconi") = "Yes") {
            ; Run throws if the machine has no registered https handler. Show the URL so the
            ; user can copy it rather than letting a raw error dialog escape.
            try {
                Run(RELEASES_PAGE)
            } catch {
                MsgBox("Couldn't open your browser. The download page is:`n`n"
                     . RELEASES_PAGE, APP_NAME, "Icon!")
            }
        }
    } else {
        MsgBox("You're up to date (" APP_VERSION ").", APP_NAME, "Iconi")
    }
}

RestartElevated(*) {
    try {
        ; Compiled, the exe IS the program. Running from a script the exe is the AutoHotkey
        ; interpreter, so the script has to be passed as an argument - handing Windows a bare
        ; .ahk path launches whichever AutoHotkey is *installed*, not the copy shipped here,
        ; and on a machine with none it opens a "how do you want to open this file" dialog.
        if A_IsCompiled
            Run('*RunAs "' A_ScriptFullPath '"')
        else
            Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
        ExitApp()
    } catch {
        MsgBox("Couldn't restart with administrator rights.", APP_NAME, "Icon!")
    }
}

A_TrayMenu.Delete()
A_TrayMenu.Add("Settings", (*) => ShowSettingsWindow(INI_PATH, OnSettingsSaved))
A_TrayMenu.Add("Check for updates", CheckForUpdates)
A_TrayMenu.Add()
A_TrayMenu.Add("Restart as administrator", RestartElevated)
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Settings"
A_IconTip := APP_NAME " " APP_VERSION

; The compiled exe embeds assets\icon.ico via Ahk2Exe /icon, and AutoHotkey uses that for
; the tray automatically. Running from a script there is no embedded icon, so load it from
; disk — otherwise the tray shows AutoHotkey's default green H. Two locations, because there
; are two ways to run from a script: beside the script in a portable release, or up in the
; repo when running out of a working tree.
; Guarded and wrapped: a missing or unreadable icon must never stop the app starting.
if !A_IsCompiled {
    for candidate in [A_ScriptDir "\icon.ico", A_ScriptDir "\..\assets\icon.ico"] {
        if FileExist(candidate) {
            try TraySetIcon(candidate)
            break
        }
    }
}

RegisterHotkeys(SETTINGS)
