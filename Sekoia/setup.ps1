New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\hooks -Target $env:userprofile\dotfiles\sekoia\hooks;
$path = "$env:USERPROFILE\hooks".Replace('\', '\\')
Add-Content ~\.gitconfig-local "`n[Core]`n  hooksPath = $path"

#choco
choco install microsoftazurestorageexplorer slack -y
