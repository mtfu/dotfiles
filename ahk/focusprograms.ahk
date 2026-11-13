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

; True if something answers HTTP on url.
ServerUp(url) {
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.SetTimeouts(200, 200, 200, 500)
        req.Open("GET", url, false)
        req.Send()
        return true
    }
    return false
}

; Story viewer from the Obsidian vault: start the server if needed, then open it in a new Brave tab.
StoryViewer() {
    url := "http://localhost:4710"
    probe := "http://127.0.0.1:4710"  ; localhost tries IPv6 first and costs ~2 s per check
    if !ServerUp(probe) {
        home := EnvGet("USERPROFILE")
        server := "C:\repos\story-viewer\server.mjs"
        ; Vault: STORY_VIEWER_VAULT if set (e.g. the home vault), else the work vault.
        vault := EnvGet("STORY_VIEWER_VAULT") || home "\Obsidian-Work"
        if !FileExist(server) {
            MsgBox "Story viewer not found:`n" server, "focusprograms", 0x10
            return
        }
        try Run 'node "' server '" --vault "' vault '" --no-open', vault, "Hide"
        catch Any as e {
            MsgBox "Could not start node`n" e.Message, "focusprograms", 0x10
            return
        }
        deadline := A_TickCount + 10000
        while !ServerUp(probe) {
            if (A_TickCount > deadline) {
                MsgBox "Story viewer did not start on " url, "focusprograms", 0x10
                return
            }
            Sleep 200
        }
    }
    try Run '"' Brave '" ' url
    catch Any as e {
        MsgBox "Could not start Brave`n" e.Message, "focusprograms", 0x10
        return
    }
    if WinWait("ahk_exe brave.exe", , 5)
        WinActivate
}

LocalAppData := EnvGet("LOCALAPPDATA")
Brave := A_ProgramFiles "\BraveSoftware\Brave-Browser\Application\brave.exe"

!r::FocusOrRun("rider64.exe", LocalAppData "\Programs\Rider\bin\rider64.exe")
!y::FocusOrRun("brave.exe", Brave)
!u::FocusOrRun("WindowsTerminal.exe", "wt.exe")
!o::FocusOrRun("Obsidian.exe", LocalAppData "\Programs\Obsidian\Obsidian.exe")
!s::StoryViewer()
