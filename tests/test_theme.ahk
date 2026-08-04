#Requires AutoHotkey v2.0
#Include "_harness.ahk"
#Include "..\src\gui\Theme.ahk"

; --- Theme(): every key present in both modes -----------------------------------------------
for key in ["bg", "text", "hint", "header"] {
    AssertEqual(Theme("light").Has(key), true, "light theme has '" key "'")
    AssertEqual(Theme("dark").Has(key),  true, "dark theme has '" key "'")
}

; --- Values are bare RRGGBB, because Gui.BackColor and the 'c' font option require that ------
AssertEqual(RegExMatch(Theme("light")["bg"], "^[0-9A-Fa-f]{6}$") > 0, true
          , "light bg is bare 6-digit hex, no # and no 0x")
AssertEqual(RegExMatch(Theme("dark")["text"], "^[0-9A-Fa-f]{6}$") > 0, true
          , "dark text is bare 6-digit hex")

; --- The two modes are genuinely different --------------------------------------------------
AssertEqual(Theme("light")["bg"] != Theme("dark")["bg"], true
          , "light and dark do not share a background")

; --- An unknown mode must fall back to light, never crash and never return an empty map ------
AssertEqual(Theme("chartreuse")["bg"], Theme("light")["bg"]
          , "an unknown mode falls back to light")
AssertEqual(Theme("")["bg"], Theme("light")["bg"]
          , "an empty mode falls back to light")

; --- ResolveUiFont ---------------------------------------------------------------------------
; A font that certainly exists must be returned unchanged.
AssertEqual(ResolveUiFont("Segoe UI", "Tahoma"), "Segoe UI"
          , "an installed family is used as-is")

; NEGATIVE CONTROL. Without this the function could 'return preferred' unconditionally and
; every other assertion here would still pass.
AssertEqual(ResolveUiFont("ZZ No Such Face", "Segoe UI"), "Segoe UI"
          , "THE ONE THAT MATTERS: a missing family falls back instead of being used silently")

ReportAndExit()
