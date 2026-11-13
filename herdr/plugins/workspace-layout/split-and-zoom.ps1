# herdr event hook: split a new workspace's root pane to the right, zoom it, run Copilot in it and nvim in the new pane.
# Not 'Stop': Windows PowerShell turns redirected native stderr into a terminating error under it.
$ErrorActionPreference = 'Continue'
$herdr = if ($env:HERDR_BIN_PATH) { $env:HERDR_BIN_PATH } else { 'herdr' }
. "$PSScriptRoot\..\copilot-agent.ps1"
trap { Write-PluginLog "workspace-layout: ERROR $_"; exit 1 }

$payload = $env:HERDR_PLUGIN_EVENT_JSON | ConvertFrom-Json
if ($payload.PSObject.Properties['data']) { $payload = $payload.data }

$workspaceId = $payload.workspace.workspace_id
$workspace = (& $herdr workspace get $workspaceId | ConvertFrom-Json).result.workspace
$panes = @((& $herdr pane list --workspace $workspaceId | ConvertFrom-Json).result.panes)
# herdr fills worktree for any space in a git repo; only linked worktrees get Copilot from worktree-copilot.
$linked = [bool]($workspace.worktree.is_linked_worktree -or $payload.workspace.worktree.is_linked_worktree)
Write-PluginLog "workspace-layout: workspace $workspaceId panes=$($panes.Count) linked_worktree=$linked"
# Only a fresh workspace: one already split (restored, or laid out by its creator) is left alone.
if ($panes.Count -ne 1) { exit 0 }
$rootPane = $panes[0].pane_id

$split = & $herdr pane split $rootPane --direction right --no-focus | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw "pane split failed for $rootPane" }
& $herdr pane zoom $rootPane --on | Out-Null
if ($LASTEXITCODE -ne 0) { throw "pane zoom failed for $rootPane" }

# Copilot in the root pane. Not in linked worktree spaces: worktree-copilot starts it there and hands it the task.
if (-not $linked) {
    try { Write-PluginLog "workspace-layout: started agent $(Start-CopilotAgent $herdr $rootPane ([string]$workspace.label)) in $rootPane" } catch { Write-PluginLog "workspace-layout: ERROR $_" }
}

# Start nvim in the new pane once its shell shows the prompt; on timeout, send it anyway (the shell buffers input).
$nvimPane = $split.result.pane.pane_id
if ($nvimPane) {
    & $herdr pane wait-output $nvimPane --match ([string][char]0x276F) --timeout 15000 | Out-Null
    & $herdr pane run $nvimPane nvim | Out-Null
}
