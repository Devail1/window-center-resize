#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "lib\Settings.ahk"
#Include "lib\Hotkeys.ahk"
#Include "lib\WindowOps.ahk"
#Include "lib\UpdateCheck.ahk"
#Include "gui\SettingsWindow.ahk"

global APP_NAME := "Window Center && Resizer"
global APP_VERSION := "2.0.0"
global INI_PATH := A_ScriptDir "\settings.ini"
global SETTINGS := SettingsLoad(INI_PATH)
global SIZE_INDEX := 0        ; 0 so the FIRST press selects preset 1 (fixes Bug D)

; An unhandled runtime error in a GUI app is a modal AutoHotkey dialog with a line number
; on a stranger's desktop. Catch anything that escapes and say something a human can act on.
OnError(_UncaughtAppError)
_UncaughtAppError(err, mode) {
    MsgBox("Something went wrong:`n`n" err.Message
         . "`n`nThe app will keep running. If this repeats, please report it at`n"
         . "https://github.com/Devail1/window-center-resize/issues"
         , APP_NAME, "Icon!")
    return 1        ; non-zero return suppresses AutoHotkey's default error dialog
}

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

DoCenter(*) {
    _ReportStatus(CenterActiveWindow())
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
    if IsValidHotkey(s["centerHotkey"]) {
        Hotkey(s["centerHotkey"], DoCenter, "On")
        live.Push(s["centerHotkey"])
    }
    if IsValidHotkey(s["resizeHotkey"]) {
        Hotkey(s["resizeHotkey"], DoResize, "On")
        live.Push(s["resizeHotkey"])
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
        Run('*RunAs "' A_ScriptFullPath '"')
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
; the tray automatically. Running from SOURCE there is no embedded icon, so load it from
; the repo — otherwise development shows AutoHotkey's default green H in the tray.
; Guarded and wrapped: a missing or unreadable icon must never stop the app starting.
if !A_IsCompiled {
    try TraySetIcon(A_ScriptDir "\..\assets\icon.ico")
}

RegisterHotkeys(SETTINGS)
