# Install the llm-council skill into Claude Code (Windows / PowerShell).
# Usage (from a clone):
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
# Or one-liner (no clone needed):
#   irm https://raw.githubusercontent.com/joppe2001/llm-council-skill/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$SkillName = "llm-council"
$Dest      = Join-Path $HOME ".claude\skills\$SkillName"
$RawBase   = "https://raw.githubusercontent.com/joppe2001/llm-council-skill/main/skills/$SkillName"

Write-Host "Installing the '$SkillName' skill into Claude Code..."
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

# If run from inside a cloned repo, copy locally; otherwise download.
$LocalSrc = $null
if ($PSScriptRoot) {
    $LocalSrc = Join-Path $PSScriptRoot "skills\$SkillName\SKILL.md"
}

if ($LocalSrc -and (Test-Path $LocalSrc)) {
    Copy-Item $LocalSrc (Join-Path $Dest "SKILL.md") -Force
    Write-Host "Copied from local clone."
} else {
    Invoke-WebRequest -Uri "$RawBase/SKILL.md" -OutFile (Join-Path $Dest "SKILL.md")
    Write-Host "Downloaded SKILL.md."
}

Write-Host ""
Write-Host "Installed to: $Dest\SKILL.md"
Write-Host "Start a new Claude Code session, then type /$SkillName or say 'convene the council on: <question>'."
