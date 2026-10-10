param ([Parameter()] $path = "dotfiles")

$ai = "$env:USERPROFILE\$path\ai"

## Instructions are always loaded into every session, so they are linked as a single file.
## Rules that must hold 100% of the time live there rather than in a skill, because skills are
## only loaded when the model judges their description relevant.
## Only Copilot gets them: ~/.claude/CLAUDE.md is managed by hand, not linked.
$instructions = "$ai\instructions\copilot-instructions.md"
$copilotInstructions = "$env:USERPROFILE\.copilot\copilot-instructions.md"

if (Test-Path $instructions) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $copilotInstructions) | Out-Null
    New-Item -ItemType SymbolicLink -Force -Path $copilotInstructions -Target $instructions | Out-Null
}
else {
    ## Loud on purpose: the link would still be created and silently dangle, and nothing
    ## about a session tells you the always-loaded rules never loaded.
    Write-Warning "No instructions at $instructions - nothing linked to $copilotInstructions"
}

## Skills are linked per skill, so ok-ai-synced skills already in ~/.copilot/skills are preserved.
## Authored skills live under dotfiles\ai\sources\<source>\skills\<skill>.
$skills = Get-ChildItem -Path "$ai\sources\*\skills\*" -Directory -ErrorAction SilentlyContinue

foreach ($skillsDir in @("$env:USERPROFILE\.copilot\skills", "$env:USERPROFILE\.claude\skills")) {
    New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null
    foreach ($skill in $skills) {
        New-Item -ItemType SymbolicLink -Force -Path (Join-Path $skillsDir $skill.Name) -Target $skill.FullName | Out-Null
    }
}
