param ([Parameter()]$gitconfig = '.gitconfig.windows', $path = "dotfiles")

New-Item -ItemType SymbolicLink -Path $profile -Target $env:USERPROFILE\$path\Profile.ps1;
New-Item -ItemType SymbolicLink -Path $env:USERPROFILE/.gitconfig -Target $env:USERPROFILE\$path\$gitconfig;

Install-Module Get-ChildItemColor -AllowClobber -Confirm:$False -Force;

function Install($moduleName) {
    Install-Module $moduleName  -Confirm:$False -Force;
}

Install("posh-git")
Install("oh-my-posh");
Install("PSfzf");
Install("ZLocation");

#SSH Agent
Get-WindowsCapability -Online | ? Name -like 'OpenSSH*';
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0;
Get-Service -Name ssh-agent | Set-Service -StartupType Automatic;
