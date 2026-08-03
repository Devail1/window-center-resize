#Requires AutoHotkey v2.0

global RELEASES_API  := "https://api.github.com/repos/Devail1/window-center-resize/releases/latest"
global RELEASES_PAGE := "https://github.com/Devail1/window-center-resize/releases/latest"

CompareVersions(a, b) {
    pa := StrSplit(LTrim(a, "vV"), ".")
    pb := StrSplit(LTrim(b, "vV"), ".")
    loop 3 {
        na := (pa.Has(A_Index) && IsNumber(pa[A_Index])) ? pa[A_Index] + 0 : 0
        nb := (pb.Has(A_Index) && IsNumber(pb[A_Index])) ? pb[A_Index] + 0 : 0
        if (na > nb)
            return 1
        if (na < nb)
            return -1
    }
    return 0
}

FetchLatestVersion() {
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", RELEASES_API, false)
        req.SetRequestHeader("User-Agent", "window-center-resize")
        req.SetTimeouts(5000, 5000, 5000, 5000)
        req.Send()
        if (req.Status != 200)
            return ""
        if RegExMatch(req.ResponseText, '"tag_name"\s*:\s*"([^"]+)"', &m)
            return LTrim(m[1], "vV")
        return ""
    } catch {
        return ""
    }
}
