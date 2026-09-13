#Requires AutoHotkey v2.0
#Include "_harness.ahk"
#Include "..\src\lib\Hotkeys.ahk"

AssertEqual(IsValidHotkey("^+c"),  true,  "ctrl+shift+c is valid")
AssertEqual(IsValidHotkey("F9"),   true,  "a bare function key is valid")
AssertEqual(IsValidHotkey("^!x"),  true,  "ctrl+alt+x is valid")
AssertEqual(IsValidHotkey("#Up"),  true,  "win+Up is valid")
AssertEqual(IsValidHotkey(""),     false, "empty string is invalid")
AssertEqual(IsValidHotkey("^"),    false, "modifiers alone are invalid")
AssertEqual(IsValidHotkey("^+!#"), false, "only modifiers is invalid")
AssertEqual(IsValidHotkey("NotAKey"), false, "an unknown key name is invalid")

; A bare single printable character registers `c::` and SWALLOWS that key system-wide —
; including in the settings box where the user would type the replacement — and it persists
; to the INI, so a restart reapplies it. It must be rejected.
; ⚠️ NAMED keys with no modifier must still pass: F9 is the DEFAULT resize hotkey.
AssertEqual(IsValidHotkey("c"),  false, "a bare single letter with no modifier is invalid")
AssertEqual(IsValidHotkey("1"),  false, "a bare single digit with no modifier is invalid")
AssertEqual(IsValidHotkey("^c"), true,  "the same letter WITH a modifier is valid")
AssertEqual(IsValidHotkey("F9"), true,  "F9 (the default resize hotkey) stays valid bare")
AssertEqual(IsValidHotkey("Up"), true,  "a bare named key is valid")

; REGRESSION GUARD: AHK v2 cannot unregister a hotkey, so a validation probe registered in
; the DEFAULT context would permanently overwrite a live binding's callback and leave it
; disabled. Validation must therefore leave nothing addressable in the default context.
; Hotkey(name, "On") throws for a hotkey that does not exist in the current context.
IsValidHotkey("^+F13")
leaked := true
try
    Hotkey("^+F13", "On")
catch
    leaked := false
AssertEqual(leaked, false, "validation must not register in the default context")

; --- What gets registered, and in what order -------------------------------------------------
; AHK has no way to unregister a hotkey, and re-registering one SILENTLY overwrites the
; earlier binding's callback. With a list of positions plus the resize key, a duplicate no
; longer needs a hand-edited file to happen — so the decision about what to register is made
; here, where it can be tested, rather than inside the loop that calls Hotkey().
plan := PlanHotkeyRegistration(Map(
    "resizeHotkey", "F9",
    "positions", [ { name: "Center", hotkey: "^+c", ax: 50, ay: 50, w: 0, h: 0 }
                 , { name: "Left",   hotkey: "^!Left", ax: 0, ay: 50, w: 50, h: 100 } ]))
AssertEqual(plan.Length,      3,          "two positions and the resize key")
AssertEqual(plan[1].key,      "F9",       "the resize key is claimed first")
AssertEqual(plan[1].action,   "resize",   "the resize key is tagged as itself")
AssertEqual(plan[2].key,      "^+c",      "positions follow, in list order")
AssertEqual(plan[2].action,   "position", "a position is tagged as one")
AssertEqual(plan[2].index,    1,          "a position carries its index")

; An unbound position is legal and simply does not register.
plan2 := PlanHotkeyRegistration(Map(
    "resizeHotkey", "F9",
    "positions", [ { name: "Nameless", hotkey: "", ax: 50, ay: 50, w: 0, h: 0 } ]))
AssertEqual(plan2.Length, 1,    "an unbound position registers nothing")
AssertEqual(plan2[1].key, "F9", "the resize key still registers")

; A duplicate is DROPPED rather than registered over the top of the binding it would kill.
plan3 := PlanHotkeyRegistration(Map(
    "resizeHotkey", "F9",
    "positions", [ { name: "A", hotkey: "^+c", ax: 50, ay: 50, w: 0, h: 0 }
                 , { name: "B", hotkey: "^+c", ax: 0,  ay: 0,  w: 50, h: 50 }
                 , { name: "C", hotkey: "F9",  ax: 0,  ay: 0,  w: 50, h: 50 } ]))
AssertEqual(plan3.Length,    2,          "duplicates are dropped, not stacked")
AssertEqual(plan3[1].key,    "F9",       "a position cannot steal the resize key")
AssertEqual(plan3[1].action, "resize",   "the resize key keeps its own action")
AssertEqual(plan3[2].index,  1,          "between two equal positions the first keeps the key")
AssertEqual(plan3[2].action, "position", "and it is still a position")

; Invalid hotkeys never reach Hotkey(), which would throw.
plan4 := PlanHotkeyRegistration(Map(
    "resizeHotkey", "F9",
    "positions", [ { name: "Bad", hotkey: "notakey", ax: 50, ay: 50, w: 0, h: 0 } ]))
AssertEqual(plan4.Length, 1, "an unregisterable hotkey is skipped")

; --- Reporting a conflict, as opposed to silently surviving one -----------------------------
; PlanHotkeyRegistration DROPS a duplicate so the app still works. That is the right runtime
; behaviour and the wrong settings-window behaviour: the user typed two things and one of them
; would quietly never happen. The window refuses the save instead, so this finds the clash and
; says which two rows it is between.

P(name, hk) => { name: name, hotkey: hk, ax: 50, ay: 50, w: 0, h: 0 }

AssertEqual(FindHotkeyConflict("F9", [P("Center", "^+c"), P("Left", "^!Left")]) = ""
          , true, "no clash reports nothing")

c1 := FindHotkeyConflict("F9", [P("Center", "^+c"), P("Left", "^+c")])
AssertEqual(c1 = "",            false,      "two positions on one key is a clash")
AssertEqual(c1.key,             "^+c",      "the clash names the key")
AssertEqual(c1.firstKind,       "position", "the earlier row is reported first")
AssertEqual(c1.firstIndex,      1,          "the earlier row's index")
AssertEqual(c1.secondIndex,     2,          "the later row's index")

; Resize is claimed BEFORE positions, so it is the one that keeps the key and the position is
; the one reported as losing it.
c2 := FindHotkeyConflict("F9", [P("Center", "^+c"), P("Grow", "F9")])
AssertEqual(c2.firstKind,   "resize",   "resize holds the key it shares with a position")
AssertEqual(c2.secondKind,  "position", "the position is the one that would be dropped")
AssertEqual(c2.secondIndex, 2,          "and it says which position")

; An unbound row is legal — a position added but not yet given a key — so two of them are not
; a clash with each other.
AssertEqual(FindHotkeyConflict("F9", [P("A", ""), P("B", "")]) = ""
          , true, "unbound rows do not clash")

; ⭐ Hotkey names are CASE-INSENSITIVE to AutoHotkey: ^+c and ^+C are the same key, and
; registering both means the second silently replaces the first. A case-sensitive comparison
; would call this pair fine and ship the exact silent overwrite the check exists to prevent.
c3 := FindHotkeyConflict("F9", [P("A", "^+c"), P("B", "^+C")])
AssertEqual(c3 = "", false, "^+c and ^+C are the same key")

; Same for the registration plan, which had the same hole.
plan4 := PlanHotkeyRegistration(Map("resizeHotkey", "F9"
    , "positions", [P("A", "^+c"), P("B", "^+C")]))
AssertEqual(plan4.Length, 2, "a case-different duplicate is dropped from the plan too")

; ⭐ MODIFIER ORDER is not meaning either. The native Hotkey control renders ^+c and reads it
; back as +^c — so merely SELECTING a row rewrote the stored value, and two rows holding the
; same key in different orders would have passed the clash check and produced exactly the
; silent overwrite it exists to prevent.
AssertEqual(NormalizeHotkeyName("^+c"), NormalizeHotkeyName("+^c")
          , "modifier order does not make a second key")
AssertEqual(NormalizeHotkeyName("^!#+F1"), NormalizeHotkeyName("+#!^f1")
          , "all four modifiers canonicalise regardless of the order typed")
c5 := FindHotkeyConflict("F9", [P("A", "^+c"), P("B", "+^c")])
AssertEqual(c5 = "", false, "^+c clashes with +^c")

; ⛔ A direction prefix BINDS to the modifier after it, so <^+c (left-ctrl, shift) and ^<+c
; (ctrl, left-shift) are DIFFERENT keys. Sorting those would invent an equivalence and refuse a
; legal save, so anything carrying < or > is compared literally.
AssertEqual(NormalizeHotkeyName("<^+c") = NormalizeHotkeyName("^<+c"), false
          , "a direction prefix is not sorted away")
c6 := FindHotkeyConflict("F9", [P("A", "<^c"), P("B", "<^C")])
AssertEqual(c6 = "", false, "a direction-prefixed key still clashes with itself")

; Surrounding whitespace in a hand-edited INI is not a different key either.
c4 := FindHotkeyConflict("F9", [P("A", "^+c"), P("B", " ^+c ")])
AssertEqual(c4 = "", false, "whitespace does not make a second key")

ReportAndExit()
