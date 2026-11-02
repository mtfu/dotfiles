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

; Story viewer from the Obsidian vault: focus Brave if it is the active tab, else let the server open it.
; The server starts if needed, or opens the page and exits if one is already running.
StoryViewer() {
    SetTitleMatchMode 1
    if WinExist("Story viewer ahk_exe brave.exe") {
        WinActivate
        return
    }
    home := EnvGet("USERPROFILE")
    server := home "\dotfiles\story-viewer\server.mjs"
    ; Vault: STORY_VIEWER_VAULT if set (e.g. the home vault), else the work vault.
    vault := EnvGet("STORY_VIEWER_VAULT") || home "\Obsidian-Work"
    if !FileExist(server) {
        MsgBox "Story viewer not found:`n" server, "focusprograms", 0x10
        return
    }
    try Run 'node "' server '" --vault "' vault '"', vault, "Hide"
    catch Any as e {
        MsgBox "Could not start node`n" e.Message, "focusprograms", 0x10
        return
    }
    if WinWait("Story viewer ahk_exe brave.exe", , 5)
        WinActivate
}

LocalAppData := EnvGet("LOCALAPPDATA")

!r::FocusOrRun("rider64.exe", LocalAppData "\Programs\Rider\bin\rider64.exe")
!y::FocusOrRun("brave.exe", A_ProgramFiles "\BraveSoftware\Brave-Browser\Application\brave.exe")
!u::FocusOrRun("WindowsTerminal.exe", "wt.exe")
!o::FocusOrRun("Obsidian.exe", LocalAppData "\Programs\Obsidian\Obsidian.exe")
!s::StoryViewer()
