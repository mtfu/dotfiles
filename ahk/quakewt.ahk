if not (RegExMatch(DllCall("GetCommandLine", "str"), " /restart(?!\S)")) {
	Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%",, UseErrorLevel
	ExitApp
}

#SingleInstance force

WtHandle = ahk_exe WindowsTerminal.exe

; On CTRL+ALT+T press
^!t::
    WinGet, wList, List, %WtHandle%
    if !wList{ 
       Run, *RunAs %UserProfile%\AppData\Local\Microsoft\WindowsApps\wt.exe, , Max
       return
    }


    WinGet, mx, MinMax, %WtHandle%

    ; If window is minimized, restore it
    if (mx = -1)
    {
        WinRestore, %WtHandle%

        ; Uncomment these lines to overcome tmux/vim rendering bug
        ; ControlSend, , ^{VK42}, %WtHandle%
        ; ControlSend, , {VK52}, %WtHandle%
    }

    ; if window is active, minimize it
    else if WinActive(WtHandle)
    {
       WinMinimize, %WtHandle%
    }

    ; Otherwise focus it
    else
    {
        WinActivate, %WtHandle%
    }
Return