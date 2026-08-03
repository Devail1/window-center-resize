#Requires AutoHotkey v2.0
#Include "..\lib\Settings.ahk"
#Include "..\lib\Hotkeys.ahk"

global _settingsGui := ""

ShowSettingsWindow(iniPath, onSaved) {
    global _settingsGui
    if (_settingsGui != "") {          ; single instance
        _settingsGui.Show()
        return
    }
    s := SettingsLoad(iniPath)

    g := Gui("-MaximizeBox -MinimizeBox", "Window Center && Resizer")
    g.MarginX := 14, g.MarginY := 12
    g.SetFont("s9", "Segoe UI")

    g.Add("Text", "xm w320", "Hotkeys (AutoHotkey syntax — ^ Ctrl, + Shift, ! Alt, # Win)")
    g.Add("Text", "xm y+8 w70", "Center:")
    eCenter := g.Add("Edit", "x+6 yp-3 w120", s["centerHotkey"])
    g.Add("Text", "xm y+8 w70", "Resize:")
    eResize := g.Add("Edit", "x+6 yp-3 w120", s["resizeHotkey"])

    g.Add("Text", "xm y+16 w320", "Size presets (% of the screen work area)")
    edits := []
    loop 3 {
        i := A_Index
        g.Add("Text", "xm y+8 w70", "Preset " i ":")
        ew := g.Add("Edit", "x+6 yp-3 w50 Number", s["sizes"][i].w)
        g.Add("Text", "x+4 yp+3 w14", "x")
        eh := g.Add("Edit", "x+4 yp-3 w50 Number", s["sizes"][i].h)
        edits.Push({ w: ew, h: eh })
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
        out := SettingsDefaults()
        out["centerHotkey"] := c
        out["resizeHotkey"] := r
        sizes := []
        loop 3
            sizes.Push({ w: ClampPercent(edits[A_Index].w.Value)
                       , h: ClampPercent(edits[A_Index].h.Value) })
        out["sizes"] := sizes
        SettingsSave(iniPath, out)
        loop 3 {
            edits[A_Index].w.Value := sizes[A_Index].w   ; reflect clamping back to the user
            edits[A_Index].h.Value := sizes[A_Index].h
        }
        onSaved(out)
        g.Hide()
    }

    _settingsGui := g
    g.Show()
}
