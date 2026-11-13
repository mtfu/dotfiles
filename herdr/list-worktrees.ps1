# List the linked worktrees of my repos, open as herdr spaces or not, and jump to the picked one:
# focus its space, or open it as a new space. Runs in a popup bound to prefix+alt+l.
$ErrorActionPreference = 'Stop'

$repoRoots = @(Get-ChildItem C:\repos -Directory) + (Get-Item "$env:USERPROFILE\dotfiles") |
    Where-Object { Test-Path (Join-Path $_.FullName '.git\worktrees') } |
    ForEach-Object FullName

function Normalize([string]$path) { $path.Replace('\\?\', '').Replace('/', '\').TrimEnd('\').ToLowerInvariant() }

$spaces = @{}
# A space's path follows its pane's folder, so Main after `z` into a worktree must not count as its space.
(herdr workspace list | ConvertFrom-Json).result.workspaces |
    Where-Object { $_.worktree.is_linked_worktree -and $_.label -ne 'Main' } |
    ForEach-Object { $spaces[(Normalize $_.worktree.checkout_path)] = $_ }

$worktrees = foreach ($repo in $repoRoots) {
    $entry = $null
    foreach ($line in (git -C $repo worktree list --porcelain) + '') {
        if ($line -like 'worktree *') { $entry = @{ Path = $line.Substring(9).Replace('/', '\'); Skip = $false } }
        elseif ($line -like 'branch refs/heads/*') { $entry.Branch = $line.Substring(18) }
        elseif ($line -in 'bare', 'prunable' -or $line -like 'prunable *') { $entry.Skip = $true }
        elseif (-not $line -and $entry) {
            if (-not $entry.Skip -and (Normalize $entry.Path) -ne (Normalize $repo)) {
                $space = $spaces[(Normalize $entry.Path)]
                [pscustomobject]@{
                    Repo   = Split-Path $repo -Leaf
                    RepoRoot = $repo
                    Branch = $entry.Branch
                    Space  = $space.number
                    SpaceId = $space.workspace_id
                    Agent  = $space.agent_status
                    Path   = $entry.Path
                }
            }
            $entry = $null
        }
    }
}

if (-not $worktrees) {
    Read-Host 'No worktrees found. Press Enter to close' | Out-Null
    exit
}

$worktrees = @($worktrees | Sort-Object Repo, Path)
$i = 0
$worktrees | ForEach-Object { $_ | Add-Member Pick (++$i) }
$worktrees | Format-Table Pick, Space, Repo, Branch, Agent, Path -AutoSize | Out-Host
Write-Host 'Space is empty for worktrees not open in herdr; picking one opens it as a new space.'

while ($true) {
    $answer = Read-Host 'Pick (Enter to close)'
    if (-not $answer) { exit }
    $pick = $worktrees | Where-Object { "$($_.Pick)" -eq $answer.Trim() }
    if (-not $pick) { Write-Host "No worktree '$answer'."; continue }

    if ($pick.SpaceId) { herdr workspace focus $pick.SpaceId | Out-Null; exit }
    $label = (Split-Path $pick.Path -Leaf) -replace '^wt-', ''
    $response = herdr worktree open --cwd $pick.RepoRoot --path $pick.Path --label $label --focus 2>&1 | Out-String
    $failure = ($response | ConvertFrom-Json -ErrorAction SilentlyContinue).error
    if (-not $failure) { exit }
    Write-Host "Open failed: $($failure.message)"
}