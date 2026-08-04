#Requires AutoHotkey v2.0

global TESTS_RUN := 0
global TESTS_FAILED := 0
global FAIL_LOG := ""

; An unhandled RUNTIME error in AutoHotkey pops a MODAL DIALOG and blocks forever —
; on a developer's desktop and in CI alike. The /ErrorStdOut command-line switch only
; covers LOAD-TIME errors (bad #Include, syntax). This handler covers runtime errors.
OnError(_UncaughtTestError)
_UncaughtTestError(err, mode) {
    FileAppend("UNCAUGHT: " err.Message " at line " err.Line "`n", "*")
    ExitApp(1)
    return 1        ; non-zero return suppresses AutoHotkey's default error dialog
}

AssertEqual(actual, expected, label) {
    global TESTS_RUN, TESTS_FAILED, FAIL_LOG
    TESTS_RUN += 1
    if (actual != expected) {
        TESTS_FAILED += 1
        FAIL_LOG .= "FAIL: " label "`n  expected: " expected "`n  actual:   " actual "`n"
    }
}

ReportAndExit() {
    global TESTS_RUN, TESTS_FAILED, FAIL_LOG
    FileAppend(FAIL_LOG . TESTS_RUN " run, " TESTS_FAILED " failed`n", "*")
    ExitApp(TESTS_FAILED > 0 ? 1 : 0)
}
