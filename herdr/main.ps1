# Focus the "Main" space, the home base. Tab 1 "shell" is a shell in ~; when Main is created, the
# workspace-layout plugin also puts Copilot and nvim in it (intended). Tab 2 "tasks" has Copilot
# next to nvim on the Obsidian task list. Other tabs (dotfiles etc.) are
# made by hand and left alone. -Tab picks where to land; creates whatever is missing.
# config.toml focuses the cached ids straight from cmd (fast) and only runs this script when that fails.
param([ValidateSet('shell', 'tasks')][string]$Tab = 'tasks')
$cache = Join-Path $env:LOCALAPPDATA 'herdr-main-id'
$vault = if ($env:OBSIDIAN_VAULT) { $env:OBSIDIAN_VAULT } else { Join-Path $HOME 'Obsidian-Work' }
# Copilot on the tasks tab starts in the vault, or on the Desktop when there is none.
$copilotDir = if (Test-Path -LiteralPath $vault -PathType Container) { $vault } else { [Environment]::GetFolderPath('Desktop') }

function Get-Tabs { (herdr tab list --workspace $id | ConvertFrom-Json).result.tabs }
function Get-Tab($label) { Get-Tabs | Where-Object label -eq $label | Select-Object -First 1 }
# The CLI has no workspace move, so call the socket API's workspace.move over herdr's named pipe.
function Move-WorkspaceToTop($workspaceId) {
    $socket = if ($env:HERDR_SOCKET_PATH) { $env:HERDR_SOCKET_PATH } else { Join-Path $env:APPDATA 'herdr\herdr.sock' }
    $pipe = [IO.Pipes.NamedPipeClientStream]::new('.', $socket, [IO.Pipes.PipeDirection]::InOut)
    try {
        $pipe.Connect(2000)
        $writer = [IO.StreamWriter]::new($pipe); $writer.AutoFlush = $true
        $request = @{ id = 'main-top'; method = 'workspace.move'; params = @{ workspace_id = $workspaceId; insert_index = 0 } }
        $writer.WriteLine(($request | ConvertTo-Json -Compress))
        $null = [IO.StreamReader]::new($pipe).ReadLine()
    } finally { $pipe.Dispose() }
}

$main = (herdr workspace list | ConvertFrom-Json).result.workspaces | Where-Object label -eq 'Main' | Select-Object -First 1
if ($main) {
    $id = $main.workspace_id
    herdr workspace focus $id | Out-Null
} else {
    $created = (herdr workspace create --cwd $HOME --label Main --focus | ConvertFrom-Json).result
    $id = $created.workspace.workspace_id
    herdr tab rename $created.tab.tab_id shell | Out-Null
    Move-WorkspaceToTop $id
}

$shellTab = Get-Tab shell
if (-not $shellTab) {
    herdr tab create --workspace $id --cwd $HOME --label shell --no-focus | Out-Null
    $shellTab = Get-Tab shell
}

$tasksTab = Get-Tab tasks
if (-not $tasksTab) {
    $copilot = (herdr tab create --workspace $id --cwd $copilotDir --label tasks --no-focus | ConvertFrom-Json).result.root_pane.pane_id
    herdr pane send-text $copilot 'copilot' | Out-Null
    herdr pane send-keys $copilot Enter | Out-Null
    $nvim = (herdr pane split $copilot --direction right --cwd $vault | ConvertFrom-Json).result.pane.pane_id
    herdr pane send-text $nvim 'nvim "01 - Next Actions.md"' | Out-Null
    herdr pane send-keys $nvim Enter | Out-Null
    $tasksTab = Get-Tab tasks
}

herdr tab focus $(if ($Tab -eq 'shell') { $shellTab.tab_id } else { $tasksTab.tab_id }) | Out-Null
[IO.File]::WriteAllText($cache, "$id $($tasksTab.tab_id) $($shellTab.tab_id)")