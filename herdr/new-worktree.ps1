# Create a worktree space from the repo of the focused pane's folder. Runs in a popup bound to
# prefix+alt+n. Replaces herdr's native new_worktree, which uses the focused space's repo, so from
# Main's shell tab after `z <repo>` it would not use that repo. worktree-copilot starts Copilot in it.
$ErrorActionPreference = 'Stop'

function Done([string]$message) {
    if ($message) { Write-Host $message }
    Read-Host 'Press Enter to close' | Out-Null
    exit
}

& "$PSScriptRoot\sweep-worktree-folders.ps1"

$cwd = $env:HERDR_ACTIVE_PANE_CWD
if (-not $cwd) { Done 'herdr did not pass the focused folder.' }
# The common dir is the main checkout's .git, also when standing in a linked worktree.
$common = git -C $cwd rev-parse --path-format=absolute --git-common-dir 2>$null
if ($LASTEXITCODE -or -not $common) { Done "Not in a git repo: $cwd" }
$repo = Split-Path $common

Write-Host "Repo: $repo`n"
$branch = Read-Host 'New branch (<type>/<work-item>-<desc>, mtfu/ is added)'
if (-not $branch) { Done 'Cancelled.' }

git -C $repo fetch origin --quiet 2>$null
if ($LASTEXITCODE) { Write-Host 'git fetch failed, using the refs you already have.' }
# Existing branches are checked out as typed; only new ones get the mtfu/ prefix.
git -C $repo show-ref --quiet --verify "refs/heads/$branch" 2>$null
$exists = -not $LASTEXITCODE
$remoteOnly = $false
if (-not $exists) { git -C $repo show-ref --quiet --verify "refs/remotes/origin/$branch" 2>$null; $exists = $remoteOnly = -not $LASTEXITCODE }
if (-not $exists -and -not $branch.StartsWith('mtfu/')) { $branch = "mtfu/$branch" }
Write-Host "Branch: $branch"

if ($remoteOnly) {
    # Cut the local branch from its remote, not the default branch.
    $base = "origin/$branch"
    Write-Host "Base: $base"
} else {
    $default = git -C $repo symbolic-ref --short refs/remotes/origin/HEAD 2>$null
    $base = Read-Host "Base$(if ($default) { " [$default]" })"
    if (-not $base) { $base = $default }
}

$createArgs = @('worktree', 'create', '--cwd', $repo, '--branch', $branch, '--focus')
if ($base) { $createArgs += '--base', $base }
$response = herdr @createArgs 2>&1 | Out-String | ConvertFrom-Json
if ($response.error) { Done "Create failed: $($response.error.message)" }
