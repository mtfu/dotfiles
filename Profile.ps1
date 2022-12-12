Import-Module Terminal-Icons
Import-Module PSfzf
Import-Module posh-git

$env:HOME = $env:USERPROFILE

Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
Set-PSReadLineOption -BellStyle None -HistorySearchCursorMovesToEnd 

Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownARrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Chord "Ctrl+p" -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptSuggestion()
    [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
}

Set-PSReadLineOption -ShowToolTips
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -Colors @{ InlinePrediction = '#000055'}

Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
$env:FZF_DEFAULT_COMMAND='fd --type f --color=never --hidden --follow -E .git/*'
$env:FZF_DEFAULT_OPTS='--no-height --color=bg+:#343d46,gutter:-1,pointer:#ff3c3c,info:#0dbc79,hl:#0dbc79,hl+:#23d18b'
$env:FZF_CTRL_T_COMMAND="$env:FZF_DEFAULT_COMMAND"
$env:FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"
$env:FZF_ALT_C_COMMAND='fd --type d . --color=never --hidden --follow -E .git/*'
#
# For zoxide v0.8.0+
Invoke-Expression (& {
    $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
    (zoxide init --hook $hook powershell | Out-String)
})

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

function vs($depth = 0, $max = 5) {
  $item = Get-ChildItem "*.sln" -Depth $depth -Exclude *Test | Select-Object -First 1
  if ($item) {
    Invoke-Item $item
    return
  }
  if ($depth -ge $max) {
    Write-Host "not found at depth $depth"
    return
  }
  $depth = $depth + 1

  return vs -depth $depth -max $max
}

function touch {
    $file = $args[0]
    if($file -eq $null) {
        throw "No filename supplied"
    }

    if(Test-Path $file)
    {
        throw "file already exists"
    }
    else
    {
        # echo $null > $file
	New-Item -ItemType File -Name ($file)
    }
}

function which ($command) {
  Get-Command -Name $command -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function sr {
  Set-Location 'C:\repos'
}

# Alias
Set-Alias vim nvim
Set-Alias ll ls
Set-Alias g git
Set-Alias htop ntop
Set-Alias grep findstr
Set-Alias tig 'C:\Program Files\Git\usr\bin\tig.exe'
Set-Alias less 'C:\Program Files\Git\usr\bin\less.exe'
Set-Alias lg lazygit
Set-Alias v vim

# Git helpers
Function stand { git standup $args }
Function ci { git commit $args }
Function cia { git commit --amend $args }
Function rsh { git reset --hard $args }
Function p { git request-pull $args }
Function ri { git rebase -i $args }
#
# Runners
Function nr { npm run $args }
Function dn { dotnet watch $args }
#
# leverage PSFzf
Function fua {Invoke-FuzzyGitStatus | % { git add $_ }}
Function fur {Invoke-FuzzyGitStatus | % { git reset $_ }}
Function fuc {Invoke-FuzzyGitStatus | % { git checkout $_ }}

function Invoke-Starship-PreCommand {
  $host.ui.Write("`e]0; PS> $pwd `a")
}

Invoke-Expression (&starship init powershell)
