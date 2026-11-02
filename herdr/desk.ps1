# Focus the "Desk" space: Copilot for non-code questions next to nvim on the Obsidian task list.
# Creates it if missing. config.toml focuses the cached id straight from cmd (fast) and only runs
# this script when that fails.
$cache = Join-Path $env:LOCALAPPDATA 'herdr-desk-id'
$desk = (herdr workspace list | ConvertFrom-Json).result.workspaces | Where-Object label -eq 'Desk' | Select-Object -First 1
if ($desk) {
    $id = $desk.workspace_id
    herdr workspace focus $id | Out-Null
} else {
    $dir = Join-Path $HOME 'desk'
    New-Item -ItemType Directory -Force $dir | Out-Null
    $created = (herdr workspace create --cwd $dir --label Desk --focus | ConvertFrom-Json).result
    $id = $created.workspace.workspace_id
    $copilot = $created.root_pane.pane_id
    herdr pane send-text $copilot 'copilot' | Out-Null
    herdr pane send-keys $copilot Enter | Out-Null

    $vault = Join-Path $HOME 'Obsidian-Work'
    $tasks = (herdr pane split $copilot --direction right --cwd $vault | ConvertFrom-Json).result.pane.pane_id
    herdr pane send-text $tasks 'nvim "01 - Next Actions.md"' | Out-Null
    herdr pane send-keys $tasks Enter | Out-Null
}
[IO.File]::WriteAllText($cache, $id)
