
param ([Parameter()]$gitconfig = '.gitconfig', $path = "dotfiles")

$dotfiles = "$env:USERPROFILE\$path"

function Link($target, $source) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    New-Item -ItemType SymbolicLink -Force -Path $target -Target $source | Out-Null
}

Link $PROFILE "$dotfiles\Profile.ps1"
Link "$env:USERPROFILE\.gitconfig" "$dotfiles\$gitconfig"
Link "$env:USERPROFILE\.gitignore_global" "$dotfiles\.gitignore_global"
Link "$env:USERPROFILE\.config\git\worktreeinclude.sh" "$dotfiles\git\worktreeinclude.sh"
Link "$env:USERPROFILE\.config\git\blocked-words.sh" "$dotfiles\git\blocked-words.sh"

## Install Vim and set HOME environment
[System.Environment]::SetEnvironmentVariable('HOME', "C:\Users\" + $env:username, [System.EnvironmentVariableTarget]::User);

Link "$env:USERPROFILE\.vimrc.minimal" "$dotfiles\.vimrc.minimal"
Link "$env:LOCALAPPDATA\nvim" "$dotfiles\.config\nvim"
Link "$env:USERPROFILE\.ideavimrc" "$dotfiles\.ideavimrc"
Link "$env:USERPROFILE\.config\starship.toml" "$dotfiles\.starship\starship.toml"
Link "$env:APPDATA\herdr\config.toml" "$dotfiles\herdr\config.toml"
Link "$env:APPDATA\herdr\agent-detection\copilot.toml" "$dotfiles\herdr\agent-detection\copilot.toml"

## AI instructions and skills for Copilot CLI and Claude Code
& "$dotfiles\ai\setup.ps1" -path $path
