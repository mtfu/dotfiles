$windowsTerminalSettingsPath = "$env:userprofile\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json";

New-Item -ItemType SymbolicLink -Force -Path $windowsTerminalSettingsPath -Target "$env:userprofile\dotfiles\windows-terminal\settings.json";
