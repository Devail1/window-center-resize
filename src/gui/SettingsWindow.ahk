#Requires AutoHotkey v2.0
#Include "..\lib\Settings.ahk"
#Include "..\lib\Hotkeys.ahk"

global _settingsGui := ""
global _settingsPopulate := ""      ; the ONE routine that fills the controls from settings

ShowSettingsWindow(iniPath, onSaved) {
    global _settingsGui, _settingsPopulate
    if (_settingsGui != "") {          ; single instance
        ; Re-opening must RELOAD from settings. Closing without saving used to leave the
        ; abandoned edit sitting in the box — contradicting the live binding, and committed
        ; by the next Save. Same populate routine as first open, not a second code path.
        _settingsPopulate(SettingsLoad(iniPath))
        _settingsGui.Show()
        return
    }
    s := SettingsLoad(iniPath)

    g := Gui("-MaximizeBox -MinimizeBox", "Window Center && Resizer")
    g.MarginX := 14, g.MarginY := 12
    g.SetFont("s9", "Segoe UI")

    g.Add("Text", "xm w320", "Hotkeys (AutoHotkey syntax — ^ Ctrl, + Shift, ! Alt, # Win)")
    g.Add("Text", "xm y+8 w70", "Center:")
    eCenter := g.Add("Edit", "x+6 yp-3 w120")
    g.Add("Text", "xm y+8 w70", "Resize:")
    eResize := g.Add("Edit", "x+6 yp-3 w120")

    g.Add("Text", "xm y+16 w320", "Size presets (% of the screen work area)")
    edits := []
    loop 3 {
        i := A_Index
        g.Add("Text", "xm y+8 w70", "Preset " i ":")
        ew := g.Add("Edit", "x+6 yp-3 w50 Number")
        g.Add("Text", "x+4 yp+3 w14", "x")
        eh := g.Add("Edit", "x+4 yp-3 w50 Number")
        edits.Push({ w: ew, h: eh })
    }

    ; The ONE place controls are filled from settings — used on first open and on re-open.
    _Populate(st) {
        eCenter.Value := st["centerHotkey"]
        eResize.Value := st["resizeHotkey"]
        loop 3 {
            edits[A_Index].w.Value := st["sizes"][A_Index].w
            edits[A_Index].h.Value := st["sizes"][A_Index].h
        }
    }

    btnSave := g.Add("Button", "xm y+18 w90 Default", "Save")
    btnClose := g.Add("Button", "x+8 w90", "Close")

    btnSave.OnEvent("Click", (*) => _Save())
    btnClose.OnEvent("Click", (*) => g.Hide())
    g.OnEvent("Close", (*) => g.Hide())
    g.OnEvent("Escape", (*) => g.Hide())

    _Save() {
        c := Trim(eCenter.Value), r := Trim(eResize.Value)
        if !IsValidHotkey(c) {
            MsgBox("'" c "' is not a valid hotkey.", "Window Center && Resizer", "Icon!")
            return
        }
        if !IsValidHotkey(r) {
            MsgBox("'" r "' is not a valid hotkey.", "Window Center && Resizer", "Icon!")
            return
        }
        ; RegisterHotkeys binds center then resize; identical strings mean the second
        ; Hotkey() call OVERWRITES the first, so centring dies silently and permanently.
        if (c = r) {
            MsgBox("Both actions can't use the same hotkey.", "Window Center && Resizer", "Icon!")
            return
        }
        out := SettingsDefaults()
        out["centerHotkey"] := c
        out["resizeHotkey"] := r
        sizes := []
        loop 3
            sizes.Push({ w: ClampPercent(edits[A_Index].w.Value)
                       , h: ClampPercent(edits[A_Index].h.Value) })
        out["sizes"] := sizes
        ; IniWrite throws OSError if the INI cannot be written — the portable exe dropped in
        ; C:\Program Files, a read-only USB stick, a network path. Unguarded, the user got a
        ; raw AHK dialog, onSaved never fired, the window never hid, and nothing said their
        ; settings were lost.
        try {
            SettingsSave(iniPath, out)
        } catch {
            MsgBox("Couldn't save settings to:`n`n" iniPath
                 . "`n`nThe folder may be read-only. Try moving the app somewhere you can "
                 . "write to, such as your Documents folder."
                 , "Window Center && Resizer", "Icon!")
            return
        }
        loop 3 {
            edits[A_Index].w.Value := sizes[A_Index].w   ; reflect clamping back to the user
            edits[A_Index].h.Value := sizes[A_Index].h
        }
        onSaved(out)
        g.Hide()
    }

    _settingsGui := g
    _settingsPopulate := _Populate
    _Populate(s)
    g.Show()
}
