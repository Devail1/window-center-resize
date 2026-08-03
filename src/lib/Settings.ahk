#Requires AutoHotkey v2.0

SettingsDefaults() {
    return Map(
        "centerHotkey", "^+c",
        "resizeHotkey", "F9",
        "sizes", [ {w: 50, h: 50}, {w: 75, h: 75}, {w: 90, h: 90} ]
    )
}

ClampPercent(value) {
    if !IsNumber(value)
        return 50
    n := Round(value + 0)
    if (n > 100)
        return 100
    if (n < 10)
        return 10
    return n
}

SettingsLoad(iniPath) {
    s := SettingsDefaults()
    if !FileExist(iniPath)
        return s

    s["centerHotkey"] := IniRead(iniPath, "Hotkeys", "Center", s["centerHotkey"])
    s["resizeHotkey"] := IniRead(iniPath, "Hotkeys", "Resize", s["resizeHotkey"])

    sizes := []
    loop 3 {
        dw := s["sizes"][A_Index].w
        dh := s["sizes"][A_Index].h
        w := ClampPercent(IniRead(iniPath, "Sizes", "Width"  . A_Index, dw))
        h := ClampPercent(IniRead(iniPath, "Sizes", "Height" . A_Index, dh))
        sizes.Push({ w: w, h: h })
    }
    s["sizes"] := sizes
    return s
}

SettingsSave(iniPath, s) {
    IniWrite(s["centerHotkey"], iniPath, "Hotkeys", "Center")
    IniWrite(s["resizeHotkey"], iniPath, "Hotkeys", "Resize")
    loop 3 {
        IniWrite(s["sizes"][A_Index].w, iniPath, "Sizes", "Width"  . A_Index)
        IniWrite(s["sizes"][A_Index].h, iniPath, "Sizes", "Height" . A_Index)
    }
}
