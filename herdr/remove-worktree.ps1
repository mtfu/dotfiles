# Remove the focused space's worktree, then its branch. Runs in a popup bound to prefix+alt+d.
# Replaces herdr's native remove_worktree, which never deletes the branch and on Windows leaves an
# empty folder when the pane's processes still hold it (herdr runs git before they have exited).
$ErrorActionPreference = 'Stop'

function Confirm([string]$question) {
    (Read-Host "$question [y/N]") -match '^(y|yes|j|ja)$'
}

function Done([string]$message) {
    if ($message) { Write-Host $message }
    Read-Host 'Press Enter to close' | Out-Null
    exit
}

function Get-Workspace([string]$id) {
    (herdr workspace list | ConvertFrom-Json).result.workspaces | Where-Object workspace_id -eq $id
}

# Sets the Branch / worktree cell to '-' in every vault Stories.md row naming this branch (and, if the
# cell names a folder, this checkout). Writes LF; git normalizes line endings.
function Clear-StoryBranch([string]$branch, [string]$checkout) {
    $vault = if ($env:OBSIDIAN_VAULT) { $env:OBSIDIAN_VAULT } else { Join-Path $HOME 'Obsidian-Work' }
    $ai = Join-Path $vault 'AI'
    if (-not (Test-Path $ai)) { return }
    $norm = { param($p) $p.Trim().TrimEnd('\', '/').Replace('/', '\') }
    $target = & $norm $checkout
    foreach ($file in Get-ChildItem $ai -Recurse -Filter 'Stories.md') {
        $lines = [IO.File]::ReadAllLines($file.FullName)
        $changed = @()
        for ($i = 0; $i -lt $lines.Length; $i++) {
            $m = [regex]::Match($lines[$i], '^(\|.*\|\s*)([^|]*?)(\s*\|\s*)$')
            if (-not $m.Success) { continue }
            $ticks = @([regex]::Matches($m.Groups[2].Value, '`([^`]+)`') | ForEach-Object { $_.Groups[1].Value })
            if (-not $ticks -or $ticks[0] -ne $branch) { continue }
            $paths = @($ticks | Select-Object -Skip 1 | Where-Object { $_ -match '^[A-Za-z]:[\\/]' })
            if ($paths -and -not ($paths | Where-Object { (& $norm $_) -ieq $target })) { continue }
            $lines[$i] = $m.Groups[1].Value + '-' + $m.Groups[3].Value
            $changed += ($lines[$i] -split '\|')[2].Trim()
        }
        if (-not $changed) { continue }
        [IO.File]::WriteAllText($file.FullName, ($lines -join "`n") + "`n")
        $changed | ForEach-Object { Write-Host "Cleared Branch in $($file.Directory.Name)/Stories.md: $_" }
    }
}

& "$PSScriptRoot\sweep-worktree-folders.ps1"

$workspaceId = ($env:HERDR_ACTIVE_PANE_ID -split ':')[0]
$workspace = Get-Workspace $workspaceId
if (-not $workspace) { Done "No focused space found (pane '$env:HERDR_ACTIVE_PANE_ID')." }
$worktree = $workspace.worktree
if (-not $worktree -or -not $worktree.is_linked_worktree) {
    Done "'$($workspace.label)' is not a linked worktree. Use prefix+alt+x to close the space instead."
}

$checkout = $worktree.checkout_path
$repo = $worktree.repo_root
$branch = $null
if (Test-Path (Join-Path $checkout '.git')) { $branch = git -C $checkout branch --show-current }

Write-Host "Space:    $($workspace.label)"
Write-Host "Checkout: $checkout"
Write-Host "Branch:   $(if ($branch) { $branch } else { '(none/detached)' })"
Write-Host ''
if (-not (Confirm 'Remove this worktree and delete its branch?')) { Done 'Cancelled.' }

$removeArgs = @('worktree', 'remove', '--workspace', $workspaceId)
if (Test-Path (Join-Path $checkout '.git')) {
    $dirty = git -C $checkout status --porcelain
    if ($dirty) {
        Write-Host "`nUncommitted changes:"
        $dirty | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }
        if (-not (Confirm 'Discard them and remove anyway?')) { Done 'Cancelled.' }
        $removeArgs += '--force'
    }
}

$response = herdr @removeArgs 2>&1 | Out-String | ConvertFrom-Json
if ($response.error) {
    $message = $response.error.message
    $stillRegistered = (git -C $repo worktree list --porcelain) -contains "worktree $($checkout -replace '\\', '/')"
    if ($stillRegistered -or $message -notmatch 'Permission denied|not a working tree') {
        Done "Remove failed: $message"
    }

    # Git already removed the worktree but couldn't delete the folder while a process still had it as
    # its working directory. Herdr then restarts the space's shells inside that folder, which keeps it
    # locked, so close the space first, then wait for the folder to be released and delete it if empty.
    Write-Host 'Git removed the worktree, but the folder is still locked. Closing the space and retrying...'
    if (Get-Workspace $workspaceId) { herdr workspace close $workspaceId | Out-Null }
    $deadline = (Get-Date).AddSeconds(15)
    while (Test-Path $checkout) {
        if (Get-ChildItem -Force $checkout) { Done "Folder is not empty, left as is: $checkout" }
        try { Remove-Item $checkout } catch {
            if ((Get-Date) -gt $deadline) { Write-Host "Folder still locked; the next new or remove deletes it: $checkout"; break }
            Start-Sleep -Milliseconds 500
        }
    }
}
Write-Host 'Worktree removed.'

if (-not $branch) { Done }
git -C $repo branch -d $branch 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    try { Clear-StoryBranch $branch $checkout } catch { Write-Host "Stories.md not updated: $_" }
    Done "Branch '$branch' deleted."
}

# Squash-merged PRs leave the branch's own commits unmerged, so -d refuses.
Write-Host "`nBranch '$branch' has commits that are not in $(git -C $repo branch --show-current):"
git -C $repo log --oneline -10 "HEAD..$branch" | ForEach-Object { Write-Host "  $_" }
if (Confirm 'Force-delete it anyway?') {
    git -C $repo branch -D $branch | Out-Null
    Done "Branch '$branch' deleted."
}
Done "Branch '$branch' kept."
