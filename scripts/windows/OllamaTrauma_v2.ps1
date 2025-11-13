<#
.SYNOPSIS
    OllamaTrauma v2 - Windows PowerShell Version
    
.DESCRIPTION
    Unified Bootstrap + AI Runner Manager for Windows
    Supports: Ollama, LocalAI, llama.cpp, text-generation-webui
    Container Runtime: Docker (Podman support via WSL)
    
.NOTES
    Version: 2.1.0
    Author: OllamaTrauma Project
    Requires: PowerShell 5.1 or higher
#>

#Requires -Version 5.1

# Stop on errors
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ============================================================================
# CONFIGURATION
# ============================================================================

$Global:ScriptVersion = "2.1.0"
$Global:ProjectName = "OllamaTrauma"
$Global:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Global:ProjectRoot = $Global:ScriptDir

# Paths
$Global:LlamaCppDir = Join-Path $Global:ProjectRoot "llama.cpp"
$Global:LocalAIContainer = "localai"
$Global:TextGenDir = Join-Path $Global:ProjectRoot "text-generation-webui"
$Global:BackupDir = Join-Path $Global:ProjectRoot ".backups"
$Global:LogDir = Join-Path $Global:ProjectRoot "data\logs"
$Global:Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Global:LogFile = Join-Path $Global:LogDir "ollamatrauma_$Global:Timestamp.log"
$Global:ErrorLogFile = Join-Path $Global:LogDir "ollamatrauma_errors_$Global:Timestamp.log"

# Colors (using Write-Host colors)
$Global:ColorInfo = "Green"
$Global:ColorWarn = "Yellow"
$Global:ColorError = "Red"
$Global:ColorStep = "Cyan"
$Global:ColorSuccess = "Green"
$Global:ColorDebug = "DarkCyan"

# Container runtime
$Global:ContainerCmd = ""

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Ensure log directory exists
    if (-not (Test-Path $Global:LogDir)) {
        New-Item -ItemType Directory -Path $Global:LogDir -Force | Out-Null
    }
    
    # Write to console
    Write-Host "[$Level] " -ForegroundColor $Color -NoNewline
    Write-Host $Message
    
    # Write to log file
    Add-Content -Path $Global:LogFile -Value $logMessage
    
    # Write errors to error log too
    if ($Level -eq "ERROR" -or $Level -eq "WARN") {
        Add-Content -Path $Global:ErrorLogFile -Value $logMessage
    }
}

function Log-Info { param([string]$Message) Write-Log -Message $Message -Level "INFO" -Color $Global:ColorInfo }
function Log-Warn { param([string]$Message) Write-Log -Message $Message -Level "WARN" -Color $Global:ColorWarn }
function Log-Error { param([string]$Message) Write-Log -Message $Message -Level "ERROR" -Color $Global:ColorError }
function Log-Step { param([string]$Message) Write-Log -Message $Message -Level "STEP" -Color $Global:ColorStep }
function Log-Success { param([string]$Message) Write-Log -Message $Message -Level "OK" -Color $Global:ColorSuccess }

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

function Show-Banner {
    Clear-Host
    Write-Host @"

                                                                  
                    OllamaTrauma v2.1.0                          
              AI Runner Manager - Windows Edition                 
                                                                  

"@ -ForegroundColor Cyan
    Write-Host ""
}

function Pause-Script {
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Clear-Screen {
    Clear-Host
}

# ============================================================================
# SYSTEM DETECTION
# ============================================================================

function Get-WindowsVersion {
    $os = Get-CimInstance Win32_OperatingSystem
    return @{
        Version = $os.Version
        Caption = $os.Caption
        Architecture = $os.OSArchitecture
    }
}

function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-CommandExists {
    param([string]$Command)
    
    $exists = $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
    if ($exists) {
        Log-Success "$Command installed"
    } else {
        Log-Warn "$Command NOT installed"
    }
    return $exists
}

# ============================================================================
# CONTAINER RUNTIME DETECTION
# ============================================================================

function Find-ContainerRuntime {
    Log-Info "Detecting container runtime..."
    
    # Check for Docker first (most common on Windows)
    if (Test-CommandExists "docker") {
        $Global:ContainerCmd = "docker"
        Log-Info "Using Docker as container runtime"
        
        # Test Docker
        try {
            $dockerVersion = docker --version 2>$null
            Log-Info "Docker version: $dockerVersion"
        } catch {
            Log-Warn "Docker installed but may not be running"
        }
    }
    # Check for Podman (via WSL or native)
    elseif (Test-CommandExists "podman") {
        $Global:ContainerCmd = "podman"
        Log-Info "Using Podman as container runtime"
    }
    else {
        $Global:ContainerCmd = ""
        Log-Warn "No container runtime detected"
        Log-Info "Install Docker Desktop: https://www.docker.com/products/docker-desktop"
    }
}

# ============================================================================
# DEPENDENCY CHECKING
# ============================================================================

function Test-AllDependencies {
    $missing = 0
    
    # Critical dependencies for Windows
    $criticalDeps = @("powershell", "git", "curl")
    
    Log-Info "Checking critical dependencies..."
    
    foreach ($dep in $criticalDeps) {
        if (-not (Test-CommandExists $dep)) {
            $missing++
        }
    }
    
    # Check Python
    if (Test-CommandExists "python") {
        $pythonVersion = python --version 2>&1
        Write-Host "  $pythonVersion" -ForegroundColor Gray
    } else {
        $missing++
    }
    
    # Check container runtime
    Find-ContainerRuntime
    
    if ($missing -gt 0) {
        Log-Error "Cannot continue: $missing critical dependencies missing"
        Log-Info "Please install missing packages:"
        Log-Info "  - Git: https://git-scm.com/download/win"
        Log-Info "  - Python: https://www.python.org/downloads/"
        Log-Info "  - Docker: https://www.docker.com/products/docker-desktop"
        return $false
    }
    
    return $true
}

function Test-Dependencies {
    Show-Banner
    Log-Step "Checking dependencies..."
    Write-Host ""
    
    $missing = 0
    $deps = @("curl", "git", "python")
    
    if ($Global:ContainerCmd) {
        $deps += $Global:ContainerCmd
    } else {
        $deps += @("docker", "podman")
    }
    
    foreach ($dep in $deps) {
        if (Test-CommandExists $dep) {
            switch ($dep) {
                "python" {
                    $version = python --version 2>&1
                    Write-Host "  $version" -ForegroundColor Gray
                }
                "git" {
                    $version = git --version 2>&1
                    Write-Host "  $version" -ForegroundColor Gray
                }
                "docker" {
                    $version = docker --version 2>&1
                    Write-Host "  $version" -ForegroundColor Gray
                }
            }
        } else {
            $missing++
        }
    }
    
    Write-Host ""
    if ($missing -eq 0) {
        Log-Success "All critical dependencies installed"
    } else {
        Log-Warn "$missing dependencies missing"
        Write-Host ""
        $response = Read-Host "View installation instructions? [y/N]"
        if ($response -match "^[Yy]$") {
            Show-InstallInstructions
        }
    }
    
    Pause-Script
}

function Show-InstallInstructions {
    Write-Host ""
    Write-Host "Installation Instructions:" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Git for Windows:" -ForegroundColor Yellow
    Write-Host "  https://git-scm.com/download/win" -ForegroundColor White
    Write-Host ""
    Write-Host "Python:" -ForegroundColor Yellow
    Write-Host "  https://www.python.org/downloads/" -ForegroundColor White
    Write-Host ""
    Write-Host "Docker Desktop:" -ForegroundColor Yellow
    Write-Host "  https://www.docker.com/products/docker-desktop" -ForegroundColor White
    Write-Host ""
    Write-Host "Or use package managers:" -ForegroundColor Yellow
    Write-Host "  winget install Git.Git" -ForegroundColor White
    Write-Host "  winget install Python.Python.3" -ForegroundColor White
    Write-Host "  winget install Docker.DockerDesktop" -ForegroundColor White
    Write-Host ""
}

# ============================================================================
# PROJECT INITIALIZATION
# ============================================================================

function Initialize-ProjectStructure {
    Log-Step "Creating project directory structure..."
    
    $directories = @(
        "config",
        "data\models",
        "data\hf_cache",
        "data\logs",
        "data\outputs",
        "data\training",
        "scripts",
        "tests\fixtures",
        "OllamaTrauma-TrainingData",
        ".backups"
    )
    
    foreach ($dir in $directories) {
        $fullPath = Join-Path $Global:ProjectRoot $dir
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Log-Success "Created: $dir"
        }
    }
}

function New-GitIgnore {
    $gitignorePath = Join-Path $Global:ProjectRoot ".gitignore"
    
    if (Test-Path $gitignorePath) {
        Log-Info ".gitignore already exists"
        return
    }
    
    $gitignoreContent = @"
# Environment files
env.yml
.vault_pass.txt
*.secret

# Data directories
data/models/*
data/hf_cache/*
data/logs/*
models/*.gguf
models/*.bin

# Training data (can be huge)
OllamaTrauma-TrainingData/

# Python
__pycache__/
*.py[cod]
*`$py.class
*.so
.Python
venv/
ENV/
env/

# OS files
.DS_Store
Thumbs.db
*.swp
*.swo
*~
desktop.ini

# Windows
*.lnk

# IDE
.vscode/
.idea/
*.code-workspace

# Keep directory structure
!data/models/.gitkeep
!data/hf_cache/.gitkeep
!data/logs/.gitkeep
!models/.gitkeep
"@
    
    Set-Content -Path $gitignorePath -Value $gitignoreContent
    Log-Success "Created .gitignore"
}

function New-RequirementsTxt {
    $reqPath = Join-Path $Global:ProjectRoot "requirements.txt"
    
    if (Test-Path $reqPath) {
        Log-Info "requirements.txt already exists"
        return
    }
    
    $requirements = @"
# Core dependencies
requests>=2.31.0
beautifulsoup4>=4.12.0
lxml>=4.9.0

# AI/ML libraries
huggingface-hub>=0.19.0
transformers>=4.35.0

# Utilities
pyyaml>=6.0
tqdm>=4.66.0
"@
    
    Set-Content -Path $reqPath -Value $requirements
    Log-Success "Created requirements.txt"
}

function Initialize-Project {
    Show-Banner
    Log-Step "Initializing OllamaTrauma project..."
    
    Initialize-ProjectStructure
    New-RequirementsTxt
    New-GitIgnore
    
    # Check for container runtime
    if (-not $Global:ContainerCmd) {
        Find-ContainerRuntime
    }
    
    if ($Global:ContainerCmd -eq "docker") {
        Write-Host ""
        Log-Info "Docker detected. Checking Docker service..."
        try {
            docker ps 2>&1 | Out-Null
            Log-Success "Docker is running"
        } catch {
            Log-Warn "Docker installed but not running"
            Log-Info "Start Docker Desktop and try again"
        }
    }
    
    Log-Success "Project initialization complete!"
    Pause-Script
}

# ============================================================================
# OLLAMA FUNCTIONS
# ============================================================================

function Install-Ollama {
    Show-Banner
    Log-Step "Installing Ollama for Windows..."
    Write-Host ""
    
    if (Test-CommandExists "ollama") {
        Log-Info "Ollama is already installed"
        $version = ollama --version 2>&1
        Write-Host "  $version" -ForegroundColor Gray
        Pause-Script
        return
    }
    
    Log-Info "Downloading Ollama installer..."
    $installerUrl = "https://ollama.ai/download/OllamaSetup.exe"
    $installerPath = Join-Path $env:TEMP "OllamaSetup.exe"
    
    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
        Log-Success "Downloaded Ollama installer"
        
        Log-Info "Running installer..."
        Start-Process -FilePath $installerPath -Wait
        
        Log-Success "Ollama installation complete"
        Log-Info "You may need to restart your terminal"
    } catch {
        Log-Error "Failed to install Ollama: $_"
    }
    
    Pause-Script
}

function Start-Ollama {
    if (-not (Test-CommandExists "ollama")) {
        Log-Error "Ollama is not installed"
        Pause-Script
        return
    }
    
    Log-Info "Starting Ollama service..."
    
    try {
        Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 2
        
        # Test if Ollama is responding
        $response = Invoke-WebRequest -Uri "http://localhost:11434" -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Log-Success "Ollama is running on http://localhost:11434"
        }
    } catch {
        Log-Warn "Could not verify Ollama status"
    }
    
    Pause-Script
}

# ============================================================================
# MENU FUNCTIONS
# ============================================================================

function Show-SetupMenu {
    while ($true) {
        Show-Banner
        Write-Host "Setup & Configuration" -ForegroundColor Cyan
        Write-Host "" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  1) Initialize Project (first-time setup)"
        Write-Host "  2) Check Dependencies"
        Write-Host "  3) Install Missing Dependencies"
        Write-Host "  0) Back to Main Menu"
        Write-Host ""
        
        $choice = Read-Host "Select option [0-3]"
        
        switch ($choice) {
            "1" { Initialize-Project }
            "2" { Test-Dependencies }
            "3" { Show-InstallInstructions; Pause-Script }
            "0" { return }
            default { Log-Error "Invalid option"; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-AIRunnersMenu {
    while ($true) {
        Show-Banner
        Write-Host "AI Runners Management" -ForegroundColor Cyan
        Write-Host "" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Installation:"
        Write-Host "    1) Install Ollama"
        Write-Host ""
        Write-Host "  Operation:"
        Write-Host "    2) Start Ollama Service"
        Write-Host "    3) Stop Ollama Service"
        Write-Host ""
        Write-Host "  0) Back to Main Menu"
        Write-Host ""
        
        $choice = Read-Host "Select option [0-3]"
        
        switch ($choice) {
            "1" { Install-Ollama }
            "2" { Start-Ollama }
            "3" { Log-Info "Stop Ollama manually via Task Manager"; Pause-Script }
            "0" { return }
            default { Log-Error "Invalid option"; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-MainMenu {
    while ($true) {
        Show-Banner
        Write-Host "Main Menu" -ForegroundColor Cyan
        Write-Host "" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  1) Setup & Configuration"
        Write-Host "  2) AI Runners Management"
        Write-Host "  3) Model Management"
        Write-Host "  4) Health Check"
        Write-Host "  0) Exit"
        Write-Host ""
        
        $choice = Read-Host "Select option [0-4]"
        
        switch ($choice) {
            "1" { Show-SetupMenu }
            "2" { Show-AIRunnersMenu }
            "3" { Log-Info "Model management coming soon..."; Pause-Script }
            "4" { Test-Dependencies }
            "0" {
                Clear-Screen
                Log-Success "Thank you for using OllamaTrauma v2!"
                return
            }
            default { Log-Error "Invalid option"; Start-Sleep -Seconds 1 }
        }
    }
}

# ============================================================================
# MAIN SCRIPT EXECUTION
# ============================================================================

# Parse command line arguments
param(
    [switch]$Help,
    [switch]$Debug
)

if ($Help) {
    Write-Host "" -ForegroundColor Cyan
    Write-Host "  OllamaTrauma v2.1.0 - AI Runner Manager (Windows)" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\OllamaTrauma_v2.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Help        Show this help message"
    Write-Host "  -Debug       Enable debug mode"
    Write-Host ""
    Write-Host "Run without options for interactive menu."
    Write-Host ""
    exit 0
}

# Ensure log directory exists
if (-not (Test-Path $Global:LogDir)) {
    New-Item -ItemType Directory -Path $Global:LogDir -Force | Out-Null
}

Log-Info "Starting OllamaTrauma v2.1.0 (Windows)"

# Get Windows version
$winVersion = Get-WindowsVersion
Log-Info "Windows: $($winVersion.Caption) ($($winVersion.Architecture))"

# Check if running as admin
if (Test-IsAdmin) {
    Log-Warn "Running as Administrator"
} else {
    Log-Info "Running as standard user (recommended)"
}

# Check critical dependencies
if (-not (Test-AllDependencies)) {
    Log-Error "Critical dependencies missing. Please install required software."
    Show-InstallInstructions
    Pause-Script
    exit 1
}

# Detect container runtime
Find-ContainerRuntime

# Show main menu
Show-MainMenu
