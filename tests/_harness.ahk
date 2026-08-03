#Requires AutoHotkey v2.0

global TESTS_RUN := 0
global TESTS_FAILED := 0
global FAIL_LOG := ""

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
