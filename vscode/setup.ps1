param ([Parameter()] $path = "dotfiles")

New-Item -ItemType SymbolicLink -Force -Path $env:APPDATA/Code/User/settings.json -Target $env:USERPROFILE\$path\vscode\settings.json
New-Item -ItemType SymbolicLink -Force -Path $env:APPDATA/Code/User/keybindings.json -Target $env:USERPROFILE\$path\vscode\keybindings.json;
Get-Content $env:USERPROFILE\$path\vscode\extensions.txt | ForEach-Object {code --install-extension $_}

