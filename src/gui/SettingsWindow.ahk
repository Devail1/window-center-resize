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
; The ONE routine that sizes the window. Exposed for the same reason as _settingsPopulate:
; the reopen branch is outside the closure and must not invent a second way to do it.
global _settingsShowFitted := ""
; Set for as long as the window is being built or re-shown. See ShowSettingsWindow.
global _settingsBuilding := false

; The tallest the window may be. 0 means "as much of the monitor's work area as is decent", which
; is what ships; a test sets it to a small number to force the overflow case on a screen that is
; nowhere near small enough to produce it naturally.
;
; Why there is a limit at all: the window sizes itself to its content, and the content grows with
; the positions list — 695px for one, and 26px per row after that, so eight positions want 877px.
; That fits a 1080p work area and does NOT fit a 768px laptop. With no sizing border to drag and
; nothing scrolling, a window taller than the screen is a dead end, which is exactly the trap the
; F9-on-our-own-window bug turned out to be.
global SETTINGS_MAX_HEIGHT := 0
global SETTINGS_SCREEN_MARGIN := 24     ; left around the window when it has to be clamped

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

; ⛔ RE-ENTRANCY GUARD, and it is load-bearing. Building this window YIELDS to the message
; queue — ScreenPictureCreate's _spBox.Show() pumps WM_SIZE into _SpFitFill, and _Reflow moves
; controls — so a second tray activation (the tray icon's DEFAULT item fires on a double-click)
; arrives mid-construction. The single-instance check below cannot stop it: _settingsGui is not
; assigned until the very end of the build, ~490 lines later, so the second call also takes the
; "first" branch and builds a SECOND window. Both then share ScreenPicture's module-level
; globals, the second construction overwrites them, and the first window's picture is never laid
; out — it shows as a blank rectangle with no draggable box. Measured 2026-09-13: two "first"
; branch entries on every double-click, and two live windows on screen.
;
; Nothing is thrown, so this is invisible to every error path. Dropping the second activation is
; the whole fix: the window is already on its way up.
ShowSettingsWindow(iniPath, onSaved) {
    global _settingsBuilding
    if (_settingsBuilding)
        return
    _settingsBuilding := true
    ; finally, not a trailing assignment: _UncaughtAppError swallows anything that escapes, and
    ; a flag left set would make the Settings item dead for the rest of the session.
    try
        _BuildSettingsWindow(iniPath, onSaved)
    finally
        _settingsBuilding := false
}

_BuildSettingsWindow(iniPath, onSaved) {
    global _settingsGui, _settingsPopulate, _settingsShowFitted
    if (_settingsGui != "") {          ; single instance
        ; Re-opening must RELOAD from settings. Closing without saving used to leave the
        ; abandoned edit sitting in the box — contradicting the live binding, and committed
        ; by the next Save. Same populate routine as first open, not a second code path.
        _settingsPopulate(SettingsLoad(iniPath))
        ; ⛔ NOT _settingsGui.Show(). A bare Show() AUTO-SIZES from the controls' declared
        ; positions, which throws away every move _Reflow made and ignores the screen-height
        ; clamp - the same trap _Reflow's own comment warns about.
        _settingsShowFitted()
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

    ; +0x00200000 is WS_VSCROLL. The style has to exist for ShowScrollBar to be able to
    ; reveal it; it is hidden immediately unless the content actually overflows.
    ; +Resize is all a sizing border costs. What AutoHotkey does NOT do is move or stretch a
    ; single control when the window changes size - there is no layout manager - so the Size
    ; handler below does that, and 0x00200000 (WS_VSCROLL) covers the case where the content
    ; is taller than the window however it got that way.
    ; MinSize stops the column being dragged down to a width the controls cannot express.
    g := Gui("-MaximizeBox -MinimizeBox +Resize +MinSize332x220 +0x00200000", APP_TITLE)
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
    txtReadout := g.Add("Text", "xm y+8 w198", "")
    txtScreen  := g.Add("Text", "x+0 yp w102 Right", "")
    g.SetFont("s10 w400 c" th["text"], "Segoe UI")
    ; ⛔ Without this there is no way to give a keep-current-size position a size, and a
    ; keep-size position cannot be resized BY DESIGN — its edges are all caption, because "keep
    ; the size it has" is exactly what having no size to drag means. Dropping the checkbox
    ; therefore did not remove an option, it removed the resize handles from the position every
    ; user starts with, with nothing on screen to explain why the edges did nothing.
    ; The label says what TICKING IT DOES, not what gets stored. "Keep the window's current
    ; size" describes a state and left it unclear that ticking it also makes the box in the
    ; picture unresizable — which is how the shipped Centre position behaves, so it is the first
    ; thing a new user meets and the first thing they read as broken.
    cbKeep := g.Add("CheckBox", "xm y+6 w300", "Move only — don't change the window's size")

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

    ; Reset repopulates every field from defaults and cannot be undone once it runs, so it sits
    ; at the far left, as far from the commit button as the dialog allows. Save is rightmost
    ; because Windows places the primary action there, and `Default` makes it the accent-filled
    ; button Windows 11 draws for the default push button.
    ;
    ; There is no Close button. The title bar's X already does exactly what it did — discard and
    ; hide — and so does Escape, so a third control for it was a row of chrome restating what
    ; the window frame already offers. 300 content, 88 wide, so Save starts at 300 - 88 = 212.
    btnReset := _A("Button", "xm y+24 w88", "Reset")
    btnSave  := _A("Button", "xm+212 yp w88 Default", "Save")

    ; --- the model <-> controls wiring ---------------------------------------------------------

    ; Moves everything below the rows so hidden rows leave no hole, and resizes the window to
    ; match. Tracked as a delta from the last layout rather than recomputed from scratch: the
    ; controls' own positions are the source of truth, so nothing here has to know the design.
    ; The layout was BUILT with every row visible, so that is the baseline the first reflow
    ; measures its delta from.
    shownRows := MAX_POSITIONS
    shown := false
    ; Scroll offset in pixels, and how far it may go. Both stay 0 whenever the content fits,
    ; which is every normal screen - the scrollbar is not even shown then.
    scrollY := 0
    scrollMax := 0
    sizing := false                              ; see _OnSize
    ; The width every control was positioned against; the scale factor's denominator.
    BASE_W := 300
    layout := []
    ; How much taller than its designed height the picture slot currently is. Tracked as a
    ; running total and applied as a DELTA, because _Reflow also moves these controls when rows
    ; are hidden - recomputing absolute positions from a captured table would undo that.
    slotExtra := 0
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
            _ShowFitted("NoActivate")
    }

    ; The height the LAYOUT wants, measured from the last control rather than left to AutoSize.
    ; ⛔ Scroll is reset to the top first: btnSave's position IS the measurement, so measuring a
    ; scrolled window reports it short by exactly the scroll offset, and clamping to that gives a
    ; window that shrinks a little more every time the list changes.
    _WantHeight() {
        _ScrollTo(0)
        btnSave.GetPos(, &sy, , &sh)
        return sy + sh + g.MarginY
    }

    ; The tallest this window may be on this monitor. The override exists so a test can force the
    ; overflow case; no screen here is short enough to produce it with the 8-position cap.
    _MaxHeight() {
        if (SETTINGS_MAX_HEIGHT > 0)
            return SETTINGS_MAX_HEIGHT
        wa := GetNearestMonitorWorkArea(g.Hwnd)
        return wa.height - SETTINGS_SCREEN_MARGIN
    }

    ; Sizes the window to its content, or to the screen when the content is taller, and gives the
    ; scrollbar exactly the difference to cover.
    _ShowFitted(opts := "") {
        want := _WantHeight()
        h := Min(want, _MaxHeight())
        scrollMax := Max(0, want - h)
        _SyncScrollBar()
        g.Show("w332 h" h (opts != "" ? " " opts : ""))
    }

    _SyncScrollBar() {
        static SB_VERT := 1, SIF_RANGE := 0x1, SIF_PAGE := 0x2, SIF_POS := 0x4
        si := Buffer(28, 0)
        NumPut("uint", 28, si, 0)
        NumPut("uint", SIF_RANGE | SIF_PAGE | SIF_POS, si, 4)
        NumPut("int", 0, si, 8)                      ; nMin
        NumPut("int", scrollMax, si, 12)             ; nMax
        NumPut("uint", 1, si, 16)                    ; nPage: 1, so nMax IS the last position
        NumPut("int", scrollY, si, 20)               ; nPos
        DllCall("SetScrollInfo", "ptr", g.Hwnd, "int", SB_VERT, "ptr", si, "int", true)
        ; Hidden entirely when the window fits, rather than shown greyed out. A dead scrollbar on
        ; a window that does not scroll is a claim that there is more to see.
        DllCall("ShowScrollBar", "ptr", g.Hwnd, "int", SB_VERT, "int", scrollMax > 0)
    }

    _ScrollTo(y) {
        y := Max(0, Min(y, scrollMax))
        if (y = scrollY)
            return
        dy := scrollY - y                            ; scrolling down moves content UP
        scrollY := y
        ; ⛔ SW_SCROLLCHILDREN is the whole reason this is three lines instead of a rewrite: it
        ; moves the CHILD WINDOWS too, which carries the picture's three layers and the draggable
        ; box (itself a child Gui) along with the ordinary controls. Moving them by hand would
        ; mean teaching this function ScreenPicture's internals, and ScreenPicture measures
        ; everything live, so it needs no telling.
        static SW_SCROLLCHILDREN := 0x0001, SW_INVALIDATE := 0x0002, SW_ERASE := 0x0004
        DllCall("ScrollWindowEx", "ptr", g.Hwnd, "int", 0, "int", dy
              , "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0
              , "uint", SW_SCROLLCHILDREN | SW_INVALIDATE | SW_ERASE)
        _SyncScrollBar()
    }

    ; The flag guards against RE-ENTRY. This handler moves and resizes windows, and showing or
    ; hiding a scrollbar changes the client area - both of which can put another WM_SIZE in front
    ; of the one being handled. Cheap insurance against laying out on top of a layout.
    ;
    ; ⚠️ PRECAUTIONARY, not a fix for anything observed. No re-entrant WM_SIZE has been measured
    ; here. It is kept because the cost is a boolean and the failure it prevents is a layout
    ; computed from half-applied positions, which would be very hard to recognise as such.
    _OnSize(guiObj, minMax, w, h) {
        if (minMax = -1)                         ; minimised: there is nothing to lay out
            return
        if (sizing)
            return
        sizing := true
        try
            _DoSize(w, h)
        finally
            sizing := false
    }

    _DoSize(w, h) {
        _Restretch(w)
        _GrowPicture(h)
        ; The picture is letterboxed into the slot, and the slot just changed shape.
        ScreenPictureRelayout()
        _SyncScrollForHeight(h)
    }

    ; Width only. Heights stay as designed - a taller window shows more of the content, it does
    ; not stretch the rows, and that is what the scrollbar is for.
    _Restretch(clientW) {
        avail := clientW - g.MarginX * 2
        if (avail < 80 || layout.Length = 0)
            return
        scale := avail / BASE_W
        for e in layout
            e.c.Move(g.MarginX + Round(e.dx * scale), , Round(e.w * scale))
    }

    ; Spare height goes to the PICTURE, which is the only control here worth making bigger - it is
    ; what the user is aiming with. Everything else keeps its designed height, so a taller window
    ; means a bigger picture rather than stretched text boxes.
    _GrowPicture(clientH) {
        btnSave.GetPos(, &sy, , &sh)
        ; Content as it stands, minus the growth already applied: the height it would want if the
        ; picture were its designed size.
        natural := sy + sh + g.MarginY + scrollY - slotExtra
        delta := Max(0, clientH - natural) - slotExtra
        if (delta = 0)
            return
        slotExtra += delta
        _spSlot.GetPos(, &slotY, , &slotH)
        _spSlot.Move(, , , slotH + delta)
        ; Everything below the picture moves with it. Measured against the slot's OLD bottom, so
        ; this composes with wherever _Reflow has already put things.
        bottom := slotY + slotH
        for hwnd, c in g {
            if (c.Hwnd = _spSlot.Hwnd || c.Hwnd = _spPic.Hwnd || c.Hwnd = _spTask.Hwnd)
                continue
            c.GetPos(, &cy)
            if (cy >= bottom)
                c.Move(, cy + delta)
        }
    }

    ; After a resize the window height is the USER'S, not ours, so the scroll range is recomputed
    ; against it rather than the window being re-shown at a height of our choosing.
    _SyncScrollForHeight(clientH) {
        btnSave.GetPos(, &sy, , &sh)
        content := sy + sh + g.MarginY + scrollY  ; + scrollY: control positions are already scrolled
        scrollMax := Max(0, content - clientH)
        if (scrollY > scrollMax)                 ; the window grew past what was scrolled away
            _ScrollTo(scrollMax)
        _SyncScrollBar()
    }

    _OnVScroll(wParam, lParam, msg, hwnd) {
        if (hwnd != g.Hwnd || scrollMax = 0)
            return
        static SB_LINEUP := 0, SB_LINEDOWN := 1, SB_PAGEUP := 2, SB_PAGEDOWN := 3
             , SB_THUMBPOSITION := 4, SB_THUMBTRACK := 5
        code := wParam & 0xFFFF
        if (code = SB_LINEUP)
            _ScrollTo(scrollY - ROW_H)
        else if (code = SB_LINEDOWN)
            _ScrollTo(scrollY + ROW_H)
        else if (code = SB_PAGEUP)
            _ScrollTo(scrollY - ROW_H * 4)
        else if (code = SB_PAGEDOWN)
            _ScrollTo(scrollY + ROW_H * 4)
        else if (code = SB_THUMBPOSITION || code = SB_THUMBTRACK)
            _ScrollTo((wParam >> 16) & 0xFFFF)
        return 0
    }

    _OnWheel(wParam, lParam, msg, hwnd) {
        static GA_ROOT := 2
        if (scrollMax = 0)
            return
        ; The wheel is delivered to whatever is under the cursor, which is usually a control and
        ; can be the box - so the window is identified by its ROOT, not by hwnd itself.
        if (DllCall("GetAncestor", "ptr", hwnd, "uint", GA_ROOT, "ptr") != g.Hwnd)
            return
        delta := (wParam >> 16) & 0xFFFF
        if (delta > 32767)
            delta -= 65536                           ; WM_MOUSEWHEEL's delta is SIGNED
        _ScrollTo(scrollY - Round(delta / 120) * ROW_H * 2)
        return 0
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
        ; Kept short on purpose: the widest it can get is "size 100x100%  at 100,100%", which
        ; is what the control is sized for. The longer phrasing truncated at "at 0," and a
        ; readout that silently loses half the numbers is worse than no readout.
        txtReadout.Value := (p.w = 0 && p.h = 0)
            ? "same size  at " p.ax "," p.ay "%"
            : "size " p.w "x" p.h "%  at " p.ax "," p.ay "%"
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

    _OnBackgroundClick(wParam, lParam, msg, hwnd) {
        if (hwnd != g.Hwnd)
            return
        DllCall("SetFocus", "ptr", g.Hwnd)
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
        ; ⛔ The window deliberately STAYS OPEN. Saving used to hide it, which suited a dialog of
        ; two fields and suits a list editor badly: the common move is to save and carry on
        ; adding. Hiding also made Save the only tidy way out, which is why a Close button
        ; existed at all.
        ;
        ; Something still has to confirm the save happened, or it reads as a dead button. The
        ; button says so itself and puts its own label back, which needs no extra control and no
        ; space in a window whose height is already the thing being defended.
        btnSave.Text := "Saved"
        SetTimer(() => btnSave.Text := "Save", -1400)
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
    ; Clicking empty space lets go of whatever field has focus.
    ;
    ; This matters more here than in most dialogs: a focused Hotkey control captures EVERY
    ; keystroke, including Tab, so without somewhere to click there is no way out of one but
    ; another control. Win32 does not move focus when you click a window's background, so it is
    ; moved deliberately — to the dialog itself, which leaves Tab and Escape working normally.
    ;
    ; Only the Gui's own background arrives here. The screen picture reaches it too, because its
    ; controls are disabled and hand their mouse messages up to the parent.
    OnMessage(0x0201, _OnBackgroundClick)          ; WM_LBUTTONDOWN
    OnMessage(0x0115, _OnVScroll)                  ; WM_VSCROLL
    OnMessage(0x020A, _OnWheel)                    ; WM_MOUSEWHEEL
    cbKeep.OnEvent("Click", _OnKeepChange)
    btnAdd.OnEvent("Click", _Add)
    btnSave.OnEvent("Click", _Save)
    btnReset.OnEvent("Click", _ResetControls)
    g.OnEvent("Close", (*) => g.Hide())
    g.OnEvent("Escape", (*) => g.Hide())

    ; The layout is captured ONCE, at the width everything was designed against, as an offset and
    ; a width per control. Resizing then maps that table through a single scale factor, so a
    ; control added later is carried along without this handler being taught about it.
    ;
    ; ⛔ The picture's fill and taskbar layers are skipped: ScreenPictureRelayout owns those and
    ; positions them by MEASURING the slot, so stretching them here would be two pieces of code
    ; moving the same windows and disagreeing.
    for hwnd, c in g {
        if (c.Hwnd = _spPic.Hwnd || c.Hwnd = _spTask.Hwnd)
            continue
        c.GetPos(&cx, , &cw)
        layout.Push({ c: c, dx: cx - g.MarginX, w: cw })
    }
    g.OnEvent("Size", _OnSize)

    _settingsGui := g
    _settingsPopulate := _Populate
    _settingsShowFitted := _ShowFitted
    _Populate(s)
    ; Focus must not start in a Hotkey control: it captures every keystroke (that is its whole
    ; purpose — building a key combination from whatever you press) including Tab, so the user
    ; could not type or even tab away without reaching for the mouse. Save is safe on both
    ; counts — Enter commits what is already on screen, Escape still closes, Tab cycles
    ; normally, and nothing swallows input.
    btnSave.Focus()
    shown := true
    _ShowFitted()
    ; Only now can anything be measured: before Show the window has a size but no position.
    ScreenPictureRelayout()
}
