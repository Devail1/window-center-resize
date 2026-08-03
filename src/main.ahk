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
    SIZE_INDEX += 1
    if (SIZE_INDEX > SETTINGS["sizes"].Length)
        SIZE_INDEX := 1
    p := SETTINGS["sizes"][SIZE_INDEX]
    _ReportStatus(ApplyRectToActiveWindow(p.w, p.h))
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
                 . "Open the download page?", APP_NAME, "YesNo Iconi") = "Yes")
            Run(RELEASES_PAGE)
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

RegisterHotkeys(SETTINGS)
