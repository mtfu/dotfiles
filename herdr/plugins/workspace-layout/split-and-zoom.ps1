# herdr event hook: split a new workspace's root pane to the right and zoom the root pane.
# Not 'Stop': Windows PowerShell turns redirected native stderr into a terminating error under it.
$ErrorActionPreference = 'Continue'
$herdr = if ($env:HERDR_BIN_PATH) { $env:HERDR_BIN_PATH } else { 'herdr' }

$payload = $env:HERDR_PLUGIN_EVENT_JSON | ConvertFrom-Json
if ($payload.PSObject.Properties['data']) { $payload = $payload.data }

$workspaceId = $payload.workspace.workspace_id
$panes = @((& $herdr pane list --workspace $workspaceId | ConvertFrom-Json).result.panes)
# Only a fresh workspace: one already split (restored, or laid out by its creator) is left alone.
if ($panes.Count -ne 1) { exit 0 }
$rootPane = $panes[0].pane_id

& $herdr pane split $rootPane --direction right --no-focus | Out-Null
if ($LASTEXITCODE -ne 0) { throw "pane split failed for $rootPane" }
& $herdr pane zoom $rootPane --on | Out-Null
if ($LASTEXITCODE -ne 0) { throw "pane zoom failed for $rootPane" }
