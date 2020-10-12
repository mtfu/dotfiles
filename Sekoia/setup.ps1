New-Item -ItemType SymbolicLink -Path $env:USERPROFILE\hooks -Target $env:userprofile\dotfiles\sekoia\hooks;
git config --global core.hooksPath $env:USERPROFILE\hooks;

#choco
choco install microsoftazurestorageexplorer slack -y