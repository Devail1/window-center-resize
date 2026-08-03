#Requires AutoHotkey v2.0
#Include "_harness.ahk"
#Include "..\src\lib\UpdateCheck.ahk"

AssertEqual(CompareVersions("2.0.0", "2.0.0"),  0, "equal versions")
AssertEqual(CompareVersions("2.0.1", "2.0.0"),  1, "patch newer")
AssertEqual(CompareVersions("2.0.0", "2.0.1"), -1, "patch older")
AssertEqual(CompareVersions("2.1.0", "2.0.9"),  1, "minor beats patch")
AssertEqual(CompareVersions("10.0.0", "9.9.9"), 1, "numeric, not lexicographic")
AssertEqual(CompareVersions("2.0",   "2.0.0"),  0, "missing segments are zero")
AssertEqual(CompareVersions("v2.0.1","2.0.0"),  1, "a leading v is ignored")

ReportAndExit()
