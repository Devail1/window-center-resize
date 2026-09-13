#Requires AutoHotkey v2.0
#Include "..\lib\Settings.ahk"
#Include "..\lib\Hotkeys.ahk"
#Include "ScreenPicture.ahk"
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
;
; With a list, the baseline is the ROW'S OWN current hotkey rather than a captured scalar. That
; is deliberate: a parallel array of baselines desynchronises the first time a row is deleted.
; The cost is that the control cannot CLEAR a binding — every empty read is treated as the blind
; spot. Unbinding a position is therefore an INI edit, which is the same escape hatch the rest
; of this window relies on.
PreserveHotkey(controlValue, loadedValue) {
    if (Trim(controlValue) = "")
        return loadedValue
    return Trim(controlValue)
}

; What an unnamed position is called. A blank name is only a cosmetic problem, so it is filled
; in rather than being turned into a modal argument at save time.
_PositionLabel(p, i) {
    return (Trim(p.name) != "") ? Trim(p.name) : "Position " i
}

ShowSettingsWindow(iniPath, onSaved) {
    global _settingsGui, _settingsPopulate
    if (_settingsGui != "") {          ; single instance
        ; Re-opening must RELOAD from settings. Closing without saving used to leave the
        ; abandoned edit sitting in the box — contradicting the live binding, and committed
        ; by the next Save. Same populate routine as first open, not a second code path.
        _settingsPopulate(SettingsLoad(iniPath))
        _settingsGui.Show()
        ; The monitor's aspect ratio is re-read here, not cached: the user may have dragged
        ; this window to a different screen since it was last open.
        ScreenPictureRelayout()
        return
    }
    s := SettingsLoad(iniPath)

    ; Captured by the nested closures below. Declared HERE so they belong to this function's
    ; scope and _Populate's writes are visible to _Save — the guard is worthless if each
    ; nested function gets its own copy.
    positions := []
    sel := 0
    loadedResize := ""
    ; Set while the controls are being filled FROM the model, so the Change handlers below do
    ; not write the value they were just given back into a different row.
    loading := false

    th := Theme("light")

    g := Gui("-MaximizeBox -MinimizeBox", APP_TITLE)
    g.MarginX := 16, g.MarginY := 16
    g.BackColor := th["bg"]
    g.SetFont("s10 w400 c" th["text"], "Segoe UI")

    ; --- Positions ---------------------------------------------------------------------------
    g.SetFont("s11 w600 c" th["header"], "Segoe UI")
    g.Add("Text", "xm w300", "Positions")
    g.SetFont("s9 w400 c" th["hint"], "Segoe UI")
    g.Add("Text", "xm y+2 w300", "Drag the blue box inside your screen.")
    g.SetFont("s10 w400 c" th["text"], "Segoe UI")

    ; Spacing ladder, each distinguishable from its neighbour: 2 (header->subtitle) /
    ; 10 (row->row) / 20 (subtitle->first row) / 24 (section->section). The subtitle sat only
    ; 2px further from the first row than the rows sit from each other, so it read as another
    ; form row instead of a caption under the bold header. Do not collapse this to a constant.
    g.Add("Text", "xm y+20 w300 h0")        ; spacer: the picture is added by ScreenPictureCreate
    ScreenPictureCreate(g, th["hint"], th["screen"], th["accent"], _OnPictureDrag)

    lv := g.Add("ListView", "xm y+10 w300 r4 -Multi +Report", ["Position", "Hotkey"])
    lv.ModifyCol(1, 196)
    lv.ModifyCol(2, 80)

    btnAdd := g.Add("Button", "xm y+10 w146", "Add")
    btnRemove := g.Add("Button", "x+8 w146", "Remove")

    g.Add("Text", "xm y+10 w106", "Name")
    eName := g.Add("Edit", "x+18 yp-3 w176")
    g.Add("Text", "xm y+10 w106", "Hotkey")
    hPos := g.Add("Hotkey", "x+18 yp-3 w176")
    cbKeep := g.Add("CheckBox", "xm y+10 w300", "Keep the window's current size")

    ; --- Resize cycle ------------------------------------------------------------------------
    g.SetFont("s11 w600 c" th["header"], "Segoe UI")
    g.Add("Text", "xm y+24 w300", "Resize cycle")
    g.SetFont("s9 w400 c" th["hint"], "Segoe UI")
    g.Add("Text", "xm y+2 w300", "One key, cycling these sizes. It also re-centres the window.")
    g.SetFont("s10 w400 c" th["text"], "Segoe UI")

    g.Add("Text", "xm y+20 w106", "Hotkey")
    hResize := g.Add("Hotkey", "x+18 yp-3 w176")

    edits := []
    loop 3 {
        i := A_Index
        g.Add("Text", "xm y+10 w106", "Preset " i)
        ew := g.Add("Edit", "x+18 yp-3 w73 Number")
        ; The multiplication sign, not the letter x — this is a dimension, not a form field.
        g.SetFont("s10 w400 c" th["hint"], "Segoe UI")
        g.Add("Text", "x+6 yp+3 w18 Center", "×")
        g.SetFont("s10 w400 c" th["text"], "Segoe UI")
        eh := g.Add("Edit", "x+6 yp-3 w73 Number")
        edits.Push({ w: ew, h: eh })
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

    ; --- the model <-> controls wiring ---------------------------------------------------------

    _RowText(i) {
        lv.Modify(i, "Col1", _PositionLabel(positions[i], i))
        lv.Modify(i, "Col2", positions[i].hotkey != "" ? positions[i].hotkey : "not set")
    }

    _RebuildList() {
        lv.Delete()
        for i, p in positions
            lv.Add(, _PositionLabel(p, i), p.hotkey != "" ? p.hotkey : "not set")
    }

    ; Fills the per-row controls FROM the model. Never the other way round.
    _ShowRow(i) {
        loading := true
        sel := i
        if (i < 1 || i > positions.Length) {
            eName.Value := "", hPos.Value := "", cbKeep.Value := 0
            eName.Enabled := false, hPos.Enabled := false, cbKeep.Enabled := false
            ScreenPictureSet({ ax: 50, ay: 50, w: 0, h: 0 }, false)
            loading := false
            return
        }
        p := positions[i]
        eName.Enabled := true, hPos.Enabled := true, cbKeep.Enabled := true
        eName.Value := p.name
        hPos.Value := p.hotkey
        cbKeep.Value := (p.w = 0 && p.h = 0) ? 1 : 0
        ScreenPictureSet(p, true)
        loading := false
    }

    ; The picture edits the SELECTED row LIVE. No Apply button: Save commits the whole list,
    ; Close discards it, Reset repopulates from defaults without touching the INI.
    _OnPictureDrag(pos) {
        if (loading || sel < 1 || sel > positions.Length)
            return
        p := positions[sel]
        p.ax := pos.ax, p.ay := pos.ay, p.w := pos.w, p.h := pos.h
        ; Dragging an edge gives the position a real size, so the checkbox has to follow. It is
        ; a view of w/h, not a separate piece of state.
        cbKeep.Value := (p.w = 0 && p.h = 0) ? 1 : 0
    }

    _OnNameChange(*) {
        if (loading || sel < 1 || sel > positions.Length)
            return
        positions[sel].name := eName.Value
        _RowText(sel)
    }

    _OnHotkeyChange(*) {
        if (loading || sel < 1 || sel > positions.Length)
            return
        v := PreserveHotkey(hPos.Value, positions[sel].hotkey)
        ; ⛔ Filling the control FIRES this handler, and the control re-renders what it was
        ; given — it is handed ^+c and reads back +^c. Writing that back rewrote the stored
        ; value just because a row was selected, and on Save it would rewrite the user's INI.
        ; The `loading` flag cannot prevent it: the notification is delivered from the message
        ; loop AFTER the flag has been cleared. So compare what the two values MEAN.
        if (NormalizeHotkeyName(v) = NormalizeHotkeyName(positions[sel].hotkey))
            return
        positions[sel].hotkey := v
        _RowText(sel)
    }

    _OnKeepChange(*) {
        if (loading || sel < 1 || sel > positions.Length)
            return
        p := positions[sel]
        if (cbKeep.Value) {
            p.w := 0, p.h := 0
        } else {
            ; Unchecking needs a real size, and it must be the size the box is ALREADY drawn at
            ; or the box jumps under the user's eyes the instant they tick the box.
            p.w := SP_KEEP_W, p.h := SP_KEEP_H
        }
        ScreenPictureSet(p, true)
    }

    _OnSelect(*) {
        if (loading)
            return
        r := lv.GetNext()
        if (r > 0)
            _ShowRow(r)
    }

    _Add(*) {
        if (positions.Length >= MAX_POSITIONS) {
            MsgBox("You can have up to " MAX_POSITIONS " positions.`n`nEach one is a "
                 . "system-wide hotkey, and a settings window that scrolls has become a page."
                 , APP_TITLE, "Icon!")
            return
        }
        ; A new position starts where a new position should: centred, keeping the window's own
        ; size, and UNBOUND. Choosing a hotkey for the user would claim a key system-wide that
        ; they never asked for.
        positions.Push({ name: "Position " (positions.Length + 1), hotkey: ""
                       , ax: 50, ay: 50, w: 0, h: 0 })
        _RebuildList()
        lv.Modify(positions.Length, "Select Focus")
        _ShowRow(positions.Length)
        eName.Focus()
    }

    _Remove(*) {
        if (sel < 1 || sel > positions.Length)
            return
        ; The last position cannot be removed. An empty list is a working app with no way back
        ; into it except the tray, and the migration path guarantees at least Center exists.
        if (positions.Length = 1) {
            MsgBox("There has to be at least one position.", APP_TITLE, "Icon!")
            return
        }
        positions.RemoveAt(sel)
        _RebuildList()
        next := Min(sel, positions.Length)
        lv.Modify(next, "Select Focus")
        _ShowRow(next)
    }

    ; The ONE place controls are filled from settings — first open, re-open, and Reset.
    _Populate(st) {
        loading := true
        ; Copied, not aliased: these objects are the ones main.ahk is holding in SETTINGS, and
        ; an edit here that is abandoned with Close must not already have changed them.
        positions := []
        for p in st["positions"]
            positions.Push({ name: p.name, hotkey: p.hotkey
                           , ax: p.ax, ay: p.ay, w: p.w, h: p.h })
        loadedResize := st["resizeHotkey"]
        hResize.Value := loadedResize
        loop 3 {
            edits[A_Index].w.Value := st["sizes"][A_Index].w
            edits[A_Index].h.Value := st["sizes"][A_Index].h
        }
        _RebuildList()
        loading := false
        if (positions.Length >= 1) {
            lv.Modify(1, "Select Focus")
            _ShowRow(1)
        } else {
            _ShowRow(0)
        }
    }

    ; Reset fills the CONTROLS from the defaults and stops there. It must not touch the INI:
    ; a reset the user cannot back out of is worse than no reset at all. They review what
    ; appeared and press Save to commit it, or Close to walk away.
    ;
    ; It now resets the POSITIONS LIST too. While the list was invisible, resetting it would
    ; have deleted the user's positions with nothing on screen to say it happened; now that the
    ; list is right there, leaving it out would be the surprising half.
    _ResetControls(*) {
        _Populate(SettingsDefaults())
    }

    _Save(*) {
        r := PreserveHotkey(hResize.Value, loadedResize)
        ; The Hotkey control cannot emit malformed syntax, but it CAN emit a bare single
        ; character — which registers a system-wide key swallower — and the INI is
        ; hand-editable, so a preserved value can be anything. The guard stays.
        if !IsValidHotkey(r) {
            MsgBox("'" r "' is not a valid hotkey.", APP_TITLE, "Icon!")
            return
        }
        for i, p in positions {
            if (p.hotkey != "" && !IsValidHotkey(p.hotkey)) {
                MsgBox("'" p.hotkey "' is not a valid hotkey, on " _PositionLabel(p, i) "."
                     , APP_TITLE, "Icon!")
                return
            }
        }
        ; Two rows on one key means AHK's second registration silently REPLACES the first, so
        ; one of the things the user just typed would never happen and nothing would say so.
        ; The running app drops the duplicate; this window refuses it, which is the difference
        ; between surviving a mistake and hiding one.
        c := FindHotkeyConflict(r, positions)
        if (c != "") {
            first := (c.firstKind = "resize")
                ? "the resize cycle"
                : _PositionLabel(positions[c.firstIndex], c.firstIndex)
            MsgBox("'" c.key "' is already used by " first ".`n`nTwo actions can't share a "
                 . "hotkey — only one of them would ever run."
                 , APP_TITLE, "Icon!")
            return
        }

        out := SettingsDefaults()
        out["positions"] := []
        for i, p in positions
            out["positions"].Push({ name: _PositionLabel(p, i), hotkey: p.hotkey
                                  , ax: p.ax, ay: p.ay, w: p.w, h: p.h })
        ; [Hotkeys] Center is no longer read for anything but migration, and it is written only
        ; so that DOWNGRADING to 2.2.0 still finds the key it expects. Position 1 is the closest
        ; thing to the old Center action, so that is what it carries.
        out["centerHotkey"] := (out["positions"].Length >= 1 && out["positions"][1].hotkey != "")
            ? out["positions"][1].hotkey
            : SettingsDefaults()["centerHotkey"]
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
        loadedResize := r
        loop 3 {
            edits[A_Index].w.Value := sizes[A_Index].w   ; reflect clamping back to the user
            edits[A_Index].h.Value := sizes[A_Index].h
        }
        onSaved(out)
        g.Hide()
    }

    lv.OnEvent("ItemSelect", _OnSelect)
    eName.OnEvent("Change", _OnNameChange)
    hPos.OnEvent("Change", _OnHotkeyChange)
    cbKeep.OnEvent("Click", _OnKeepChange)
    btnAdd.OnEvent("Click", _Add)
    btnRemove.OnEvent("Click", _Remove)
    btnSave.OnEvent("Click", _Save)
    btnReset.OnEvent("Click", _ResetControls)
    btnClose.OnEvent("Click", (*) => g.Hide())
    g.OnEvent("Close", (*) => g.Hide())
    g.OnEvent("Escape", (*) => g.Hide())

    _settingsGui := g
    _settingsPopulate := _Populate
    _Populate(s)
    ; Focus must not start in a Hotkey control: it captures every keystroke (that is its whole
    ; purpose — building a key combination from whatever you press) including Tab, so the user
    ; could not type or even tab away without reaching for the mouse. Save is safe on both
    ; counts — Enter commits what is already on screen, Escape still closes, Tab cycles
    ; normally, and nothing swallows input.
    btnSave.Focus()
    g.Show()
    ; Only now can anything be measured: before Show the window has a size but no position.
    ScreenPictureRelayout()
}
