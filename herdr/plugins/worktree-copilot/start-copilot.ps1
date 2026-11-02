# herdr event hook: start Copilot CLI in the root pane of a new worktree workspace, and hand it a task if one
# is waiting in %LOCALAPPDATA%\herdr-worktree-tasks\<branch-slug>.md (written by whoever created the worktree).
# Not 'Stop': Windows PowerShell turns redirected native stderr into a terminating error under it.
$ErrorActionPreference = 'Continue'
$herdr = if ($env:HERDR_BIN_PATH) { $env:HERDR_BIN_PATH } else { 'herdr' }

$payload = $env:HERDR_PLUGIN_EVENT_JSON | ConvertFrom-Json
if ($payload.PSObject.Properties['data']) { $payload = $payload.data }
if ($payload.already_open) { exit 0 }

$workspaceId = $payload.workspace.workspace_id
$panes = (& $herdr pane list --workspace $workspaceId | ConvertFrom-Json).result.panes
if ($panes | Where-Object agent) { exit 0 }
$paneId = ($panes | Select-Object -First 1).pane_id
if (-not $paneId) { throw "No pane in workspace $workspaceId" }

# Agent names must match [a-z][a-z0-9_-]{0,31} and be unique among live agents.
$source = if ($payload.worktree.branch) { $payload.worktree.branch } else { Split-Path $payload.worktree.path -Leaf }
$slug = ($source.ToLower() -replace '[^a-z0-9_-]+', '-').Trim('-')
$base = ('cp-' + $slug).Substring(0, [Math]::Min(29, 3 + $slug.Length)).TrimEnd('-')
$name = $base
# agent list omits names; agent get resolves a live name, so success means it is taken.
for ($i = 2; $null -ne (& $herdr agent get $name 2>$null); $i++) { $name = "$base-$i" }

# The new shell may not be at its prompt yet; agent start refuses a busy pane.
$started = $false
for ($attempt = 1; $attempt -le 10; $attempt++) {
    $output = & $herdr agent start $name --kind copilot --pane $paneId 2>&1
    if ($LASTEXITCODE -eq 0) { $started = $true; break }
    Start-Sleep -Seconds 2
}
if (-not $started) { throw "agent start failed for $paneId`: $output" }

# Task handoff. The prompt only points at the file, so no task text goes through shell quoting or gets split on
# newlines. Renamed afterwards so reopening the worktree doesn't run it again.
$task = Join-Path $env:LOCALAPPDATA "herdr-worktree-tasks\$slug.md"
if (-not (Test-Path $task)) { exit 0 }
& $herdr agent wait $name --until idle --timeout 120000 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "agent $name never became idle; task left in $task" }
$startedTask = [IO.Path]::ChangeExtension($task, '.started.md')
Move-Item $task $startedTask -Force
& $herdr agent prompt $name "Read the task in $startedTask and do it." | Out-Null
if ($LASTEXITCODE -ne 0) { throw "agent prompt failed for $name; task in $startedTask" }
# herdr can report idle before Copilot's input box handles Enter, leaving the prompt typed but unsent.
for ($attempt = 1; $attempt -le 3; $attempt++) {
    & $herdr agent wait $name --until working --timeout 10000 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { exit 0 }
    & $herdr agent send-keys $name enter | Out-Null
}
throw "agent $name never started on its task; prompt is typed in pane $paneId"
