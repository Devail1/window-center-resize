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
    g.Add("Text", "xm y+2 w300", "Drag the window where you want it. Give it a name and a key.")
    g.SetFont("s10 w400 c" th["text"], "Segoe UI")

    ; Spacing ladder, each distinguishable from its neighbour: 2 (header->subtitle) /
    ; 10 (row->row) / 20 (subtitle->first row) / 24 (section->section). The subtitle sat only
    ; 2px further from the first row than the rows sit from each other, so it read as another
    ; form row instead of a caption under the bold header. Do not collapse this to a constant.
    g.Add("Text", "xm y+20 w300 h0")        ; the picture is added by ScreenPictureCreate
    ScreenPictureCreate(g, th["hint"], th["screen"], th["taskbar"], th["accent"], th["fill"]
                     , _OnPictureDrag)

    ; The numbers behind the drag. A picture is the fastest way to AIM and a hopeless way to
    ; read back exactly what you aimed at, and these are the values that reach settings.ini.
    g.SetFont("s9 w400 c" th["hint"], "Consolas")
    txtReadout := g.Add("Text", "xm y+8 w186", "")
    txtScreen  := g.Add("Text", "x+0 yp w114 Right", "")
    g.SetFont("s10 w400 c" th["text"], "Segoe UI")
    ; ⛔ Without this there is no way to give a keep-current-size position a size, and a
    ; keep-size position cannot be resized BY DESIGN — its edges are all caption, because "keep
    ; the size it has" is exactly what having no size to drag means. Dropping the checkbox
    ; therefore did not remove an option, it removed the resize handles from the position every
    ; user starts with, with nothing on screen to explain why the edges did nothing.
    cbKeep := g.Add("CheckBox", "xm y+6 w300", "Keep the window's current size")

    ; One row per position, edited in place. There is no separate "selected row" panel: the row
    ; IS the panel, which is a whole block of controls this window does not have to carry.
    ;
    ; All MAX_POSITIONS rows are created up front and the unused ones hidden, because AutoHotkey
    ; cannot destroy a single control — only the whole window. _Reflow then moves everything
    ; below them so hidden rows do not leave a hole.
    rows := []
    loop MAX_POSITIONS {
        i := A_Index
        yOpt := (i = 1) ? "xm y+10" : "xm y+4"
        ; The swatch is the selection indicator. A border around the row would need custom
        ; painting; a filled square does the same job with a colour.
        ; A Text, not a Progress: Progress has no Click event, so the swatch could be drawn
        ; but never used to select its row.
        sw := g.Add("Text", yOpt " w22 h22 Background" th["hint"])
        nm := g.Add("Edit", "x+6 yp-1 w120")
        hk := g.Add("Hotkey", "x+6 yp w118")
        dl := g.Add("Button", "x+6 yp-1 w22 h24", "x")
        rows.Push({ swatch: sw, name: nm, hotkey: hk, del: dl })
    }

    ; ⛔ MEASURED, not declared. The reflow shifts everything below by (rows removed) x pitch,
    ; and a pitch guessed at 30 against a real 26 put the last row on top of the Add button.
    ; The controls' own geometry is the only thing that cannot drift out of step with itself.
    rows[1].swatch.GetPos(, &r1y)
    rows[2].swatch.GetPos(, &r2y)
    ROW_H := r2y - r1y

    btnAdd := g.Add("Button", "xm y+8 w300", "+ Add position")

    ; Everything from here down has to move when the number of rows changes. Collected as it is
    ; created rather than looked up later: the control list is the one thing that cannot drift
    ; out of step with the layout.
    below := [btnAdd]
    _A(type, opts, text := "") {
        c := g.Add(type, opts, text)
        below.Push(c)
        return c
    }

    ; --- Resize cycle ------------------------------------------------------------------------
    g.SetFont("s11 w600 c" th["header"], "Segoe UI")
    _A("Text", "xm y+24 w300", "Size")
    g.SetFont("s9 w400 c" th["hint"], "Segoe UI")
    ; ⛔ NOT "cycles these without moving the window" — the mock says that and it is wrong. F9
    ; sizes AND re-centres, unchanged since 2.2.0, and that is a settled decision rather than an
    ; oversight. A subtitle that denies it would be the only place in the app that lies.
    _A("Text", "xm y+2 w300", "A separate key, cycling these sizes. It re-centres too.")
    g.SetFont("s10 w400 c" th["text"], "Segoe UI")

    _A("Text", "xm y+20 w106", "Resize")
    hResize := _A("Hotkey", "x+18 yp-3 w176")

    edits := []
    loop 3 {
        i := A_Index
        _A("Text", "xm y+10 w106", "Preset " i)
        ew := _A("Edit", "x+18 yp-3 w73 Number")
        ; The multiplication sign, not the letter x — this is a dimension, not a form field.
        g.SetFont("s10 w400 c" th["hint"], "Segoe UI")
        _A("Text", "x+6 yp+3 w18 Center", "×")
        g.SetFont("s10 w400 c" th["text"], "Segoe UI")
        eh := _A("Edit", "x+6 yp-3 w73 Number")
        edits.Push({ w: ew, h: eh })
    }

    ; Reset repopulates every field from defaults and cannot be undone by the user once it
    ; runs, so it must not sit adjacent to the commit pair where a misclick lands on it
    ; instead of Close or Save. It gets its own position at the left margin; Close and Save
    ; stay right-aligned as a pair, with Save last since Windows places the primary action
    ; rightmost, and `Default` makes it the accent-filled button Windows 11 draws for the
    ; default push button.
    ; 300 content, right-hand pair = 88 + 8 + 88 = 184, so the pair starts at 300 - 184 = 116.
    btnReset := _A("Button", "xm y+24 w88", "Reset")
    btnClose := _A("Button", "xm+116 yp w88", "Close")
    btnSave  := _A("Button", "x+8 w88 Default", "Save")

    ; --- the model <-> controls wiring ---------------------------------------------------------

    ; Moves everything below the rows so hidden rows leave no hole, and resizes the window to
    ; match. Tracked as a delta from the last layout rather than recomputed from scratch: the
    ; controls' own positions are the source of truth, so nothing here has to know the design.
    ; The layout was BUILT with every row visible, so that is the baseline the first reflow
    ; measures its delta from.
    shownRows := MAX_POSITIONS
    shown := false
    _Reflow(n) {
        if (n = shownRows)
            return
        delta := (n - shownRows) * ROW_H
        shownRows := n
        loop MAX_POSITIONS {
            vis := (A_Index <= n)
            for _, c in [rows[A_Index].swatch, rows[A_Index].name
                       , rows[A_Index].hotkey, rows[A_Index].del]
                c.Visible := vis
        }
        for c in below {
            c.GetPos(&cx, &cy)
            c.Move(cx, cy + delta)
        }
        ; The height is computed from the LAST control rather than left to AutoSize. AutoSize
        ; re-runs the layout from the controls' declared positions and would undo every move
        ; above; it also has no reason to exclude the rows that were just hidden.
        if (shown)
            g.Show("w332 h" _WantHeight() " NoActivate")
    }

    _WantHeight() {
        btnSave.GetPos(, &sy, , &sh)
        return sy + sh + g.MarginY
    }

    _Swatches() {
        loop MAX_POSITIONS
            rows[A_Index].swatch.Opt("+Background"
                . ((A_Index = sel) ? th["accent"] : th["hint"]))
    }

    _Readout() {
        ; The MONITOR's size, because the monitor is what the picture draws — the strip along
        ; the bottom is the taskbar, and the part above it is the work area a position lives in.
        wa := GetNearestMonitorWorkArea(g.Hwnd)
        txtScreen.Value := wa.monWidth " x " wa.monHeight
        if (sel < 1 || sel > positions.Length) {
            txtReadout.Value := ""
            return
        }
        p := positions[sel]
        txtReadout.Value := (p.w = 0 && p.h = 0)
            ? "same size  ·  at " p.ax ", " p.ay " %"
            : "size " p.w " x " p.h " %  ·  at " p.ax ", " p.ay " %"
    }

    ; Fills the per-row controls FROM the model. Never the other way round.
    _ShowRow(i) {
        loading := true
        sel := i
        _Swatches()
        if (i >= 1 && i <= positions.Length) {
            cbKeep.Value := (positions[i].w = 0 && positions[i].h = 0) ? 1 : 0
            cbKeep.Enabled := true
            ScreenPictureSet(positions[i], true)
        } else {
            cbKeep.Value := 0
            cbKeep.Enabled := false
            ScreenPictureSet({ ax: 50, ay: 50, w: 0, h: 0 }, false)
        }
        _Readout()
        loading := false
    }

    _RefreshRows() {
        loading := true
        for i, p in positions {
            rows[i].name.Value := p.name
            rows[i].hotkey.Value := p.hotkey
        }
        _Reflow(positions.Length)
        loading := false
    }

    ; The picture edits the SELECTED row LIVE. No Apply button: Save commits the whole list,
    ; Close discards it, Reset repopulates from defaults without touching the INI.
    _OnPictureDrag(pos) {
        if (loading || sel < 1 || sel > positions.Length)
            return
        p := positions[sel]
        p.ax := pos.ax, p.ay := pos.ay, p.w := pos.w, p.h := pos.h
        ; Dragging an edge gives the position a real size, so the checkbox follows. It is a
        ; VIEW of w/h, never a separate piece of state that could disagree with them.
        cbKeep.Value := (p.w = 0 && p.h = 0) ? 1 : 0
        _Readout()
    }

    _OnKeepChange(*) {
        if (loading || sel < 1 || sel > positions.Length)
            return
        p := positions[sel]
        if (cbKeep.Value) {
            p.w := 0, p.h := 0
        } else {
            ; Unticking needs a real size, and it must be the size the box is ALREADY drawn at,
            ; or the box jumps under the user's eyes the instant they tick the box.
            p.w := SP_KEEP_W, p.h := SP_KEEP_H
        }
        ScreenPictureSet(p, true)
        _Readout()
    }

    _OnRowFocus(i) {
        if (loading || i = sel)
            return
        _ShowRow(i)
    }

    ; ⛔ NO `loading` GUARD HERE, and that is deliberate.
    ;
    ; The flag cannot protect a handler that carries DATA. _ShowRow calls into the picture,
    ; which redraws, which pumps the message queue — so Change notifications already queued get
    ; dispatched WHILE the flag is set, and their writes are dropped. Measured: typing into a
    ; row whose focus event was still in flight lost every keystroke, and the row saved under
    ; its old name with the new one still visible in the field.
    ;
    ; It does not need a guard. During a populate the control was just set FROM the model, so
    ; writing it back is a no-op. Anything else is the user typing, which is exactly what should
    ; be written.
    _OnRowName(i) {
        if (i > positions.Length)
            return
        positions[i].name := rows[i].name.Value
    }

    ; Same reasoning as _OnRowName: no `loading` guard, because the comparison below already
    ; makes a populate's echo a no-op and the flag cannot be trusted across a message pump.
    _OnRowHotkey(i) {
        if (i > positions.Length)
            return
        v := PreserveHotkey(rows[i].hotkey.Value, positions[i].hotkey)
        ; ⛔ Filling the control FIRES this handler, and the control re-renders what it was
        ; given — handed ^+c, it reads back +^c. Writing that back rewrote the stored value just
        ; because a row was populated, and on Save it would rewrite the user's INI. The
        ; `loading` flag cannot prevent it on its own: the notification is delivered from the
        ; message loop AFTER the flag has been cleared. So compare what the two values MEAN.
        if (NormalizeHotkeyName(v) = NormalizeHotkeyName(positions[i].hotkey))
            return
        positions[i].hotkey := v
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
        _RefreshRows()
        _ShowRow(positions.Length)
        rows[positions.Length].name.Focus()
    }

    _Remove(i) {
        if (i < 1 || i > positions.Length)
            return
        ; The last position cannot be removed. An empty list is a working app with no way back
        ; into it except the tray, and the migration path guarantees at least Center exists.
        if (positions.Length = 1) {
            MsgBox("There has to be at least one position.", APP_TITLE, "Icon!")
            return
        }
        positions.RemoveAt(i)
        _RefreshRows()
        _ShowRow(Min(i, positions.Length))
    }

    ; The ONE place controls are filled from settings — first open, re-open, and Reset.
    _Populate(st) {
        loading := true
        ; Copied, not aliased: these objects are the ones main.ahk is holding in SETTINGS, and
        ; an edit here that is abandoned with Close must not already have changed them.
        positions := []
        for p in st["positions"] {
            if (positions.Length >= MAX_POSITIONS)
                break
            positions.Push({ name: p.name, hotkey: p.hotkey
                           , ax: p.ax, ay: p.ay, w: p.w, h: p.h })
        }
        loadedResize := st["resizeHotkey"]
        hResize.Value := loadedResize
        loop 3 {
            edits[A_Index].w.Value := st["sizes"][A_Index].w
            edits[A_Index].h.Value := st["sizes"][A_Index].h
        }
        loading := false
        _RefreshRows()
        _ShowRow(positions.Length >= 1 ? 1 : 0)
    }

    ; Reset fills the CONTROLS from the defaults and stops there. It must not touch the INI:
    ; a reset the user cannot back out of is worse than no reset at all. They review what
    ; appeared and press Save to commit it, or Close to walk away.
    ;
    ; It now resets the POSITIONS LIST too. While the list was invisible, resetting it would
    ; have deleted the user's positions with nothing on screen to say it happened; now that the
    ; rows are right there, leaving them out would be the surprising half.
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

    ; ⛔ THE WIRING MUST HAPPEN IN A FUNCTION CALL, one per row.
    ;
    ; An AutoHotkey closure captures the VARIABLE, not its value. Written as a loop over
    ; `i := A_Index`, all MAX_POSITIONS closures share the single `i` and every one of them ends
    ; up pointing at the LAST index. Every keystroke, every delete and every focus then went to
    ; row 8 — which usually does not exist, so the range guard silently dropped it and nothing
    ; the user typed ever reached the model. Names and hotkeys came back empty from a save, the
    ; readout stayed blank, and add and remove appeared to do nothing.
    ;
    ; Each call to _WireRow has its OWN idx, so each closure captures a different variable.
    _WireRow(idx) {
        rows[idx].name.OnEvent("Focus",  (*) => _OnRowFocus(idx))
        rows[idx].name.OnEvent("Change", (*) => _OnRowName(idx))
        ; ⛔ A Hotkey control supports Change but NOT Focus — registering Focus on one throws
        ; at load. Typing into it is what selects its row instead, which is the moment the
        ; picture needs to be showing that row anyway.
        rows[idx].hotkey.OnEvent("Change", (*) => (_OnRowFocus(idx), _OnRowHotkey(idx)))
        rows[idx].swatch.OnEvent("Click", (*) => _OnRowFocus(idx))
        rows[idx].del.OnEvent("Click", (*) => _Remove(idx))
    }
    loop MAX_POSITIONS
        _WireRow(A_Index)
    cbKeep.OnEvent("Click", _OnKeepChange)
    btnAdd.OnEvent("Click", _Add)
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
    shown := true
    g.Show("w332 h" _WantHeight())
    ; Only now can anything be measured: before Show the window has a size but no position.
    ScreenPictureRelayout()
}
