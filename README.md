#### Purpose of the repo
To easy get a new computer up and running with the same configuration as my other machines.

Contains installation scripts to download and install programs with choco and winget.
Creates a bunch of symbolic links, so it is easy to update the config between machines.
Configures the following:
vscode
git
neovim
neovim extensions
powershell
powershell extensions
ssh
ahk
windows-terminal
and a bunch of programs

1. Download CHOCO and GIT
2. choco install powershell-core -y
3. Run setupAll again in powershell core.
4. Run winget/setup.ps1, to install the newest version of windows terminal

# Git
Insert into gitconfig-local
[user]
    email = 
    name = 

# NEOVIM
To install extensions for neovim run :PlugInstall
