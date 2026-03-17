Import-Module PSfzf

# Set Git Alias before post-git, to make auto-completion work
Set-Alias g git
Import-Module 'lazy-posh-git'

Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
Set-PSReadLineOption -BellStyle None -HistorySearchCursorMovesToEnd 
Set-PSReadLineOption -ShowToolTips
Set-PSReadLineOption -Colors @{ InlinePrediction = '#000055' }
#
# Move cursor
Set-PSReadLineKeyHandler -Chord Ctrl+a -Function BeginningOfLine
Set-PSReadLineKeyHandler -Chord Ctrl+e -Function EndOfLine
Set-PSReadLineKeyHandler -Chord Ctrl+b -Function BackwardChar
Set-PSReadLineKeyHandler -Chord Ctrl+f -Function ForwardChar
Set-PSReadLineKeyHandler -Chord Alt+b  -Function BackwardWord
Set-PSReadLineKeyHandler -Chord Alt+f  -Function NextWord

# Deleting
Set-PSReadLineKeyHandler -Chord Ctrl+h -Function BackwardDeleteChar
Set-PSReadLineKeyHandler -Chord Ctrl+w -Function BackwardKillWord
Set-PSReadLineKeyHandler -Chord Alt+d  -Function KillWord
Set-PSReadLineKeyHandler -Chord Ctrl+u -Function BackwardKillLine
Set-PSReadLineKeyHandler -Chord Ctrl+k -Function KillLine

# Pasting
Set-PSReadLineKeyHandler -Chord Ctrl+y -Function Yank
Set-PSReadLineKeyHandler -Chord Alt+y  -Function YankPop

# Other useful bindings
Set-PSReadLineKeyHandler -Chord Ctrl+l -Function ClearScreen
Set-PSReadLineKeyHandler -Chord Ctrl+_ -Function Undo

Set-PSReadLineKeyHandler -Chord "Ctrl+p" -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptSuggestion()
    [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
}

Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PsFzfOption -PSReadlineChordSetLocation 'Alt+c'

$env:FZF_DEFAULT_COMMAND = 'fd --type f --color=never --hidden --follow -E .git/*'
$env:FZF_DEFAULT_OPTS = '--no-height --color=bg+:#343d46,gutter:-1,pointer:#ff3c3c,info:#0dbc79,hl:#0dbc79,hl+:#23d18b'
$env:FZF_CTRL_T_COMMAND = "$env:FZF_DEFAULT_COMMAND"
$env:FZF_CTRL_T_OPTS = "--preview 'bat --color=always --line-range :50 {}'"
$env:FZF_ALT_C_COMMAND = 'fd --type d . --color=never --hidden --follow -E .git/*'


function choco {
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    & choco.exe @args
}

function weather {
    param([string]$location = "aarhus")
    curl "https://wttr.in/$location"
}

function vs {
    param (
        [PSDefaultValue(Help = 'Current directory')]
        [string[]] $SearchPath = '.',
        [PSDefaultValue(Help = 'Current depth')]
        $Depth = 1, 
        [PSDefaultValue(Help = 'Max depth')]
        $Max = 5
    )
    $item = Get-ChildItem "*.sln" -Depth $Depth -Path $SearchPath | Select-Object -First 1
    if ($item) {
        Invoke-Expression "rs $item"
        return
    }
    if ($Depth -ge $Max) {
        Write-Host "not found at depth $Depth"
        return
    }

    $Depth = $Depth + 1
    return vs -depth $Depth -Max $Max
}

function touch {
    if (!$args[0]) { throw "No filename supplied" }
    if (Test-Path $args[0]) { (Get-Item $args[0]).LastWriteTime = Get-Date }
    else { New-Item -ItemType File -Name $args[0] }
}

function which ($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function sr {
    Set-Location 'C:\repos'
}

function nGuid {
    $guid = [guid]::NewGuid().ToString()
    Write-Host $guid
    $guid | clip
}

# Alias
Set-Alias vim nvim
Set-Alias ll ls
Set-Alias htop ntop
Set-Alias grep findstr
# Set-Alias tig 'C:\Program Files\Git\usr\bin\tig.exe'
# Set-Alias less 'C:\Program Files\Git\usr\bin\less.exe'
Set-Alias lg lazygit
Set-Alias v vim
Set-Alias ws 'C:\Users\Epico_mtfu\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\JetBrains Toolbox\WebStorm.lnk'
Set-Alias rs 'C:\Users\Epico_mtfu\AppData\Local\Programs\Rider\bin\rider64.exe'

# Env
$env:GIT_SSH = "C:\Windows\system32\OpenSSH\ssh.exe"

# Git
function ci { 
    git commit $args 
}
function cia {
    git commit --amend $args 
}

# Runners
function nr {
    npm run $args 
}
function dn {
    dotnet watch $args 
}

# Leverage PSFzf
function fua {
    Invoke-FuzzyGitStatus | % { git add $_ } 
}
function fur {
    Invoke-FuzzyGitStatus | % { git reset $_ }
}
function fuc {
    Invoke-FuzzyGitStatus | % { git checkout $_ }
}


# Docker
function fcon {
    $CONTAINER = (docker ps | Select-String -Pattern "CONTAINER" -NotMatch | ForEach-Object { ($_ -split " ")[-1] } | Out-String).Trim() | fzf
    return $CONTAINER;
}

function fexec {
    $CONTAINER = fcon
    if (-not [string]::IsNullOrEmpty($CONTAINER)) {
        docker exec -it $CONTAINER bash
    }
}

function flog {
    $CONTAINER = fcon
    if (-not [string]::IsNullOrEmpty($CONTAINER)) {
        docker logs $CONTAINER | less
    }
}



# Enable completion for winget
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
    $Local:word = $wordToComplete.Replace('"', '""')
    $Local:ast = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

$localAliasFile = "$HOME\PowerShell\machine.local.ps1"
if (Test-Path $localAliasFile) {
    . $localAliasFile
    Write-Host "Loaded machine.local.ps1" -ForegroundColor DarkGray
}


function Invoke-Starship-PreCommand {
    $esc = [char]27
    # OSC 9;9 for Windows Terminal directory tracking
    [Console]::Write("$esc]9;9;$($PWD.Path)$esc\")
    # Set terminal title
    [Console]::Write("$esc]0;PS> $PWD$esc\")
}


Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init powershell | Out-String) })
