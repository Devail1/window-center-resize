; tests/manual_editor_spike.ahk
;
; THROWAWAY SPIKE. Not part of the automated suite, not shipped, delete once the editor lands.
;
; It exists to answer the questions the headless suite cannot reach, on a real display:
;
;   Q1  Does a "-Caption +Resize +Parent" child Gui honour a
;       PostMessage(WM_NCLBUTTONDOWN, HTCAPTION) move loop, and are its invisible sizing
;       borders actually grabbable with a mouse?
;   Q2  How far apart are the child's WINDOW rect (what we measure and store) and its CLIENT
;       rect (the blue fill the user sees)? WS_THICKFRAME puts a frame in the non-client area,
;       and a picture that lies by 8 px is not a picture. Mode B below removes it.
;   Q3  Does percent -> pixel -> drag -> percent round-trip cleanly on a SCALED display?
;       150% / 175% DPI is the unmeasured risk, and it is invisible at 100%.
;   Q4  Does snapping felt DURING the drag (rewriting the RECT in WM_SIZING / WM_MOVING)
;       behave, or does it fight the mouse?
;
; HOW TO RUN IT:  drag the blue rectangle, resize it by its edges and corners, press
; "Mode B", drag it again, press "Round-trip check", then copy the whole report box back.
;
; ---------------------------------------------------------------------------------------------
; THE ONE RULE THIS SPIKE IS BUILT AROUND: never compute a pixel from a nominal number.
;
; AutoHotkey DPI-scales the coordinates passed to Gui.Add and Gui.Show, so "w300" is 450
; physical pixels at 150%. WinGetPos, by contrast, always reports raw physical pixels. Mixing
; the two is the DPI bug waiting to happen. So every drag calculation below MEASURES the
; picture with WinGetPos on its HWND and derives everything from that measurement. The nominal
; 300x170 is layout only; nothing downstream ever sees it. If this rule holds on a scaled
; display, DPI cancels by construction and the editor needs no DPI code at all.
; ---------------------------------------------------------------------------------------------

#Requires AutoHotkey v2.0
#Include "..\src\lib\Monitors.ahk"
#Include "..\src\gui\Theme.ahk"

global WM_NCCALCSIZE    := 0x0083
global WM_NCHITTEST     := 0x0084
global WM_NCLBUTTONDOWN := 0x00A1
global WM_LBUTTONDOWN   := 0x0201
global WM_SIZING        := 0x0214
global WM_MOVING        := 0x0216

global HTCAPTION := 2
global HTLEFT := 10, HTRIGHT := 11, HTTOP := 12, HTTOPLEFT := 13, HTTOPRIGHT := 14
global HTBOTTOM := 15, HTBOTTOMLEFT := 16, HTBOTTOMRIGHT := 17

global WS_CLIPSIBLINGS := 0x04000000, WS_CLIPCHILDREN := 0x02000000
global SWP_NOSIZE := 0x0001, SWP_NOMOVE := 0x0002, SWP_NOZORDER := 0x0004
global SWP_NOACTIVATE := 0x0010, SWP_FRAMECHANGED := 0x0020

; The snap grid, in percent of the picture. 5 is the plan's number; the spike cycles it so the
; grid can be FELT rather than argued about. 0 means no snapping at all.
; (user decision) 2%. NOT 2.5%: ClampAnchor in Settings.ahk stores the anchor as Round(value),
; so a 2.5 grid would be saved as 2, 5, 8, 10, 13 — the value dragged would not be the value
; stored, which is the single thing a picture exists to rule out. 2 still lands every anchor
; that means anything: flush 0, centre 50, flush 100, quarters 25 and 75.
global SNAP_PCT := 2
global SNAP_STEPS := [2, 5, 1, 0]

; POSITION and SIZE do not want the same grid, which is the thing 5%-everywhere got wrong.
;
; Position wants to be COARSE. There are only a handful of placements anyone means — flush,
; quarter, centre — and a coarse grid makes the box land on them decisively.
;
; Size wants to be FINE. Widths are a continuum, and the most-wanted ones are not evenly
; spaced: a third is 33.3%, which is not on a 5% grid, or a 2% one. So the size grid is fine
; AND carries magnets at the fractions people actually ask for. Magnets need a pull RADIUS
; wider than the grid step or they never win.
; (user decision) 1% plus magnets. At 5% a nudge smaller than half a step rounded straight back
; and the width would not move at all — measured: twelve nudges, width 40 every time.
global SIZE_PCT := 0                     ; 0 selects magnet mode
global SIZE_STEPS := [0, 1, 2, 5]        ; 0 selects the magnet mode below
global SIZE_MAGNETS := [25, 33, 50, 67, 75, 100]
global MAGNET_RADIUS := 2                ; percent

; WHAT the snap applies to while MOVING. These are three different grids and they feel
; different, which is the whole reason the toggle exists:
;
;   "anchor"  snap the anchor to 5% of the SLACK. The step therefore changes size with the box
;             — a narrow box jumps in coarse pixels, a wide one in fine ones — and the edges do
;             not line up with anything visible. 0 / 50 / 100 are exactly reachable.
;   "edge"    snap the leading edge to 5% of the PICTURE. Uniform steps, edges land on the same
;             grid a resize uses. But the CENTRE becomes unreachable for odd widths: a 33% wide
;             box centres at 33.5%, which is not on the grid.
;   "magnet"  the edge grid, plus stops at flush-left, centred and flush-right. Uniform feel,
;             edges aligned, and centring still exact. Costs one extra comparison per drag.
global SNAP_MODE := "anchor"
global SNAP_MODES := ["anchor", "edge", "magnet"]
; A position may not be dragged smaller than this, in percent. Zero-size is not a position, and
; a box too small to grab again is a trap.
global MIN_PCT := 10
; The grab zone for mode B's hand-rolled hit-test, in physical pixels. Deliberately NOT the
; system frame metric: the box in the picture is small, and ~8 px would be most of it.
global GRAB_PX := 7

global G := ""              ; parent Gui
; Named PICTURE, not PIC: AutoHotkey is CASE-INSENSITIVE, so a global PIC and the local `pic`
; that three of the drag handlers use for the measured rectangle are the same identifier. The
; local silently shadows the control object inside those functions.
global PICTURE := ""        ; the monitor picture (a Progress control used as a coloured rect)
global BOX := ""            ; the draggable child Gui
global LIVE := ""           ; the one-line readout, updated during the drag
global REPORT := ""         ; the log, updated only on discrete events
; (user decision) MODE B SHIPS. The system frame insets the visible fill by 7px per side, so a
; box stored as "left 50%" draws as ~46% and "flush left" draws with a gap — the picture lies
; by more than the 5% grid it snaps to. Mode A is kept only so the two can still be compared.
global FRAMELESS := true    ; mode B: client rect == window rect
global BMODE := ""          ; the mode toggle, whose label IS the mode indicator
global BSNAP := "", BGRID := ""
global NOTES := []
; Which messages actually arrive. When the box refuses to move there are three different
; failures that look identical on screen — the click never reached the child, the move loop
; never started, or the RECT rewrite is wrong — and this is what tells them apart.
global MSGCOUNT := Map()
; The first few WM_MOVING events of a drag, with the cursor beside the rectangle Windows
; proposed. If the proposal tracks the DRAG START it is absolute and safe to rewrite; if it
; tracks the window's CURRENT position it is incremental, and every rewrite feeds back into the
; next proposal.
global TRACE := []
global TRACING := false

; ⛔ THE ONE THAT MATTERS. WM_MOVING's proposed RECT is NOT an absolute function of the cursor:
; Windows derives it from the window's CURRENT position plus the movement since the last
; message. So a handler that snaps the rect and writes it back feeds its own output into the
; next proposal, and the drag is eaten — measured at cursor +80px, box +8px. It reads exactly
; like "I can't hold and drag."
;
; The fix is to ignore the proposed rect's POSITION entirely and derive the position from the
; CURSOR and an offset captured once, when the drag starts. That makes the rewrite idempotent:
; snapping the same cursor position twice gives the same rectangle, so there is no feedback.
global GRAB := { x: 0, y: 0, l: 0, t: 0, r: 0, b: 0 }
; A drag whose WM_ENTERSIZEMOVE never arrived would run on the PREVIOUS drag's offset and jump.
global GRABBED := false

; The live position, in the SAME units settings.ini stores. The picture edits this, never pixels.
; Deliberately free in BOTH axes. The obvious default — left half, full height — has ZERO
; vertical slack, so the box genuinely cannot move up or down, and that reads as a broken drag
; when you are trying to judge how the drag feels.
global POS := { ax: 50, ay: 50, w: 40, h: 55 }
; The size a real window happens to have, for positions storing w/h = 0 ("keep current size").
; The picture must draw something, so it draws this. Percent of the work area.
global KEEPSIZE := { w: 40, h: 55 }

; A runtime error in a GUI script is a MODAL dialog — it blocks the very window being tested and
; has to be dismissed by hand before anything else can be tried. /ErrorStdOut does not cover it;
; it only covers load time. Put the fault in the report instead, where it can be read and the
; session carries on. (main.ahk and the test harness both do this for the same reason.)
OnError(_SpikeError)
_SpikeError(err, mode) {
    msg := "ERROR: "
    try msg .= err.Message
    try msg .= "   at line " err.Line
    Note(msg)
    try Render()
    return 1        ; handled — do not raise the dialog
}

Main()

Main() {
    global G, PICTURE, BOX, LIVE, REPORT, BMODE, BSNAP, BGRID

    th := Theme("light")

    ; WS_CLIPCHILDREN on the parent, WS_CLIPSIBLINGS on the two Progress controls below.
    ; Without them the picture PAINTS OVER the blue box: the box is correctly positioned and
    ; correctly hit-tested — clicks reach it — but it is invisible except for whatever fragment
    ; happened to be painted last. A drag mechanism that works perfectly on a box you cannot see
    ; is indistinguishable from one that does not work, which is exactly how this presented.
    G := Gui("-MaximizeBox -MinimizeBox +" WS_CLIPCHILDREN, "Editor drag spike")
    G.MarginX := 16, G.MarginY := 16
    G.BackColor := th["bg"]

    G.SetFont("s11 w600 c" th["header"], "Segoe UI")
    G.Add("Text", "xm w300", "Position")
    G.SetFont("s9 w400 c" th["hint"], "Segoe UI")
    G.Add("Text", "xm y+2 w300", "Drag the blue box inside your screen.")

    ; The slot is a FIXED-HEIGHT letterbox. The picture inside it takes the monitor's real
    ; aspect ratio and gives up WIDTH to keep the dialog one size, portrait monitors included.
    ; The aspect is read HERE, at show time, not once at startup: the user can drag the settings
    ; window to another monitor between opens.
    wa := GetNearestMonitorWorkArea(G.Hwnd)
    slot := G.Add("Progress", "xm y+12 w300 h170 Background" th["hint"], 0)

    ClipSiblings(slot.Hwnd)
    WinGetPos(&sx, &sy, &sw, &sh, "ahk_id " slot.Hwnd)      ; MEASURED, never assumed
    aspect := wa.width / wa.height
    if (sw / sh > aspect) {            ; slot wider than the monitor: letterbox left and right
        ph := sh, pw := Round(sh * aspect)
    } else {                           ; slot taller: letterbox top and bottom
        pw := sw, ph := Round(sw / aspect)
    }
    ; "xp yp wp hp" = exactly on top of the slot. It is WinMoved to the letterbox rect two
    ; lines down, but it must be DECLARED at the slot's full size: AutoHotkey's layout cursor
    ; for every control added afterwards comes from the DECLARED rectangle, not the moved one.
    ; Declared as "x0 y0 w10 h10" the cursor stayed at y=10 and the buttons, the labels and the
    ; report were all laid out on top of the picture. Measured, not guessed.
    PICTURE := G.Add("Progress", "xp yp wp hp BackgroundFFFFFF", 0)
    ClipSiblings(PICTURE.Hwnd)
    MoveToScreenRect(PICTURE.Hwnd, G.Hwnd
                   , sx + Round((sw - pw) / 2), sy + Round((sh - ph) / 2), pw, ph)

    ; The draggable box.
    ;
    ; "+Resize" is doing real work: it leaves WS_THICKFRAME on the window, and WS_THICKFRAME is
    ; what makes DefWindowProc's hit-test return HTLEFT / HTBOTTOMRIGHT / ... for a frame the
    ; user cannot see. Without it the box can be moved but never resized.
    BOX := Gui("-Caption +Resize +Parent" G.Hwnd)
    BOX.BackColor := "3B82F6"
    BOX.Show("NoActivate")
    FrameChanged()          ; mode B is the default, so the frame must be recalculated at once
    ; Raised to the front of its siblings at the END of Main() — see RaiseBox(). A child Gui is
    ; a SIBLING of the parent's controls, and new siblings go to the FRONT of the z-order, so
    ; the two Progress controls underneath it were covering it completely: every click landed on
    ; the picture and the box never saw a WM_LBUTTONDOWN at all. It looked exactly like a dead
    ; drag mechanism.

    G.SetFont("s9 w400 c" th["text"], "Segoe UI")
    G.Add("Text", "xm y+12 w300", "Presets — percent in, pixels out:")
    b1 := G.Add("Button", "xm y+6 w70", "Left half")
    b2 := G.Add("Button", "x+6 yp w70", "Right 1/3")
    b3 := G.Add("Button", "x+6 yp w70", "Centre*")
    b4 := G.Add("Button", "x+6 yp w70", "Full")
    b1.OnEvent("Click", (*) => SetPos(0, 50, 50, 100))
    b2.OnEvent("Click", (*) => SetPos(100, 50, 33, 100))
    ; *Centre stores w/h = 0 — the shipped default, which MOVES without resizing. The picture
    ; still has to draw a box, so it draws KEEPSIZE. How the editor should SHOW "keep the size
    ; the window already has" is an open UI question this spike deliberately leaves open.
    b3.OnEvent("Click", (*) => SetPos(50, 50, 0, 0))
    b4.OnEvent("Click", (*) => SetPos(50, 50, 100, 100))

    bMode := G.Add("Button", "xm y+10 w150", "")
    bRt   := G.Add("Button", "x+6 yp w144", "Round-trip check")
    bSnap := G.Add("Button", "xm y+6 w150", "")
    bGrid := G.Add("Button", "x+6 yp w144", "")
    BMODE := bMode, BSNAP := bSnap, BGRID := bGrid
    RenderMode()
    bMode.OnEvent("Click", (*) => ToggleFrameless())
    bTrace := G.Add("Button", "xm y+6 w300", "Trace next drag")
    bTrace.OnEvent("Click", (*) => StartTrace())
    bSnap.OnEvent("Click", (*) => CycleSizeGrid())
    bGrid.OnEvent("Click", (*) => CycleGrid())
    bRt.OnEvent("Click", (*) => RoundTripCheck())

    G.SetFont("s9 w600 c" th["text"], "Consolas")
    LIVE := G.Add("Text", "xm y+12 w300")
    G.SetFont("s9 w400 c" th["text"], "Consolas")
    REPORT := G.Add("Edit", "xm y+6 w300 r16 ReadOnly -Wrap +HScroll")

    ; The drag. Tell Windows the click landed on a title bar it cannot see; Windows then runs
    ; its own modal move loop. No timer, no mouse tracking, no capture to leak.
    OnMessage(WM_LBUTTONDOWN, OnBoxLButtonDown)
    ; Clamp and snap by rewriting the RECT Windows hands over DURING the drag, so the snap is
    ; felt under the mouse rather than applied on release.
    OnMessage(WM_MOVING, OnBoxMoving)
    OnMessage(WM_SIZING, OnBoxSizing)
    OnMessage(0x0231, OnEnterSizeMove)             ; WM_ENTERSIZEMOVE
    OnMessage(0x0232, OnExitSizeMove)              ; WM_EXITSIZEMOVE
    ; Mode B only; both no-op while FRAMELESS is false.
    OnMessage(WM_NCCALCSIZE, OnBoxNcCalcSize)
    OnMessage(WM_NCHITTEST, OnBoxNcHitTest)

    G.OnEvent("Close", (*) => ExitApp())
    G.OnEvent("Escape", (*) => ExitApp())
    bRt.Focus()
    G.Show()

    RaiseBox()
    ; Everything below is measured AFTER Show — before it, the Gui has a size but not yet a
    ; screen position.
    ApplyPosToPicture()
    p := PictureRect()
    Note("monitor work area  " wa.width "x" wa.height "   aspect " Round(aspect, 3))
    Note("A_ScreenDPI " A_ScreenDPI "  =>  scaling " Round(A_ScreenDPI / 96 * 100) "%")
    Note("slot     nominal 300x170   measured " sw "x" sh
       . ((sw = 300 && sh = 170) ? "   (unscaled)" : "   <- AHK scaled the layout"))
    Note("picture  measured " p.w "x" p.h)
    ReportFrameGap()
    Render()
}

; --- geometry: the picture is the only thing measured, percent the only thing stored ----------

; AutoHotkey does not put WS_CLIPSIBLINGS on a Progress control, so it paints its whole
; rectangle including the part the box is sitting on.
ClipSiblings(hwnd) {
    static GWL_STYLE := -16
    cur := DllCall("GetWindowLongPtr", "ptr", hwnd, "int", GWL_STYLE, "ptr")
    DllCall("SetWindowLongPtr", "ptr", hwnd, "int", GWL_STYLE, "ptr", cur | WS_CLIPSIBLINGS)
}

; AutoHotkey inserts each new control BEHIND the ones already added, so creation order is
; REVERSE z-order. The picture is created after the slot and therefore ends up underneath it,
; completely hidden; the box needs to be in front of both. Nothing here can be left to the
; order the controls happen to be declared in.
;
; Required order, front to back:  BOX  >  PICTURE  >  slot.
Raise(hwnd) {
    static HWND_TOP := 0
    DllCall("SetWindowPos", "ptr", hwnd, "ptr", HWND_TOP, "int", 0, "int", 0, "int", 0
          , "int", 0, "uint", SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE)
}

RaiseBox() {
    Raise(PICTURE.Hwnd)
    Raise(BOX.Hwnd)
    Repaint()
}

; A raise or a move changes what is on top but does not, on its own, mark anything as needing
; to be drawn again.
Repaint() {
    static RDW_INVALIDATE := 0x0001, RDW_ERASE := 0x0004, RDW_ALLCHILDREN := 0x0080
         , RDW_UPDATENOW := 0x0100, RDW_FRAME := 0x0400
    DllCall("RedrawWindow", "ptr", G.Hwnd, "ptr", 0, "ptr", 0
          , "uint", RDW_INVALIDATE | RDW_ERASE | RDW_FRAME | RDW_ALLCHILDREN | RDW_UPDATENOW)
}

PictureRect() {
    WinGetPos(&x, &y, &w, &h, "ahk_id " PICTURE.Hwnd)
    return { x: x, y: y, w: w, h: h }
}

BoxRect() {
    WinGetPos(&x, &y, &w, &h, "ahk_id " BOX.Hwnd)
    return { x: x, y: y, w: w, h: h }
}

; WinGetPos reports SCREEN coordinates; WinMove on a child window takes coordinates relative to
; the parent's CLIENT area. That asymmetry is a bug generator, so it is converted in exactly one
; place and every caller speaks screen coordinates.
MoveToScreenRect(hwnd, parentHwnd, x, y, w, h) {
    pt := Buffer(8, 0)
    NumPut("int", x, pt, 0), NumPut("int", y, pt, 4)
    DllCall("ScreenToClient", "ptr", parentHwnd, "ptr", pt)
    WinMove(NumGet(pt, 0, "int"), NumGet(pt, 4, "int"), w, h, "ahk_id " hwnd)
}

; percent -> pixels, against the MEASURED picture.
PctToRect(p, pic) {
    wp := (p.w > 0) ? p.w : KEEPSIZE.w      ; 0 = "keep the window's size"; draw something
    hp := (p.h > 0) ? p.h : KEEPSIZE.h
    w := Round(pic.w * wp / 100)
    h := Round(pic.h * hp / 100)
    x := pic.x + Round((pic.w - w) * p.ax / 100)
    y := pic.y + Round((pic.h - h) * p.ay / 100)
    return { x: x, y: y, w: w, h: h }
}

; pixels -> percent. The anchor runs across the SLACK, so a full-width box has NO slack and its
; anchor is undefined — keep whatever it was rather than dividing by zero.
RectToPct(r, pic, prev) {
    slackX := pic.w - r.w, slackY := pic.h - r.h
    return { ax: (slackX > 0) ? Round((r.x - pic.x) / slackX * 100) : prev.ax
           , ay: (slackY > 0) ? Round((r.y - pic.y) / slackY * 100) : prev.ay
           , w:  Round(r.w / pic.w * 100)
           , h:  Round(r.h / pic.h * 100) }
}

ApplyPosToPicture() {
    r := PctToRect(POS, PictureRect())
    MoveToScreenRect(BOX.Hwnd, G.Hwnd, r.x, r.y, r.w, r.h)
    Repaint()
}

SetPos(ax, ay, w, h) {
    POS.ax := ax, POS.ay := ay, POS.w := w, POS.h := h
    ApplyPosToPicture()
    Note("preset   ax " ax "  ay " ay "  w " w "  h " h
       . ((w = 0 || h = 0) ? "   (0 = keep size, drawn at KEEPSIZE)" : ""))
    Render()
}

; --- the drag ---------------------------------------------------------------------------------

; Screen coordinates, unambiguously. CoordMode "Mouse" defaults to Client, and a handler that
; silently mixes client and screen coordinates is the same class of bug as the one above.
CursorPos() {
    pt := Buffer(8, 0)
    DllCall("GetCursorPos", "ptr", pt)
    return { x: NumGet(pt, 0, "int"), y: NumGet(pt, 4, "int") }
}

; The drag starts here, once, and every later frame is measured against what is captured now.
OnEnterSizeMove(wParam, lParam, msg, hwnd) {
    global GRAB, GRABBED
    Tally("WM_ENTERSIZEMOVE any")
    if (hwnd != BOX.Hwnd)
        return
    Tally("WM_ENTERSIZEMOVE on BOX")
    c := CursorPos()
    WinGetPos(&bx, &by, &bw, &bh, "ahk_id " BOX.Hwnd)
    GRAB := { x: c.x, y: c.y, l: bx, t: by, r: bx + bw, b: by + bh }
    GRABBED := true
}

OnBoxLButtonDown(wParam, lParam, msg, hwnd) {
    Tally("WM_LBUTTONDOWN any")
    if (hwnd != BOX.Hwnd)
        return
    Tally("WM_LBUTTONDOWN on BOX")
    ; HTCAPTION on a window with no caption. DefWindowProc reads the cursor position itself, so
    ; lParam is not needed. In mode B this is redundant — the hand-rolled hit-test already
    ; returns HTCAPTION for the middle — and the two must not fight, hence the guard.
    if (!FRAMELESS)
        PostMessage(WM_NCLBUTTONDOWN, HTCAPTION, 0, , "ahk_id " BOX.Hwnd)
    return 0
}

; WM_MOVING / WM_SIZING hand over a RECT in SCREEN coordinates. Everything below therefore stays
; in screen coordinates — no conversion, nothing to get backwards.
ReadRect(lParam) {
    return { l: NumGet(lParam, 0, "int"), t: NumGet(lParam, 4, "int")
           , r: NumGet(lParam, 8, "int"), b: NumGet(lParam, 12, "int") }
}
WriteRect(lParam, l, t, r, b) {
    NumPut("int", l, lParam, 0), NumPut("int", t, lParam, 4)
    NumPut("int", r, lParam, 8), NumPut("int", b, lParam, 12)
}

; Moving: the size is fixed, so the ANCHOR is what the user is choosing. Snap the ANCHOR, not
; the pixel — a 5% pixel grid and a 5% anchor grid are different things, and the anchor is what
; gets stored. Clamping to 0..100 is also what keeps the box inside its own screen: there is no
; separate bounds check, because an anchor outside 0..100 is the only way out of the picture.
OnBoxMoving(wParam, lParam, msg, hwnd) {
    Tally("WM_MOVING any")
    if (hwnd != BOX.Hwnd)
        return
    Tally("WM_MOVING on BOX")
    if (!GRABBED)
        Tally("!! WM_MOVING with NO GRAB")
    if (TRACING && TRACE.Length < 10) {
        MouseGetPos(&mgx, &mgy)
        tc := ReadRect(lParam)
        WinGetPos(&wgx, &wgy, , , "ahk_id " BOX.Hwnd)
        TRACE.Push("cursor " CursorPos().x "   proposed.l " tc.l "   window.x now " wgx)
    }
    pic := PictureRect()
    c := ReadRect(lParam)
    w := c.r - c.l, h := c.b - c.t
    slackX := pic.w - w, slackY := pic.h - h
    ; The proposal supplies the SIZE, which is stable during a move. The POSITION comes from the
    ; cursor — see the GRAB comment above for why reading it from the proposal eats the drag.
    cur := CursorPos()
    l := SnapMove(cur.x - (GRAB.x - GRAB.l), pic.x, pic.w, slackX, POS.ax)
    t := SnapMove(cur.y - (GRAB.y - GRAB.t), pic.y, pic.h, slackY, POS.ay)
    POS.ax := (slackX > 0) ? Round((l - pic.x) / slackX * 100) : POS.ax
    POS.ay := (slackY > 0) ? Round((t - pic.y) / slackY * 100) : POS.ay
    WriteRect(lParam, l, t, l + w, t + h)
    RenderLive()
    return 1
}

; Sizing: the user is dragging an EDGE, so the edges snap. Only the edges wParam names are
; rewritten; the opposite edge must stay exactly where it is or the box crawls across the
; picture while being resized.
;
; Consequence worth knowing before this ships: an edge on the 5% grid does NOT guarantee an
; ANCHOR on the 5% grid — edges at 5% and 70% give w 65%, slack 35%, ax 14.3 -> 14. The live
; line flags it when it happens, so the rounding is visible rather than mysterious.
;
; Dragging an edge also converts a "keep current size" position (w/h = 0) into a fixed size.
; That is correct — the user just chose a size — but it is a real state change and the editor
; will need to say so.
OnBoxSizing(wParam, lParam, msg, hwnd) {
    global POS
    static WMSZ_LEFT := 1, WMSZ_RIGHT := 2, WMSZ_TOP := 3, WMSZ_TOPLEFT := 4
    static WMSZ_TOPRIGHT := 5, WMSZ_BOTTOM := 6, WMSZ_BOTTOMLEFT := 7, WMSZ_BOTTOMRIGHT := 8
    Tally("WM_SIZING any")
    if (hwnd != BOX.Hwnd)
        return
    Tally("WM_SIZING on BOX")
    pic := PictureRect()
    c := ReadRect(lParam)
    minW := Round(pic.w * MIN_PCT / 100), minH := Round(pic.h * MIN_PCT / 100)

    left   := (wParam = WMSZ_LEFT || wParam = WMSZ_TOPLEFT || wParam = WMSZ_BOTTOMLEFT)
    right  := (wParam = WMSZ_RIGHT || wParam = WMSZ_TOPRIGHT || wParam = WMSZ_BOTTOMRIGHT)
    top    := (wParam = WMSZ_TOP || wParam = WMSZ_TOPLEFT || wParam = WMSZ_TOPRIGHT)
    bottom := (wParam = WMSZ_BOTTOM || wParam = WMSZ_BOTTOMLEFT || wParam = WMSZ_BOTTOMRIGHT)

    ; Each dragged edge is derived from the CURSOR and where that edge was when the drag began,
    ; for the same reason the move is — the proposal is incremental and feeds back on itself.
    ; The edges NOT being dragged are taken from the proposal, where they are stable.
    cur := CursorPos()
    l := c.l, t := c.t, r := c.r, b := c.b
    ; The OPPOSITE edge is held exactly where it is and the SIZE is what snaps. Snapping the
    ; dragged edge instead made the resulting size depend on where the opposite edge happened
    ; to sit, which is how a 5% grid produced a 48%-wide box.
    if (left) {
        raw := r - Clamp(cur.x - (GRAB.x - GRAB.l), pic.x, pic.x + pic.w)
        l := r - Max(minW, Min(r - pic.x, SnapSize(raw, pic.w)))
    }
    if (right) {
        raw := Clamp(cur.x - (GRAB.x - GRAB.r), pic.x, pic.x + pic.w) - l
        r := l + Max(minW, Min(pic.x + pic.w - l, SnapSize(raw, pic.w)))
    }
    if (top) {
        raw := b - Clamp(cur.y - (GRAB.y - GRAB.t), pic.y, pic.y + pic.h)
        t := b - Max(minH, Min(b - pic.y, SnapSize(raw, pic.h)))
    }
    if (bottom) {
        raw := Clamp(cur.y - (GRAB.y - GRAB.b), pic.y, pic.y + pic.h) - t
        b := t + Max(minH, Min(pic.y + pic.h - t, SnapSize(raw, pic.h)))
    }

    WriteRect(lParam, l, t, r, b)
    POS := RectToPct({ x: l, y: t, w: r - l, h: b - t }, pic, POS)
    RenderLive()
    return 1
}

; Snap the LEADING EDGE of a moving box, and clamp it so the box cannot leave the picture.
; `v` and `origin` are absolute; `slack` is how far the box can travel; `prevAnchor` is what to
; fall back on when there is no slack at all (a full-width box has no anchor to choose).
SnapMove(v, origin, span, slack, prevAnchor) {
    if (slack <= 0)
        return origin + Round(slack * prevAnchor / 100)
    lo := origin, hi := origin + slack
    if (!SNAP_PCT)
        return Round(Max(lo, Min(hi, v)))
    if (SNAP_MODE = "anchor")
        return origin + Round(slack * SnapPct((v - origin) / slack * 100) / 100)
    best := SnapEdge(v, origin, span)                  ; the picture's own grid
    if (SNAP_MODE = "magnet") {
        ; flush-left, centred, flush-right — the three the anchor model names exactly, and the
        ; three the edge grid cannot always reach.
        for stop in [lo, origin + Round(slack / 2), hi] {
            if (Abs(stop - v) < Abs(best - v))
                best := stop
        }
    }
    return Round(Max(lo, Min(hi, best)))
}

Clamp(v, lo, hi) {
    return Max(lo, Min(hi, v))
}

SnapPct(v) {
    ; Guarded at its own door, not only by the caller. It is reached today solely through
    ; SnapMove's "grid off" check, which is exactly the kind of guard that gets moved.
    if (!SNAP_PCT)
        return Max(0, Min(100, v))
    return Max(0, Min(100, Round(v / SNAP_PCT) * SNAP_PCT))
}

; Snap a SIZE, in pixels, against the picture dimension it is a fraction of. This is what a
; resize snaps now — NOT the edge. Snapping the edge made the size depend on where the opposite
; edge happened to be, so a 5% edge grid produced sizes like 48%.
SnapSize(px, span) {
    if (span <= 0)
        return px
    pct := px / span * 100
    if (SIZE_PCT)
        return Round(span * (Round(pct / SIZE_PCT) * SIZE_PCT) / 100)
    ; Magnet mode: 1% everywhere, with a wider pull toward the useful fractions.
    ;
    ; A magnet must beat the RAW value, not the already-rounded one. Compared against the 1%
    ; grid the magnet can never win — rounding is always within 0.5% and the magnet is up to
    ; MAGNET_RADIUS away — so the pull silently did nothing.
    best := Round(pct)
    nearest := MAGNET_RADIUS + 1
    for m in SIZE_MAGNETS {
        if (Abs(m - pct) <= MAGNET_RADIUS && Abs(m - pct) < nearest) {
            nearest := Abs(m - pct)
            best := m
        }
    }
    return Round(span * best / 100)
}

; Snap an absolute edge to the picture's own 5% grid, and clamp it inside the picture. Clamping
; AFTER the snap is what stops a drag past the edge leaving the box half outside its own screen.
SnapEdge(v, origin, span) {
    if (!SNAP_PCT)
        return Round(Max(origin, Min(origin + span, v)))
    step := span * SNAP_PCT / 100
    snapped := origin + Round((v - origin) / step) * step
    return Round(Max(origin, Min(origin + span, snapped)))
}

; --- mode B: client rect == window rect --------------------------------------------------------
;
; Mode A (the default) keeps the system's WS_THICKFRAME. That frame lives in the NON-CLIENT area,
; so the blue fill the user sees is INSET from the rect being measured and stored. Q2 is by how
; much.
;
; Mode B zeroes the non-client area in WM_NCCALCSIZE so the fill covers the whole window rect and
; the picture stops lying — but a window with no non-client area also gets no border hit-tests
; from DefWindowProc, so the edges have to be hit-tested by hand. Both halves are needed; neither
; works alone.

RenderMode() {
    if (IsObject(BMODE))
        BMODE.Text := FRAMELESS ? "MODE B  ->  switch to A" : "MODE A  ->  switch to B"
    if (IsObject(BSNAP))
        BSNAP.Text := "size: " (SIZE_PCT ? SIZE_PCT "%" : "1% + magnets")
    if (IsObject(BGRID))
        BGRID.Text := SNAP_PCT ? "move: " SNAP_PCT "%" : "move: off"
}

StartTrace() {
    global TRACE, TRACING
    TRACE := [], TRACING := true
    Note("--- armed: drag the box, the trace prints when you let go ---")
    Render()
}

; WM_EXITSIZEMOVE fires when the modal loop ends, which is the natural moment to read a trace
; back without needing a second button press mid-thought.
OnExitSizeMove(wParam, lParam, msg, hwnd) {
    global TRACING, GRABBED
    if (hwnd != BOX.Hwnd)
        return
    GRABBED := false
    if (!TRACING)
        return
    TRACING := false
    Note("--- trace: is the proposal ABSOLUTE (tracks drag start) or INCREMENTAL? ---")
    for line in TRACE
        Note("  " line)
    Render()
}

CycleSizeGrid() {
    global SIZE_PCT
    for i, v in SIZE_STEPS {
        if (v = SIZE_PCT) {
            SIZE_PCT := SIZE_STEPS[Mod(i, SIZE_STEPS.Length) + 1]
            break
        }
    }
    RenderMode()
    Note("size grid -> " (SIZE_PCT ? SIZE_PCT "%" : "1% + magnets at " )
       . (SIZE_PCT ? "" : "25/33/50/67/75/100"))
    Render()
}

CycleSnapMode() {
    global SNAP_MODE
    for i, m in SNAP_MODES {
        if (m = SNAP_MODE) {
            SNAP_MODE := SNAP_MODES[Mod(i, SNAP_MODES.Length) + 1]
            break
        }
    }
    RenderMode()
    Note("snap mode -> " SNAP_MODE)
    Render()
}

CycleGrid() {
    global SNAP_PCT
    for i, v in SNAP_STEPS {
        if (v = SNAP_PCT) {
            SNAP_PCT := SNAP_STEPS[Mod(i, SNAP_STEPS.Length) + 1]
            break
        }
    }
    RenderMode()
    Note("grid -> " (SNAP_PCT ? SNAP_PCT "%" : "off"))
    Render()
}

; WM_NCCALCSIZE is only consulted when the window is told to recalculate its frame.
FrameChanged() {
    DllCall("SetWindowPos", "ptr", BOX.Hwnd, "ptr", 0, "int", 0, "int", 0, "int", 0, "int", 0
          , "uint", SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE)
}

ToggleFrameless() {
    global FRAMELESS
    FRAMELESS := !FRAMELESS
    RenderMode()
    FrameChanged()
    ApplyPosToPicture()
    RaiseBox()
    Note("mode " (FRAMELESS ? "B  frameless, hand-rolled hit-test" : "A  system frame"))
    ReportFrameGap()
    Render()
}

OnBoxNcCalcSize(wParam, lParam, msg, hwnd) {
    if (hwnd != BOX.Hwnd || !FRAMELESS)
        return
    Tally("WM_NCCALCSIZE on BOX")
    ; Returning 0 with the proposed rectangle left untouched means "the client area IS the whole
    ; window rect".
    return 0
}

OnBoxNcHitTest(wParam, lParam, msg, hwnd) {
    Tally("WM_NCHITTEST any")
    if (hwnd != BOX.Hwnd || !FRAMELESS)
        return
    Tally("WM_NCHITTEST on BOX")
    ; lParam carries the cursor in SCREEN coordinates as a packed pair of SIGNED 16-bit values.
    ; A monitor to the left of the primary has negative screen coordinates, which is exactly
    ; where an unsigned read goes wrong, so sign-extend both halves.
    sx := (lParam & 0xFFFF), sy := ((lParam >> 16) & 0xFFFF)
    if (sx > 0x7FFF)
        sx -= 0x10000
    if (sy > 0x7FFF)
        sy -= 0x10000
    WinGetPos(&bx, &by, &bw, &bh, "ahk_id " BOX.Hwnd)
    onLeft   := (sx < bx + GRAB_PX), onRight  := (sx > bx + bw - GRAB_PX)
    onTop    := (sy < by + GRAB_PX), onBottom := (sy > by + bh - GRAB_PX)
    if (onTop)
        return onLeft ? HTTOPLEFT : onRight ? HTTOPRIGHT : HTTOP
    if (onBottom)
        return onLeft ? HTBOTTOMLEFT : onRight ? HTBOTTOMRIGHT : HTBOTTOM
    if (onLeft)
        return HTLEFT
    if (onRight)
        return HTRIGHT
    ; The middle is a title bar Windows cannot see. HTCAPTION here makes the OS start its move
    ; loop on the press with no WM_LBUTTONDOWN handler involved at all.
    return HTCAPTION
}

; --- the report --------------------------------------------------------------------------------

ReportFrameGap() {
    WinGetPos(&ww_x, &ww_y, &ww, &wh, "ahk_id " BOX.Hwnd)
    rc := Buffer(16, 0)
    DllCall("GetClientRect", "ptr", BOX.Hwnd, "ptr", rc)
    cw := NumGet(rc, 8, "int"), ch := NumGet(rc, 12, "int")
    gap := (ww - cw) / 2
    Note("Q2  window " ww "x" wh "   client " cw "x" ch "   inset " gap "px"
       . (gap = 0 ? "   <- picture is honest"
                  : "   <- the blue fill is SMALLER than the stored rect"))
}

; Set the box from percentages, read it straight back, and report anything that does not survive
; the trip. This is the DPI question (Q3) asked in the only way that can answer it: on the
; display it might break on.
RoundTripCheck() {
    cases := [ { ax:   0, ay:  50, w:  50, h: 100 }
             , { ax: 100, ay:  50, w:  33, h: 100 }
             , { ax:  50, ay:  50, w:  60, h:  60 }
             , { ax:   0, ay:   0, w:  25, h:  25 }
             , { ax: 100, ay: 100, w:  25, h:  25 }
             , { ax:  50, ay:  50, w: 100, h: 100 } ]   ; no slack: the anchor must be PRESERVED
    pic := PictureRect()
    bad := 0
    Note("--- round-trip (Q3), picture " pic.w "x" pic.h " ----------------")
    for c in cases {
        r := PctToRect(c, pic)
        MoveToScreenRect(BOX.Hwnd, G.Hwnd, r.x, r.y, r.w, r.h)
        got := RectToPct(BoxRect(), pic, c)
        ok := (got.ax = c.ax && got.ay = c.ay && got.w = c.w && got.h = c.h)
        if (!ok)
            bad += 1
        Note((ok ? "  ok    " : "  FAIL  ")
           . "ax " c.ax "/" got.ax "   ay " c.ay "/" got.ay
           . "   w " c.w "/" got.w "   h " c.h "/" got.h)
    }
    Note(bad = 0 ? "  all " cases.Length " round-tripped"
                 : "  " bad " of " cases.Length " LOST DATA")
    ApplyPosToPicture()
    Render()
}

Tally(key) {
    MSGCOUNT[key] := MSGCOUNT.Has(key) ? MSGCOUNT[key] + 1 : 1
}

Note(line) {
    NOTES.Push(line)
    if (NOTES.Length > 200)
        NOTES.RemoveAt(1)
}

; Two readouts on purpose. The live line is rewritten on every WM_MOVING — hundreds of times
; inside the OS's modal drag loop — so it has to be one short Text control. Rebuilding the whole
; log there would make the drag feel bad for a reason that is not the mechanism under test, and
; Q4 is exactly a question about how the drag feels.
RenderLive() {
    if (LIVE = "")
        return
    s := (FRAMELESS ? "B " : "A ") SubStr(SNAP_MODE, 1, 1) (SNAP_PCT ? SNAP_PCT : "-")
       . " ax " Fmt(POS.ax) "  ay " Fmt(POS.ay) "  w " Fmt(POS.w) "  h " Fmt(POS.h)
    ; Mod(x, 0) throws "Divide by zero" — and with no grid there is no grid to be off.
    off := ""
    if (SNAP_PCT && (Mod(POS.ax, SNAP_PCT) || Mod(POS.ay, SNAP_PCT)))
        off .= " anchor"
    if (SIZE_PCT && (Mod(POS.w, SIZE_PCT) || Mod(POS.h, SIZE_PCT)))
        off .= " size"
    if (off != "")
        s .= "   << OFF THE " SNAP_PCT "% GRID:" off
    LIVE.Value := s
}

Render() {
    RenderLive()
    if (REPORT = "")
        return
    out := ""
    for line in NOTES
        out .= (out = "" ? "" : "`r`n") line
    t := ""
    for k, v in MSGCOUNT
        t .= (t = "" ? "" : "   ") k " " v
    out .= "`r`nmsgs: " (t = "" ? "(none seen)" : t)
    out .= "`r`nBOX hwnd " BOX.Hwnd "   style 0x" Format("{:X}", WinGetStyle("ahk_id " BOX.Hwnd))
    REPORT.Value := out
}

Fmt(n) {
    return Format("{:3}", n)
}
