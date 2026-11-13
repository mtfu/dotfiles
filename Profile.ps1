Import-Module PSfzf

# Set Git Alias before post-git, to make auto-completion work
Set-Alias g git
Import-Module 'lazy-posh-git'
# lazy-posh-git only loads posh-git on cd, so load it when the shell starts inside a repo
$gitRoot = $PWD.ProviderPath
while ($gitRoot -and -not (Test-Path (Join-Path $gitRoot '.git'))) { $gitRoot = Split-Path $gitRoot }
if ($gitRoot) { Import-Module posh-git }
Remove-Variable gitRoot

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

$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'

$env:FZF_DEFAULT_COMMAND = 'fd --type f --color=never --hidden --follow -E .git/*'
$env:FZF_DEFAULT_OPTS = '--no-height --color=bg+:#343d46,gutter:-1,pointer:#ff3c3c,info:#0dbc79,hl:#0dbc79,hl+:#23d18b'
$env:FZF_CTRL_T_COMMAND = "$env:FZF_DEFAULT_COMMAND"
$env:FZF_CTRL_T_OPTS = "--preview 'bat --color=always --line-range :50 {}'"
$env:FZF_ALT_C_COMMAND = 'fd --type d . --color=never --hidden --follow -E .git/*'


if ($env:ChocolateyInstall)
{
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
}

function weather
{
    param([string]$location = "aarhus")
    curl "https://wttr.in/$location"
}

function vs
{
    param (
        [PSDefaultValue(Help = 'Current directory')]
        [string[]] $SearchPath = '.',
        [PSDefaultValue(Help = 'Current depth')]
        $Depth = 1, 
        [PSDefaultValue(Help = 'Max depth')]
        $Max = 5
    )
    $item = Get-ChildItem "*.sln" -Depth $Depth -Path $SearchPath | Select-Object -First 1
    if ($item)
    {
        & rs $item.FullName
        return
    }
    if ($Depth -ge $Max)
    {
        Write-Host "not found at depth $Depth"
        return
    }

    $Depth = $Depth + 1
    return vs -depth $Depth -Max $Max
}

function touch
{
    if (!$args[0])
    { throw "No filename supplied" 
    }
    if (Test-Path $args[0])
    { (Get-Item $args[0]).LastWriteTime = Get-Date 
    } else
    { New-Item -ItemType File -Name $args[0] 
    }
}

function which ($command)
{
    Get-Command -Name $command -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

# Markdown in the browser, mermaid included: same live-preview.nvim as <leader>mb, run headless
function mb
{
    param([Parameter(Mandatory)][string] $Path)
    $file = Get-Item -LiteralPath $Path -ErrorAction Stop
    $nvim = Start-Process nvim -WorkingDirectory $file.DirectoryName -WindowStyle Hidden -PassThru `
        -ArgumentList '--headless', "`"$($file.Name)`"", '-c', 'MarkdownPreview'
    try { Read-Host "Previewing $($file.Name) - press Enter to stop" | Out-Null }
    # finally also runs on Ctrl+C, so the headless nvim never outlives mb.
    finally { Stop-Process -Id $nvim.Id -ErrorAction SilentlyContinue }
}

function sr
{
    Set-Location 'C:\repos'
}

function nGuid
{
    $guid = [guid]::NewGuid().ToString()
    Write-Host $guid
    $guid | clip
}

function cpath
{
    pwd | Select-Object -ExpandProperty Path | clip
}

# Alias
Set-Alias vim nvim
Set-Alias ll ls
Set-Alias htop ntop
Set-Alias grep findstr
Set-Alias lg lazygit
Set-Alias v vim
Set-Alias ws webstorm
Set-Alias rs rider

# Env
$env:GIT_SSH = "C:\Windows\system32\OpenSSH\ssh.exe"

# Git
function ci
{ 
    git commit $args 
}
function cia
{
    git commit --amend $args 
}

# Runners
function nr
{
    npm run $args 
}
function dn
{
    dotnet watch $args 
}

# Leverage PSFzf
function fua
{
    Invoke-FuzzyGitStatus | % { git add $_ } 
}
function fur
{
    Invoke-FuzzyGitStatus | % { git reset $_ }
}
function fuc
{
    Invoke-FuzzyGitStatus | % { git checkout $_ }
}

# Kill whatever listens on a port: `killport 4710`, `4710, 3000 | killport`.
# Without a port, pick listening ports in fzf (Tab for several).
function killport
{
    param([Parameter(ValueFromPipeline)][int[]]$Port)

    begin { $ports = @() }
    process { $ports += $Port }
    end
    {
        if ($ports)
        {
            foreach ($n in $ports)
            {
                $procIds = Get-NetTCPConnection -LocalPort $n -State Listen -ErrorAction SilentlyContinue |
                    Select-Object -ExpandProperty OwningProcess -Unique
                if (-not $procIds) { Write-Warning "Nothing listens on port $n"; continue }
                foreach ($procId in $procIds)
                {
                    $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
                    Stop-Process -Id $procId
                    "Killed $($p.ProcessName) ($procId) on port $n"
                }
            }
            return
        }

        Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
            Sort-Object LocalPort -Unique |
            ForEach-Object {
                $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
                '{0,-6} {1,-7} {2}' -f $_.LocalPort, $_.OwningProcess, $p.ProcessName
            } |
            fzf --multi --header 'PORT   PID     PROCESS' |
            ForEach-Object { Stop-Process -Id ([int]($_ -split '\s+')[1]) -Confirm }
    }
}


# Docker
function fcon
{
    $CONTAINER = (docker ps | Select-String -Pattern "CONTAINER" -NotMatch | ForEach-Object { ($_ -split " ")[-1] } | Out-String).Trim() | fzf
    return $CONTAINER;
}

function fexec
{
    $CONTAINER = fcon
    if (-not [string]::IsNullOrEmpty($CONTAINER))
    {
        docker exec -it $CONTAINER bash
    }
}

function flog
{
    $CONTAINER = fcon
    if (-not [string]::IsNullOrEmpty($CONTAINER))
    {
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
if (Test-Path $localAliasFile)
{
    . $localAliasFile
    Write-Host "Loaded machine.local.ps1" -ForegroundColor DarkGray
}

function removeOrigFiles
{
    Get-ChildItem -Recurse -Filter '*.orig' | Remove-Item
}

function Invoke-Starship-PreCommand
{
    $esc = [char]27
    # OSC 9;9 for Windows Terminal directory tracking
    [Console]::Write("$esc]9;9;$($PWD.Path)$esc\")
    # Set terminal title
    [Console]::Write("$esc]0;PS> $PWD$esc\")
}

Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init powershell | Out-String) })
