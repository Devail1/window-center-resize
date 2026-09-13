#Requires AutoHotkey v2.0
#Include "..\lib\Geometry.ahk"
#Include "..\lib\Monitors.ahk"

; A picture of the user's screen with a draggable box in it — the whole of the positions
; editor's input. Everything here is Win32 plumbing; all the arithmetic lives in Geometry.ahk
; where the headless suite can reach it, because none of this can be tested without a display.
;
; Proven in tests\manual_editor_spike.ahk before being written here. Every comment below marked
; ⛔ records something that was MEASURED to break, not something that looked risky.

; The grids. Position and size deliberately do not share one: position wants to LAND on the few
; placements anyone means, size is a continuum whose useful values are not evenly spaced.
global SP_MOVE_STEP    := 2
global SP_SIZE_STEP    := 1
global SP_SIZE_MAGNETS := [25, 33, 50, 67, 75, 100]
global SP_MAGNET_PULL  := 2
; Matches ClampPercent's floor in Settings.ahk. A box that can be dragged smaller than the
; schema will store is a box that jumps when you let go of it.
global SP_MIN_PCT      := 10
; The grab zone for the edges. NOT the system frame metric: the box in the picture is small and
; the system's ~8px would be most of it.
global SP_GRAB_PX      := 7

global SP_SLOT_H := 170                  ; the letterbox slot's fixed height, in layout units

global _spGui := "", _spSlot := "", _spPic := "", _spBox := "", _spFill := ""
; The border thickness of the drawn window, in pixels. The box Gui paints the border colour and
; a single inset child paints the fill, which is the cheapest way to draw an outline without
; GDI+ — one extra window rather than four edge strips.
global SP_BORDER := 2
global _spPos := { ax: 50, ay: 50, w: 0, h: 0 }
global _spOnChange := ""
global _spEnabled := false
global _spGrab := { x: 0, y: 0, l: 0, t: 0, r: 0, b: 0 }
; What a "keep the window's current size" position is DRAWN at. It has no size of its own, and
; the picture still has to show something.
global SP_KEEP_W := 40, SP_KEEP_H := 55

; --- creation ---------------------------------------------------------------------------------

; Adds the slot, the picture and the box to `g` at the current layout cursor. Call
; ScreenPictureRelayout() after g.Show() — before the window is on screen it has a size but not
; yet a position, so nothing can be measured.
ScreenPictureCreate(g, slotColor, screenColor, boxColor, fillColor, onChange) {
    global _spGui, _spSlot, _spPic, _spBox, _spFill, _spOnChange
    _spGui := g, _spOnChange := onChange

    ; ⛔ WS_CLIPCHILDREN on the parent and WS_CLIPSIBLINGS on both Progress controls. Without
    ; them the picture PAINTS OVER the box: the box is positioned correctly and hit-tested
    ; correctly — clicks reach it — and is invisible except for whatever fragment was painted
    ; last. A drag mechanism working perfectly on a box you cannot see is indistinguishable
    ; from one that does not work.
    _SpAddStyle(g.Hwnd, 0x02000000)                       ; WS_CLIPCHILDREN

    _spSlot := g.Add("Progress", "xm w300 h" SP_SLOT_H " Background" slotColor, 0)
    _SpAddStyle(_spSlot.Hwnd, 0x04000000)                 ; WS_CLIPSIBLINGS

    ; ⛔ "xp yp wp hp" — exactly on top of the slot. It is moved to the letterboxed rectangle in
    ; Relayout, but it must be DECLARED at the slot's full size: AutoHotkey's layout cursor for
    ; every control added afterwards comes from the DECLARED rectangle, not the moved one.
    ; Declared small, the cursor stayed put and the rest of the window was laid out on top of
    ; the picture.
    _spPic := g.Add("Progress", "xp yp wp hp Background" screenColor, 0)
    _SpAddStyle(_spPic.Hwnd, 0x04000000)

    ; "+Resize" leaves WS_THICKFRAME on the box, which is what makes Windows honour the sizing
    ; hit-tests below. The frame itself is then removed in WM_NCCALCSIZE — see _SpNcCalcSize.
    _spBox := Gui("-Caption +Resize +Parent" g.Hwnd)
    ; The box must not be the SCREEN's colour. Painted the same, it is invisible against the
    ; picture and reads as "the whole screen is selected".
    _spBox.BackColor := boxColor
    _spFill := _spBox.Add("Progress", "x0 y0 w10 h10 Background" fillColor, 0)
    ; Without WS_CLIPCHILDREN the box repaints its own background over the fill, so the border
    ; colour covers the whole box and the outline never appears.
    _SpAddStyle(_spBox.Hwnd, 0x02000000)
    _SpAddStyle(_spFill.Hwnd, 0x04000000)
    ; ⛔ The fill covers the box's whole interior, so without this every click lands on the FILL
    ; and the box never receives a hit-test: the drag silently stops working the moment the box
    ; gains an inside. WS_EX_TRANSPARENT makes it invisible to the mouse while still painting.
    _SpAddExStyle(_spFill.Hwnd, 0x00000020)
    ; Belt and braces: a DISABLED child sends its mouse messages to its parent, which is the
    ; behaviour relied on here. WS_EX_TRANSPARENT alone left WindowFromPoint still returning the
    ; fill, and the fill is decoration — it should never be a mouse target by any route.
    _spFill.Enabled := false

    ; ⛔ The handlers are registered BEFORE the box is shown and before its frame is
    ; recalculated. Registered after, _SpFrameChanged ran with NO WM_NCCALCSIZE handler in
    ; place, so the frame was never removed — and nothing recalculates it again, so it stayed
    ; for the life of the window. The box then measured 14px (2 x 7) wider and taller than the
    ; model believed, which changes the SLACK the anchor is a fraction of: merely pressing the
    ; mouse moved a 50/50 position to 56/100. Every handler already no-ops while _spBox is
    ; unset, so registering early is safe.
    OnMessage(0x0005, _SpSize)            ; WM_SIZE
    OnMessage(0x0024, _SpGetMinMaxInfo)   ; WM_GETMINMAXINFO
    OnMessage(0x0083, _SpNcCalcSize)      ; WM_NCCALCSIZE
    OnMessage(0x0084, _SpNcHitTest)       ; WM_NCHITTEST
    OnMessage(0x0231, _SpEnterSizeMove)   ; WM_ENTERSIZEMOVE
    OnMessage(0x0214, _SpSizing)          ; WM_SIZING
    OnMessage(0x0216, _SpMoving)          ; WM_MOVING

    _spBox.Show("NoActivate")
    _SpFrameChanged()
}

; Measures the slot and letterboxes the picture into it at the CURRENT monitor's aspect ratio.
;
; Read at Show() time, never once at startup: the user can drag the settings window to another
; monitor between opens, and a 9:16 screen drawn at the dialog's width would be ~750px tall, so
; the picture gives up WIDTH rather than the dialog changing size.
ScreenPictureRelayout() {
    wa := GetNearestMonitorWorkArea(_spGui.Hwnd)
    WinGetPos(&sx, &sy, &sw, &sh, "ahk_id " _spSlot.Hwnd)     ; MEASURED, never assumed
    aspect := (wa.height > 0) ? wa.width / wa.height : 16 / 9
    if (sw / sh > aspect) {
        ph := sh, pw := Round(sh * aspect)
    } else {
        pw := sw, ph := Round(sw / aspect)
    }
    _SpMoveToScreen(_spPic.Hwnd, sx + Round((sw - pw) / 2), sy + Round((sh - ph) / 2), pw, ph)
    ScreenPictureSet(_spPos, _spEnabled)
}

; --- the value ---------------------------------------------------------------------------------

ScreenPictureSet(pos, enabled := true) {
    global _spPos, _spEnabled
    _spPos := { ax: pos.ax, ay: pos.ay, w: pos.w, h: pos.h }
    _spEnabled := enabled
    _SpRedrawBox()
}

ScreenPictureGet() {
    return { ax: _spPos.ax, ay: _spPos.ay, w: _spPos.w, h: _spPos.h }
}

; --- internals ----------------------------------------------------------------------------------

_SpPictureRect() {
    WinGetPos(&x, &y, &w, &h, "ahk_id " _spPic.Hwnd)
    return { x: x, y: y, w: w, h: h }
}

; The size a keep-current-size position is drawn at, in pixels.
_SpKeepPx(pic) {
    return { w: Round(pic.w * SP_KEEP_W / 100), h: Round(pic.h * SP_KEEP_H / 100) }
}

_SpRedrawBox() {
    if (_spPic = "" || _spBox = "")
        return
    pic := _SpPictureRect()
    k := _SpKeepPx(pic)
    r := AnchoredRect(pic.x, pic.y, pic.w, pic.h, _spPos, k.w, k.h)
    ; ⛔ WinShow, NOT Gui.Show. Gui.Show AUTO-SIZES the window to fit its contents, which for an
    ; empty box means it silently resizes itself and throws away the rectangle just computed —
    ; measured as a box 14px larger than asked for in both axes, every redraw. Because the
    ; anchor is a fraction of the SLACK, a box that is not the size the model believes puts the
    ; position in the wrong place and drifts a little further on each redraw.
    ;
    ; Visibility is settled BEFORE the move, so the move is the last word on the rectangle.
    ; The box is hidden rather than greyed when no row is selected: a box you can see but not
    ; move is an invitation to try.
    if (_spEnabled)
        WinShow("ahk_id " _spBox.Hwnd)
    else
        WinHide("ahk_id " _spBox.Hwnd)
    _SpMoveToScreen(_spBox.Hwnd, r.x, r.y, r.w, r.h)
    _SpFitFill()
    _SpRaise()
}

; ⛔ AutoHotkey inserts each new control BEHIND the ones already added, so creation order is
; REVERSE z-order: the picture ends up underneath the slot and the box underneath both. When
; that happened every click landed on the picture and the box never saw a message at all.
; Required order, front to back: box > picture > slot.
_SpRaise() {
    static HWND_TOP := 0, FLAGS := 0x0001 | 0x0002 | 0x0010    ; NOSIZE | NOMOVE | NOACTIVATE
    DllCall("SetWindowPos", "ptr", _spPic.Hwnd, "ptr", HWND_TOP
          , "int", 0, "int", 0, "int", 0, "int", 0, "uint", FLAGS)
    DllCall("SetWindowPos", "ptr", _spBox.Hwnd, "ptr", HWND_TOP
          , "int", 0, "int", 0, "int", 0, "int", 0, "uint", FLAGS)
    ; A raise or a move changes what is on top; it does not on its own mark anything as needing
    ; to be drawn again.
    static RDW := 0x0001 | 0x0004 | 0x0080 | 0x0100 | 0x0400
    DllCall("RedrawWindow", "ptr", _spGui.Hwnd, "ptr", 0, "ptr", 0, "uint", RDW)
}

_SpAddExStyle(hwnd, bits) {
    static GWL_EXSTYLE := -20
    cur := DllCall("GetWindowLongPtr", "ptr", hwnd, "int", GWL_EXSTYLE, "ptr")
    DllCall("SetWindowLongPtr", "ptr", hwnd, "int", GWL_EXSTYLE, "ptr", cur | bits)
}

_SpAddStyle(hwnd, bits) {
    static GWL_STYLE := -16
    cur := DllCall("GetWindowLongPtr", "ptr", hwnd, "int", GWL_STYLE, "ptr")
    DllCall("SetWindowLongPtr", "ptr", hwnd, "int", GWL_STYLE, "ptr", cur | bits)
}

_SpFrameChanged() {
    static F := 0x0020 | 0x0002 | 0x0001 | 0x0004 | 0x0010    ; FRAMECHANGED NOMOVE NOSIZE ...
    DllCall("SetWindowPos", "ptr", _spBox.Hwnd, "ptr", 0
          , "int", 0, "int", 0, "int", 0, "int", 0, "uint", F)
}

; WinGetPos reports SCREEN coordinates; WinMove on a child window takes coordinates relative to
; the PARENT'S CLIENT area. That asymmetry is a bug generator, so it is converted in exactly one
; place and every caller speaks screen coordinates.
_SpMoveToScreen(hwnd, x, y, w, h) {
    pt := Buffer(8, 0)
    NumPut("int", x, pt, 0), NumPut("int", y, pt, 4)
    DllCall("ScreenToClient", "ptr", _spGui.Hwnd, "ptr", pt)
    WinMove(NumGet(pt, 0, "int"), NumGet(pt, 4, "int"), w, h, "ahk_id " hwnd)
}

_SpCursor() {
    pt := Buffer(8, 0)
    DllCall("GetCursorPos", "ptr", pt)
    return { x: NumGet(pt, 0, "int"), y: NumGet(pt, 4, "int") }
}

_SpReadRect(lParam) {
    return { l: NumGet(lParam, 0, "int"), t: NumGet(lParam, 4, "int")
           , r: NumGet(lParam, 8, "int"), b: NumGet(lParam, 12, "int") }
}
_SpWriteRect(lParam, l, t, r, b) {
    NumPut("int", l, lParam, 0), NumPut("int", t, lParam, 4)
    NumPut("int", r, lParam, 8), NumPut("int", b, lParam, 12)
}

; The fill is inset inside the box on every size change, which is what leaves the box's own
; background showing as a border. WM_SIZE rather than a call from _SpRedrawBox, so it keeps up
; DURING a resize drag and not only when the drag ends.
_SpSize(wParam, lParam, msg, hwnd) {
    if (_spBox = "" || hwnd != _spBox.Hwnd)
        return
    _SpFitFill()
}

; Insets the fill inside the box, which is what leaves the box's own background showing as a
; border. Called from BOTH the redraw and WM_SIZE: the redraw is what guarantees it is right
; after a programmatic move, and WM_SIZE is what keeps it right DURING a resize drag.
_SpFitFill() {
    if (_spBox = "" || _spFill = "")
        return
    WinGetPos(, , &w, &h, "ahk_id " _spBox.Hwnd)
    WinMove(SP_BORDER, SP_BORDER
          , Max(1, w - SP_BORDER * 2), Max(1, h - SP_BORDER * 2), "ahk_id " _spFill.Hwnd)
}

; ⛔ A sizable window has an OS-enforced MINIMUM TRACKING SIZE, and it is far larger than a box
; in a 300px-wide picture: asking for 120x89 got back 134x103. That is not a frame — the client
; rect measured 134x103 too — it is Windows refusing to make the window smaller. Left in place
; it silently changes the box's size, and since the anchor is a fraction of the SLACK, a box
; that is 14px bigger than the model believes puts the position in the wrong place and makes it
; drift on every redraw.
;
; The real minimum is SP_MIN_PCT, enforced in _SpSizing against the picture, so the OS floor can
; go to 1x1 without anything becoming ungrabbable.
_SpGetMinMaxInfo(wParam, lParam, msg, hwnd) {
    if (_spBox = "" || hwnd != _spBox.Hwnd)
        return
    ; MINMAXINFO: ptReserved 0, ptMaxSize 8, ptMaxPosition 16, ptMinTrackSize 24, ptMaxTrack 32.
    NumPut("int", 1, lParam, 24)
    NumPut("int", 1, lParam, 28)
    return 0
}

; The box owns its whole rectangle. The system's WS_THICKFRAME lives in the NON-client area, so
; the visible fill would be inset from the rectangle being stored — measured at 7px per side,
; which made a box stored as "left 50%" draw as about 46%. A picture that lies by more than the
; grid it snaps to is not a picture. Returning 0 with the proposed rectangle untouched means
; "the client area IS the whole window rect".
_SpNcCalcSize(wParam, lParam, msg, hwnd) {
    if (_spBox = "" || hwnd != _spBox.Hwnd)
        return
    return 0
}

; With no non-client area Windows returns no border hit-tests either, so the edges are
; hit-tested by hand. This also drives the MOVE: HTCAPTION in the middle makes Windows run its
; own modal move loop on the press, with no posted message needed.
_SpNcHitTest(wParam, lParam, msg, hwnd) {
    static HTCAPTION := 2, HTLEFT := 10, HTRIGHT := 11, HTTOP := 12, HTTOPLEFT := 13
    static HTTOPRIGHT := 14, HTBOTTOM := 15, HTBOTTOMLEFT := 16, HTBOTTOMRIGHT := 17
    if (_spBox = "" || hwnd != _spBox.Hwnd)
        return
    ; lParam carries the cursor in SCREEN coordinates as a packed pair of SIGNED 16-bit values.
    ; A monitor left of the primary has negative coordinates, which is where an unsigned read
    ; goes wrong.
    sx := (lParam & 0xFFFF), sy := ((lParam >> 16) & 0xFFFF)
    if (sx > 0x7FFF)
        sx -= 0x10000
    if (sy > 0x7FFF)
        sy -= 0x10000
    ; A keep-current-size position has no size to drag. Every point is the caption, so the box
    ; can be moved and cannot be resized — which is what "keep the size it has" means.
    if (_spPos.w = 0 && _spPos.h = 0)
        return HTCAPTION
    WinGetPos(&bx, &by, &bw, &bh, "ahk_id " _spBox.Hwnd)
    onL := (sx < bx + SP_GRAB_PX), onR := (sx > bx + bw - SP_GRAB_PX)
    onT := (sy < by + SP_GRAB_PX), onB := (sy > by + bh - SP_GRAB_PX)
    if (onT)
        return onL ? HTTOPLEFT : onR ? HTTOPRIGHT : HTTOP
    if (onB)
        return onL ? HTBOTTOMLEFT : onR ? HTBOTTOMRIGHT : HTBOTTOM
    if (onL)
        return HTLEFT
    if (onR)
        return HTRIGHT
    return HTCAPTION
}

; ⛔ THE ONE THAT MATTERS. WM_MOVING's proposed RECT is NOT an absolute function of the cursor:
; Windows derives it from the window's CURRENT position plus the movement since the last
; message. A handler that snaps that rectangle and writes it back therefore feeds its own output
; into the next proposal, and the drag is eaten — measured at cursor +80px, box +8px, which
; reads exactly as "I can't hold and drag".
;
; So the grab offset is captured ONCE, here, and every later frame derives the position from the
; live cursor minus that offset. Snapping the same cursor position twice then gives the same
; rectangle, and there is no feedback.
_SpEnterSizeMove(wParam, lParam, msg, hwnd) {
    global _spGrab
    if (_spBox = "" || hwnd != _spBox.Hwnd)
        return
    c := _SpCursor()
    WinGetPos(&bx, &by, &bw, &bh, "ahk_id " _spBox.Hwnd)
    _spGrab := { x: c.x, y: c.y, l: bx, t: by, r: bx + bw, b: by + bh }
}

_SpMoving(wParam, lParam, msg, hwnd) {
    global _spPos
    if (_spBox = "" || hwnd != _spBox.Hwnd)
        return
    pic := _SpPictureRect()
    c := _SpReadRect(lParam)
    cur := _SpCursor()
    w := c.r - c.l, h := c.b - c.t                  ; the proposal's SIZE is stable during a move
    slackX := pic.w - w, slackY := pic.h - h
    ax := (slackX > 0)
        ? SnapAnchorPct((cur.x - (_spGrab.x - _spGrab.l) - pic.x) / slackX * 100, SP_MOVE_STEP)
        : _spPos.ax
    ay := (slackY > 0)
        ? SnapAnchorPct((cur.y - (_spGrab.y - _spGrab.t) - pic.y) / slackY * 100, SP_MOVE_STEP)
        : _spPos.ay
    _spPos.ax := ax, _spPos.ay := ay
    ; Clamping falls out of the anchor being 0..100; there is no separate bounds check, because
    ; an anchor outside that range is the only way out of the picture.
    l := pic.x + Round(slackX * ax / 100)
    t := pic.y + Round(slackY * ay / 100)
    _SpWriteRect(lParam, l, t, l + w, t + h)
    _SpNotify()
    return 1
}

_SpSizing(wParam, lParam, msg, hwnd) {
    global _spPos
    static WMSZ_LEFT := 1, WMSZ_RIGHT := 2, WMSZ_TOP := 3, WMSZ_TOPLEFT := 4
    static WMSZ_TOPRIGHT := 5, WMSZ_BOTTOM := 6, WMSZ_BOTTOMLEFT := 7, WMSZ_BOTTOMRIGHT := 8
    if (_spBox = "" || hwnd != _spBox.Hwnd)
        return
    pic := _SpPictureRect()
    c := _SpReadRect(lParam)
    cur := _SpCursor()
    minW := Round(pic.w * SP_MIN_PCT / 100), minH := Round(pic.h * SP_MIN_PCT / 100)

    left   := (wParam = WMSZ_LEFT || wParam = WMSZ_TOPLEFT || wParam = WMSZ_BOTTOMLEFT)
    right  := (wParam = WMSZ_RIGHT || wParam = WMSZ_TOPRIGHT || wParam = WMSZ_BOTTOMRIGHT)
    top    := (wParam = WMSZ_TOP || wParam = WMSZ_TOPLEFT || wParam = WMSZ_TOPRIGHT)
    bottom := (wParam = WMSZ_BOTTOM || wParam = WMSZ_BOTTOMLEFT || wParam = WMSZ_BOTTOMRIGHT)

    l := c.l, t := c.t, r := c.r, b := c.b
    ; The OPPOSITE edge is held exactly where it is and the SIZE is what snaps. Snapping the
    ; dragged EDGE instead made the resulting size depend on wherever the other edge happened to
    ; sit, which is how a 5% grid produced a 48%-wide box.
    if (left)
        l := r - _SpSnapSpan(r - _SpClamp(cur.x - (_spGrab.x - _spGrab.l), pic.x, pic.x + pic.w)
                           , pic.w, minW, r - pic.x)
    if (right)
        r := l + _SpSnapSpan(_SpClamp(cur.x - (_spGrab.x - _spGrab.r), pic.x, pic.x + pic.w) - l
                           , pic.w, minW, pic.x + pic.w - l)
    if (top)
        t := b - _SpSnapSpan(b - _SpClamp(cur.y - (_spGrab.y - _spGrab.t), pic.y, pic.y + pic.h)
                           , pic.h, minH, b - pic.y)
    if (bottom)
        b := t + _SpSnapSpan(_SpClamp(cur.y - (_spGrab.y - _spGrab.b), pic.y, pic.y + pic.h) - t
                           , pic.h, minH, pic.y + pic.h - t)

    _SpWriteRect(lParam, l, t, r, b)
    k := _SpKeepPx(pic)
    _spPos := AnchorFromRect(pic.x, pic.y, pic.w, pic.h
                           , { x: l, y: t, w: r - l, h: b - t }, _spPos, k.w, k.h)
    _SpNotify()
    return 1
}

_SpSnapSpan(raw, span, minPx, maxPx) {
    px := Round(span * SnapSizePct(raw / span * 100, SP_SIZE_STEP, SP_SIZE_MAGNETS, SP_MAGNET_PULL) / 100)
    return Max(minPx, Min(maxPx, px))
}

_SpClamp(v, lo, hi) {
    return Max(lo, Min(hi, v))
}

_SpNotify() {
    if (_spOnChange != "")
        _spOnChange(ScreenPictureGet())
}
