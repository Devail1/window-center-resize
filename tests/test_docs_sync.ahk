#Requires AutoHotkey v2.0
#Include "_harness.ahk"

; The settings-window screenshot exists TWICE - assets/ for the README, docs/ for the GitHub
; Pages landing page - kept equal by hand, with nothing enforcing it. Both references also
; hardcode a pixel width. Resize the window and all four drift apart silently, because no
; test compiles a README or an <img> tag. This is that test.
;
; Coverage limit: this guards the DECLARED width and that the two screenshot copies match,
; not that the screenshot depicts the current UI. A future restyle that happened to produce
; the same 334px width would leave a stale image in place and this suite would still pass
; green. It is not a screenshot-freshness guard.

root := A_ScriptDir "\.."

; PNG IHDR: 8-byte signature, 4-byte length, 4-byte type, then width as a BIG-ENDIAN uint32
; at byte offset 16.
PngWidth(path) {
    ; FileOpen throws an OSError (not a falsy return) when the file doesn't exist, so the
    ; whole body is wrapped: any failure to open or read means "not a readable PNG" -> 0.
    try {
        f := FileOpen(path, "r")
        if (!f)
            return 0
        b := Buffer(24, 0)
        f.RawRead(b, 24)
        f.Close()
        return (NumGet(b, 16, "UChar") << 24) | (NumGet(b, 17, "UChar") << 16)
             | (NumGet(b, 18, "UChar") << 8)  |  NumGet(b, 19, "UChar")
    } catch {
        return 0
    }
}

BytesEqual(pathA, pathB) {
    ; AssertEqual doesn't stop the script on failure, so this runs even when a prior
    ; readability assertion has already failed - a missing file must read as "not equal",
    ; not crash the suite before ReportAndExit can report the earlier failure by name.
    try {
        a := FileRead(pathA, "RAW"), b := FileRead(pathB, "RAW")
    } catch {
        return false
    }
    if (a.Size != b.Size)
        return false
    loop a.Size {
        if (NumGet(a, A_Index - 1, "UChar") != NumGet(b, A_Index - 1, "UChar"))
            return false
    }
    return true
}

; Finds width="N" on the <img> tag that references `needle`. Attribute order varies between
; the two files, so match on the tag, not on a fixed sequence.
DeclaredWidth(path, needle) {
    txt := FileRead(path, "UTF-8")
    if RegExMatch(txt, 'i)<img[^>]*' needle '[^>]*?width="(\d+)"', &m)
        return m[1] + 0
    return 0
}

; The landing page's version string is hand-typed and nothing else reads it: main.ahk is
; the source of truth, docs/index.html is served straight from `main` via GitHub Pages, and
; a stale version there is publicly visible next to a Download button that always resolves
; to the latest release. AppVersion/DocsVersion extract each copy so a mismatch fails by
; name instead of drifting silently, the same way the screenshot checks below do.
AppVersion(path) {
    txt := FileRead(path, "UTF-8")
    if RegExMatch(txt, 'APP_VERSION\s*:=\s*"([^"]+)"', &m)
        return m[1]
    return ""
}

DocsVersion(path) {
    txt := FileRead(path, "UTF-8")
    if RegExMatch(txt, 'v(\d+\.\d+\.\d+)', &m)
        return m[1]
    return ""
}

assetsPng := root "\assets\settings-window.png"
docsPng   := root "\docs\settings-window.png"

w := PngWidth(assetsPng)
AssertEqual(w > 0, true, "the assets screenshot is a readable PNG")
AssertEqual(PngWidth(docsPng) > 0, true, "the docs screenshot is a readable PNG")
AssertEqual(PngWidth(docsPng), w, "both screenshot copies are the same pixel width")
AssertEqual(BytesEqual(assetsPng, docsPng), true
          , "THE ONE THAT MATTERS: the two screenshot copies are byte-identical")

AssertEqual(DeclaredWidth(root "\README.md", "settings-window\.png"), w
          , "README declares the screenshot's real width")
AssertEqual(DeclaredWidth(root "\docs\index.html", "settings-window\.png"), w
          , "the landing page declares the screenshot's real width")

; Both extractors return "" when their regex stops matching, and "" == "" passes. Without this
; pre-assertion the version check below is vacuous: rename APP_VERSION and the suite stays green.
AssertEqual(AppVersion(root "\src\main.ahk") != "", true, "src/main.ahk declares a version")

AssertEqual(DocsVersion(root "\docs\index.html"), AppVersion(root "\src\main.ahk")
          , "the landing page's advertised version matches APP_VERSION")

ReportAndExit()
