if not (RegExMatch(DllCall("GetCommandLine", "str"), " /restart(?!\S)")) {
	Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%",, UseErrorLevel
	ExitApp
}

Capslock::Esc
