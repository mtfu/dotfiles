
param ([Parameter()]$gitconfig = '.gitconfig', $path = "dotfiles")

New-Item -ItemType SymbolicLink -Force -Path $PROFILE -Target $env:USERPROFILE\$path\Profile.ps1;
New-Item -ItemType SymbolicLink -Force -Path $env:USERPROFILE/.gitconfig -Target $env:USERPROFILE\$path\$gitconfig;
New-Item -ItemType SymbolicLink -Force -Path $env:USERPROFILE/.gitignore_global -Target $env:USERPROFILE\$path\.gitignore_global 

## Install Vim and set HOME environment
[System.Environment]::SetEnvironmentVariable('HOME', "C:\Users\" + $env:username, [System.EnvironmentVariableTarget]::User);

New-Item -ItemType SymbolicLink -Force -Path $env:USERPROFILE/.vimrc -Target $env:USERPROFILE\$path\.vimrc
New-Item -ItemType SymbolicLink -Force -Path $env:USERPROFILE/.vimrc.minimal -Target $env:USERPROFILE\$path\.vimrc.minimal
New-Item -ItemType SymbolicLink -Force -Path $env:LOCALAPPDATA/nvim -Target $env:USERPROFILE\$path\.config\nvim
New-Item -ItemType SymbolicLink -Force -Path $env:USERPROFILE/.ideavimrc -Target $env:USERPROFILE\$path\.ideavimrc
New-Item -ItemType SymbolicLink -Force -Path $env:USERPROFILE/.confi/starfield.toml -Target $env:USERPROFILE\$path\.starfield.toml

