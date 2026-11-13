# herdr event hook: start Copilot CLI in the root pane of a new worktree workspace.
# If a task is waiting in %LOCALAPPDATA%\herdr-worktree-tasks\<branch-slug>.md
# (written by whoever created the worktree), hand it to the agent.

# Not 'Stop': Windows PowerShell turns redirected native stderr into a terminating error under it.
$ErrorActionPreference = 'Continue'

$herdr = if ($env:HERDR_BIN_PATH) { $env:HERDR_BIN_PATH } else { 'herdr' }
. "$PSScriptRoot\..\copilot-agent.ps1"

function Log([string]$message) {
    Write-PluginLog "worktree-copilot: $message"
}

trap {
    Log "ERROR $_"
    exit 1
}


# --- Read the event ---

$payload = $env:HERDR_PLUGIN_EVENT_JSON | ConvertFrom-Json
if ($payload.PSObject.Properties['data']) {
    $payload = $payload.data
}

$workspaceId = $payload.workspace.workspace_id
Log "workspace $workspaceId branch '$($payload.worktree.branch)' already_open=$($payload.already_open)"

if ($payload.already_open) {
    Log 'skip, already open'
    exit 0
}


# --- Pick the pane ---

$panes = (& $herdr pane list --workspace $workspaceId | ConvertFrom-Json).result.panes

$agentPanes = $panes | Where-Object agent
if ($agentPanes) {
    Log "skip, a pane already has an agent ($($agentPanes.pane_id -join ', '))"
    exit 0
}

$paneId = ($panes | Select-Object -First 1).pane_id
if (-not $paneId) {
    throw "No pane in workspace $workspaceId"
}


# --- Start Copilot ---

$source = if ($payload.worktree.branch) {
    $payload.worktree.branch
} else {
    Split-Path $payload.worktree.path -Leaf
}

$name = Start-CopilotAgent $herdr $paneId $source
Log "started agent $name in $paneId"


# --- Hand over the task ---
# The prompt only points at the file, so no task text goes through shell quoting
# or gets split on newlines. The file is renamed afterwards so reopening the
# worktree doesn't run it again.

# The task file is named by this slug (same rule as the agent name).
$slug = ($source.ToLower() -replace '[^a-z0-9_-]+', '-').Trim('-')
$task = Join-Path $env:LOCALAPPDATA "herdr-worktree-tasks\$slug.md"

if (-not (Test-Path $task)) {
    Log "no task file $task"
    exit 0
}

$wait = & $herdr agent wait $name --until idle --timeout 120000 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "agent $name never became idle ($wait); task left in $task"
}

$startedTask = [IO.Path]::ChangeExtension($task, '.started.md')
Move-Item $task $startedTask -Force

$prompt = & $herdr agent prompt $name "Read the task in $startedTask and do it." 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "agent prompt failed for $name ($prompt); task in $startedTask"
}


# --- Make sure the prompt is sent ---
# herdr can report idle before Copilot accepts input (e.g. "Managed account
# policy is still loading"), leaving the prompt typed but unsent. Press Enter
# until the agent leaves idle; Enter on an empty input does nothing.

for ($try = 0; $try -lt 60; $try++) {
    & $herdr agent wait $name --until working --until blocked --until done --timeout 1000 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        break
    }
    & $herdr agent send-keys $name enter | Out-Null
}

if ($try -ge 60) {
    throw "agent $name never started on its task; prompt left in its input, task in $startedTask"
}

Log "$name prompted with $startedTask (extra Enters: $try)"
