param ([parameter()]$gitconfig = '.gitconfig', $path = "dotfiles")

$env:home = "$userprofile"
$localgitconfig = "$env:userprofile/.gitconfig.local"

if (-not (test-path -path $localgitconfig -pathtype leaf)) {
		cp .gitconfig.local $localgitconfig
}

& '.\updateSymbolicLinks.ps1'; 


## Setup GIT_SSH
[System.Environment]::SetEnvironmentVariable('GIT_SSH', "C:\Windows\System32\OpenSSH\ssh.exe", [System.EnvironmentVariableTarget]::User);
#
# We want to expose Linux helpful commands like tig, less and xargs
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Git\usr\bin" , [System.EnvironmentVariableTarget]::Machine)

## Install PlugInstall
iwr -useb https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim |`
    ni "$(@($env:XDG_DATA_HOME, $env:LOCALAPPDATA)[$null -eq $env:XDG_DATA_HOME])/nvim-data/site/autoload/plug.vim" -Force;

function Install($moduleName) {
    Install-Module $moduleName  -Confirm:$False -Force;
}

Install("posh-git")
Install("PSfzf");
Install("posh-sshell");
Install("Terminal-Icons");

#SSH Agent
Get-WindowsCapability -Online | ? Name -like 'OpenSSH*';
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0;
Get-Service -Name ssh-agent | Set-Service -StartupType Automatic;

#TODO 2022-09-09 Requirement for using nvim-tree-sitter might be possible to remove this later on (Fix for an error)
npm install -g tree-sitter-cli 
