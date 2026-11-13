# Reopen a closed space: pick a folder zoxide knows. Runs in a popup bound to prefix+shift+o.
# A linked worktree reopens as a worktree space (so prefix+alt+d and worktree-copilot still work),
# any other folder as a plain space. A worktree that already has a space is just focused. Plain
# spaces aren't detected: their reported path follows the pane's folder (Main after `z`), not the space.
$ErrorActionPreference = 'Stop'

function Normalize([string]$path) { $path.Replace('\\?\', '').Replace('/', '\').TrimEnd('\').ToLowerInvariant() }

$dir = zoxide query --list | fzf --prompt 'open space> ' --reverse
if (-not $dir) { exit }

$open = (herdr workspace list | ConvertFrom-Json).result.workspaces |
    Where-Object { $_.worktree.is_linked_worktree -and $_.label -ne 'Main' -and (Normalize $_.worktree.checkout_path) -eq (Normalize $dir) } |
    Select-Object -First 1
if ($open) {
    herdr workspace focus $open.workspace_id | Out-Null
    exit
}

$gitDir = git -C $dir rev-parse --path-format=absolute --git-dir 2>$null
$common = git -C $dir rev-parse --path-format=absolute --git-common-dir 2>$null
if ($gitDir -and $gitDir -ne $common) {
    $response = herdr worktree open --cwd (Split-Path $common) --path $dir --focus 2>&1 | Out-String | ConvertFrom-Json
    if (-not $response.error) { exit }
    Write-Host "Opening as a worktree failed ($($response.error.message)), opening as a plain space."
}
herdr workspace create --cwd $dir --focus | Out-Null
