#Requires AutoHotkey v2.0
#Include "..\lib\Settings.ahk"
#Include "..\lib\Hotkeys.ahk"
#Include "Theme.ahk"

; The one place the product name is spelled, for the window title and every MsgBox raised
; from this file. It deliberately does NOT reuse main.ahk's APP_NAME: tests\manual_settings_gui.ahk
; loads this file standalone, with no main.ahk in the include chain.
;
; ONE ampersand. In AutoHotkey '&' is an accelerator prefix in CONTROL text only (buttons,
; labels, menu items), where it must be doubled to render literally. Window titles and MsgBox
; titles do not process it at all, so the doubled form showed up verbatim as
; "Window Center && Resizer" in the title bar. No control in this window contains an
; ampersand, so nothing here needs doubling.
global APP_TITLE := "Window Center & Resizer"

global _settingsGui := ""
global _settingsPopulate := ""      ; the ONE routine that fills the controls from settings

; The native Hotkey control cannot represent every hotkey the INI can hold. A Win-key
; combination ("#Up") assigned to it reads back as an EMPTY STRING, silently — measured, not
; assumed. Anything else it fails to parse does the same. So an empty read-back is NOT the
; user clearing the field, it is the control's blind spot, and writing that empty value to
; the INI would DESTROY a hotkey the user set by hand.
;
; Rule: an empty read-back keeps whatever value was loaded into the control. A non-empty
; read-back is the user's choice and wins.
PreserveHotkey(controlValue, loadedValue) {
    if (Trim(controlValue) = "")
        return loadedValue
    return Trim(controlValue)
}

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

    ; Captured by the nested closures below. Declared HERE so they belong to this function's
    ; scope and _Populate's writes are visible to _Save — the guard above is worthless if each
    ; nested function gets its own copy.
    loadedCenter := "", loadedResize := ""

    th := Theme("light")

    g := Gui("-MaximizeBox -MinimizeBox", APP_TITLE)
    g.MarginX := 16, g.MarginY := 16
    g.BackColor := th["bg"]
    g.SetFont("s10 w400 c" th["text"], "Segoe UI")

    ; --- Hotkeys ---------------------------------------------------------------------------
    g.SetFont("s11 w600 c" th["header"], "Segoe UI")
    g.Add("Text", "xm w300", "Hotkeys")
    g.SetFont("s9 w400 c" th["hint"], "Segoe UI")
    g.Add("Text", "xm y+2 w300", "Click a field and press the keys you want.")
    g.SetFont("s10 w400 c" th["text"], "Segoe UI")

    g.Add("Text", "xm y+12 w76", "Center")
    hCenter := g.Add("Hotkey", "x+18 yp-3 w206")
    g.Add("Text", "xm y+10 w76", "Resize")
    hResize := g.Add("Hotkey", "x+18 yp-3 w206")

    ; --- Size presets ----------------------------------------------------------------------
    g.SetFont("s11 w600 c" th["header"], "Segoe UI")
    g.Add("Text", "xm y+24 w300", "Size presets")
    g.SetFont("s9 w400 c" th["hint"], "Segoe UI")
    g.Add("Text", "xm y+2 w300", "Percentage of the screen work area.")
    g.SetFont("s10 w400 c" th["text"], "Segoe UI")

    edits := []
    loop 3 {
        i := A_Index
        g.Add("Text", "xm y+10 w76", "Preset " i)
        ew := g.Add("Edit", "x+18 yp-3 w88 Number")
        ; The multiplication sign, not the letter x — this is a dimension, not a form field.
        g.SetFont("s10 w400 c" th["hint"], "Segoe UI")
        g.Add("Text", "x+6 yp+3 w18 Center", "×")
        g.SetFont("s10 w400 c" th["text"], "Segoe UI")
        eh := g.Add("Edit", "x+6 yp-3 w88 Number")
        edits.Push({ w: ew, h: eh })
    }

    ; The ONE place controls are filled from settings — first open, re-open, and Reset.
    _Populate(st) {
        loadedCenter := st["centerHotkey"]
        loadedResize := st["resizeHotkey"]
        hCenter.Value := loadedCenter
        hResize.Value := loadedResize
        loop 3 {
            edits[A_Index].w.Value := st["sizes"][A_Index].w
            edits[A_Index].h.Value := st["sizes"][A_Index].h
        }
    }

    ; Reset repopulates every field from defaults and cannot be undone by the user once it
    ; runs, so it must not sit adjacent to the commit pair where a misclick lands on it
    ; instead of Close or Save. It gets its own position at the left margin; Close and Save
    ; stay right-aligned as a pair, with Save last since Windows places the primary action
    ; rightmost, and `Default` makes it the accent-filled button Windows 11 draws for the
    ; default push button.
    ; 300 content, right-hand pair = 88 + 8 + 88 = 184, so the pair starts at 300 - 184 = 116.
    btnReset := g.Add("Button", "xm y+24 w88", "Reset")
    btnClose := g.Add("Button", "xm+116 yp w88", "Close")
    btnSave  := g.Add("Button", "x+8 w88 Default", "Save")

    btnSave.OnEvent("Click", (*) => _Save())
    ; Reset fills the CONTROLS from the defaults and stops there. It must not touch the INI:
    ; a reset the user cannot back out of is worse than no reset at all. They review what
    ; appeared and press Save to commit it, or Close to walk away.
    btnReset.OnEvent("Click", (*) => _Populate(SettingsDefaults()))
    btnClose.OnEvent("Click", (*) => g.Hide())
    g.OnEvent("Close", (*) => g.Hide())
    g.OnEvent("Escape", (*) => g.Hide())

    _Save() {
        c := PreserveHotkey(hCenter.Value, loadedCenter)
        r := PreserveHotkey(hResize.Value, loadedResize)
        ; The Hotkey control cannot emit malformed syntax, but it CAN emit a bare single
        ; character — which registers a system-wide key swallower — and the INI is
        ; hand-editable, so a preserved value can be anything. The guard stays.
        if !IsValidHotkey(c) {
            MsgBox("'" c "' is not a valid hotkey.", APP_TITLE, "Icon!")
            return
        }
        if !IsValidHotkey(r) {
            MsgBox("'" r "' is not a valid hotkey.", APP_TITLE, "Icon!")
            return
        }
        ; RegisterHotkeys binds center then resize; identical strings mean the second
        ; Hotkey() call OVERWRITES the first, so centring dies silently and permanently.
        if (c = r) {
            MsgBox("Both actions can't use the same hotkey.", APP_TITLE, "Icon!")
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
                 , APP_TITLE, "Icon!")
            return
        }
        ; What was just written is now what is loaded — otherwise a preserved Win-key hotkey
        ; would be measured against a stale baseline on the next Save in the same session.
        loadedCenter := c, loadedResize := r
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
    ; Focus must not start in a Hotkey control: it captures every keystroke (that is its whole
    ; purpose — building a key combination from whatever you press) including Tab, so the user
    ; could not type or even tab away without reaching for the mouse. Focus must also not be
    ; left to fall through to Reset, which is what an unset focus defaults to here: a stray
    ; Enter would repopulate every field from defaults and discard the user's settings. Save is
    ; safe on both counts — Enter commits what is already on screen, Escape still closes, Tab
    ; cycles normally, and nothing swallows input.
    btnSave.Focus()
    g.Show()
}
