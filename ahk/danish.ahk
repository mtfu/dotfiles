if not (RegExMatch(DllCall("GetCommandLine", "str"), " /restart(?!\S)")) {
	Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%",, UseErrorLevel
	ExitApp
}

:?*:,ae::æ
:?*:,oe::ø
:?*:,aa::å
:?*:,AE::Æ
:?*:,OE::Ø
:?*:,AA::Å
