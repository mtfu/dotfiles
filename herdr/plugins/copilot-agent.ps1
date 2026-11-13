# Shared by the workspace-layout and worktree-copilot plugins (dot-sourced).

# Plugin hooks have no visible output, so they log here.
function Write-PluginLog([string]$Message) {
    $log = Join-Path $env:LOCALAPPDATA 'herdr-plugins.log'
    Add-Content -Path $log -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$PID] $Message"
}

# Start Copilot CLI in a pane. Returns the agent name; throws if it never starts.
function Start-CopilotAgent([string]$Herdr, [string]$Pane, [string]$Source) {
    # Agent names must match [a-z][a-z0-9_-]{0,31} and be unique among live agents.
    $slug = ($Source.ToLower() -replace '[^a-z0-9_-]+', '-').Trim('-')
    if (-not $slug) { $slug = 'space' }
    $base = ('cp-' + $slug).Substring(0, [Math]::Min(29, 3 + $slug.Length)).TrimEnd('-')
    $name = $base
    # agent list omits names; agent get resolves a live name, so success means it is taken.
    for ($i = 2; $null -ne (& $Herdr agent get $name 2>$null); $i++) { $name = "$base-$i" }

    # The new shell may not be at its prompt yet; agent start refuses a busy pane.
    for ($attempt = 1; $attempt -le 10; $attempt++) {
        $output = & $Herdr agent start $name --kind copilot --pane $Pane 2>&1
        if ($LASTEXITCODE -eq 0) { return $name }
        # A start can launch the agent yet report failure; the retry then finds our own agent in this pane.
        if ("$output" -match 'agent_name_taken' -and "$output" -match "pane_id=$([regex]::Escape($Pane))\s") { return $name }
        Write-PluginLog "agent start attempt $attempt for $Pane failed: $output"
        Start-Sleep -Seconds 2
    }
    throw "agent start failed for $Pane`: $output"
}
