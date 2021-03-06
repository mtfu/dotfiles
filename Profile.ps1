Import-Module Get-ChildItemColor
Import-Module posh-git
Import-Module oh-my-posh
Import-Module PSfzf

Set-PoshPrompt -Theme  powerlevel10k_lean
Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'

if (! (Get-Process | Where-Object { $_.Name -eq 'ssh-agent' })) {
    Start-SshAgent
}

## My own scripts
function vs {
    Invoke-Item (Get-ChildItem *.sln -Recurse | Select-Object -First 1)
}

function sr {
    Set-Location 'C:\repos'
}

function t($command) {
    wsl.exe dstask $command
}
# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
