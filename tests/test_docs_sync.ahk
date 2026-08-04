#Requires AutoHotkey v2.0
#Include "_harness.ahk"

; The settings-window screenshot exists TWICE - assets/ for the README, docs/ for the GitHub
; Pages landing page - kept equal by hand, with nothing enforcing it. Both references also
; hardcode a pixel width. Resize the window and all four drift apart silently, because no
; test compiles a README or an <img> tag. This is that test.

root := A_ScriptDir "\.."

; PNG IHDR: 8-byte signature, 4-byte length, 4-byte type, then width as a BIG-ENDIAN uint32
; at byte offset 16.
PngWidth(path) {
    f := FileOpen(path, "r")
    if (!f)
        return 0
    b := Buffer(24, 0)
    f.RawRead(b, 24)
    f.Close()
    return (NumGet(b, 16, "UChar") << 24) | (NumGet(b, 17, "UChar") << 16)
         | (NumGet(b, 18, "UChar") << 8)  |  NumGet(b, 19, "UChar")
}

BytesEqual(pathA, pathB) {
    a := FileRead(pathA, "RAW"), b := FileRead(pathB, "RAW")
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

assetsPng := root "\assets\settings-window.png"
docsPng   := root "\docs\settings-window.png"

w := PngWidth(assetsPng)
AssertEqual(w > 0, true, "the assets screenshot is a readable PNG")
AssertEqual(PngWidth(docsPng), w, "both screenshot copies are the same pixel width")
AssertEqual(BytesEqual(assetsPng, docsPng), true
          , "THE ONE THAT MATTERS: the two screenshot copies are byte-identical")

AssertEqual(DeclaredWidth(root "\README.md", "settings-window\.png"), w
          , "README declares the screenshot's real width")
AssertEqual(DeclaredWidth(root "\docs\index.html", "settings-window\.png"), w
          , "the landing page declares the screenshot's real width")

ReportAndExit()
