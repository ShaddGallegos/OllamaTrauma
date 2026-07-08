#!/usr/bin/env pwsh
# Windows PowerShell wrapper for OllamaTrauma_v2.
# If running under WSL, delegates to the Linux script via wsl.exe.
# Otherwise, attempts to run the included Windows PowerShell implementation if present.
param([Parameter(ValueFromRemainingArguments=$true)] $Args)

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$MainUnix = Join-Path $RepoRoot 'OllamaTrauma_v2.sh'
$WinImpl = Join-Path $RepoRoot 'windows\OllamaTrauma_v2.ps1'

if (Test-Path $Env:WINDIR -PathType Container -ErrorAction SilentlyContinue) {
  # Native Windows
  if (Get-Command wsl -ErrorAction SilentlyContinue) {
    Write-Host "Detected WSL support; running main bash script via wsl"
    wsl bash -lc "'$MainUnix' $($Args -join ' ')"
    exit $LASTEXITCODE
  }
  elseif (Test-Path $WinImpl) {
    Write-Host "Running repository Windows implementation: $WinImpl"
    & $WinImpl @Args
    exit $LASTEXITCODE
  }
  else {
    Write-Host "No native Windows implementation found. Install WSL or use Git Bash."
    exit 2
  }
} else {
  # Non-Windows host (PowerShell Core on Linux/Mac)
  if (Test-Path $MainUnix) {
    bash $MainUnix @Args
    exit $LASTEXITCODE
  }
  else {
    Write-Host "Main script not found: $MainUnix"
    exit 2
  }
}
