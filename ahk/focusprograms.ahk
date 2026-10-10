#Requires AutoHotkey v2.0

; Activate the window if it exists, otherwise launch it and wait for it to appear.
FocusOrRun(exe, target) {
    id := "ahk_exe " exe
    if WinExist(id) {
        WinActivate  ; reuse the window WinExist just found, no second search
        return
    }
    try {
        Run target
    } catch Any as e {
        MsgBox "Could not start " target "`n" e.Message, "focusprograms", 0x10
        return
    }
    if WinWait(id, , 30)
        WinActivate
}

LocalAppData := EnvGet("LOCALAPPDATA")

!o::FocusOrRun("rider64.exe", LocalAppData "\Programs\Rider\bin\rider64.exe")
!y::FocusOrRun("brave.exe", A_ProgramFiles "\BraveSoftware\Brave-Browser\Application\brave.exe")
!u::FocusOrRun("WindowsTerminal.exe", "wt.exe")
!r::FocusOrRun("Obsidian.exe", LocalAppData "\Programs\Obsidian\Obsidian.exe")
