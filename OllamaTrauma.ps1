# OllamaTrauma PowerShell Cross-Platform Script
# Compatible with Windows, macOS (PowerShell Core), and Linux (PowerShell Core)
# Version: 2.0

param(
    [string]$ConfigDir = $PSScriptRoot,
    [string]$Model = "mistral",
    [switch]$InstallOnly,
    [switch]$Quiet,
    [switch]$Version
)

# Version information
if ($Version) {
    Write-Host "OllamaTrauma PowerShell v2.0" -ForegroundColor Green
    exit 0
}

# Global variables
$Global:SelectedModel = $Model
$Global:ConfigFile = Join-Path $ConfigDir "ollama_config.json"
$Global:LogFile = Join-Path $ConfigDir "ollama_trauma.log"
$Global:IsAnsible = $false

# Color definitions
$Colors = @{
    Red = [ConsoleColor]::Red
    Green = [ConsoleColor]::Green
    Yellow = [ConsoleColor]::Yellow
    Blue = [ConsoleColor]::Blue
    Magenta = [ConsoleColor]::Magenta
    Cyan = [ConsoleColor]::Cyan
    White = [ConsoleColor]::White
}

# Check if running under Ansible
if ($env:ANSIBLE_STDOUT_CALLBACK -or $env:ANSIBLE_REMOTE_USER -or $env:ANSIBLE_PLAYBOOK) {
    $Global:IsAnsible = $true
}

function Write-Log {
    param(
        [string]$Level,
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file
    Add-Content -Path $Global:LogFile -Value $logEntry -ErrorAction SilentlyContinue
    
    # Write to console with color
    if (-not $Quiet) {
        Write-Host "[$Level] $Message" -ForegroundColor $Color
    }
}

function Get-OSInfo {
    $osInfo = @{
        Platform = $PSVersionTable.Platform
        OS = $PSVersionTable.OS
        Edition = $PSVersionTable.PSEdition
        Version = $PSVersionTable.PSVersion.ToString()
        PackageManager = "unknown"
    }
    
    # Determine package manager based on OS
    if ($IsWindows -or $PSVersionTable.PSEdition -eq "Desktop") {
        $osInfo.PackageManager = "winget"
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            $osInfo.PackageManager = "choco"
        } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
            $osInfo.PackageManager = "scoop"
        }
    } elseif ($IsMacOS) {
        $osInfo.PackageManager = "brew"
    } elseif ($IsLinux) {
        if (Get-Command dnf -ErrorAction SilentlyContinue) {
            $osInfo.PackageManager = "dnf"
        } elseif (Get-Command apt -ErrorAction SilentlyContinue) {
            $osInfo.PackageManager = "apt"
        } elseif (Get-Command yum -ErrorAction SilentlyContinue) {
            $osInfo.PackageManager = "yum"
        } elseif (Get-Command pacman -ErrorAction SilentlyContinue) {
            $osInfo.PackageManager = "pacman"
        }
    }
    
    return $osInfo
}

function Install-Package {
    param(
        [string]$PackageName,
        [hashtable]$PackageMap = @{}
    )
    
    $osInfo = Get-OSInfo
    $actualPackage = if ($PackageMap.ContainsKey($osInfo.PackageManager)) {
        $PackageMap[$osInfo.PackageManager]
    } else {
        $PackageName
    }
    
    Write-Log "INFO" "Installing package: $actualPackage" $Colors.Yellow
    
    try {
        switch ($osInfo.PackageManager) {
            "winget" {
                $result = Start-Process -FilePath "winget" -ArgumentList "install", $actualPackage -Wait -PassThru -NoNewWindow
                return $result.ExitCode -eq 0
            }
            "choco" {
                $result = Start-Process -FilePath "choco" -ArgumentList "install", "-y", $actualPackage -Wait -PassThru -NoNewWindow -Verb RunAs
                return $result.ExitCode -eq 0
            }
            "scoop" {
                $result = Start-Process -FilePath "scoop" -ArgumentList "install", $actualPackage -Wait -PassThru -NoNewWindow
                return $result.ExitCode -eq 0
            }
            "brew" {
                $result = Start-Process -FilePath "brew" -ArgumentList "install", $actualPackage -Wait -PassThru -NoNewWindow
                return $result.ExitCode -eq 0
            }
            "apt" {
                $result = Start-Process -FilePath "sudo" -ArgumentList "apt", "update" -Wait -PassThru -NoNewWindow
                if ($result.ExitCode -eq 0) {
                    $result = Start-Process -FilePath "sudo" -ArgumentList "apt", "install", "-y", $actualPackage -Wait -PassThru -NoNewWindow
                }
                return $result.ExitCode -eq 0
            }
            "dnf" {
                $result = Start-Process -FilePath "sudo" -ArgumentList "dnf", "install", "-y", $actualPackage -Wait -PassThru -NoNewWindow
                return $result.ExitCode -eq 0
            }
            default {
                Write-Log "ERROR" "Unknown package manager: $($osInfo.PackageManager)" $Colors.Red
                return $false
            }
        }
    } catch {
        Write-Log "ERROR" "Failed to install $actualPackage : $($_.Exception.Message)" $Colors.Red
        return $false
    }
}

function Test-Command {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Test-Dependencies {
    Write-Log "INFO" "Checking dependencies..." $Colors.Cyan
    
    $dependencies = @{
        "curl" = @{
            "winget" = "curl"
            "choco" = "curl"
            "scoop" = "curl"
        }
        "git" = @{
            "winget" = "Git.Git"
            "choco" = "git"
            "scoop" = "git"
        }
    }
    
    $allInstalled = $true
    
    foreach ($dep in $dependencies.Keys) {
        if (-not (Test-Command $dep)) {
            Write-Log "WARN" "$dep not found. Installing..." $Colors.Yellow
            if (-not (Install-Package $dep $dependencies[$dep])) {
                $allInstalled = $false
            }
        } else {
            Write-Log "INFO" "$dep is already installed" $Colors.Green
        }
    }
    
    # Check PowerShell modules
    $modules = @("PowerShellGet", "PackageManagement")
    foreach ($module in $modules) {
        if (-not (Get-Module -Name $module -ListAvailable)) {
            Write-Log "WARN" "Installing PowerShell module: $module" $Colors.Yellow
            try {
                Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
                Write-Log "INFO" "Successfully installed $module" $Colors.Green
            } catch {
                Write-Log "ERROR" "Failed to install $module : $($_.Exception.Message)" $Colors.Red
            }
        }
    }
    
    return $allInstalled
}

function Test-OllamaRunning {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -TimeoutSec 5 -ErrorAction Stop
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Start-OllamaService {
    if (Test-OllamaRunning) {
        Write-Log "INFO" "Ollama service is already running" $Colors.Green
        return $true
    }
    
    Write-Log "INFO" "Starting Ollama service..." $Colors.Yellow
    
    try {
        $osInfo = Get-OSInfo
        
        if ($IsWindows -or $PSVersionTable.PSEdition -eq "Desktop") {
            # Windows: Start as background job
            $job = Start-Job -ScriptBlock { ollama serve }
            Start-Sleep 2
        } elseif ($IsMacOS -and (Test-Command "brew")) {
            Start-Process -FilePath "brew" -ArgumentList "services", "start", "ollama" -NoNewWindow
        } else {
            # Linux/Unix: Start as background process
            Start-Process -FilePath "ollama" -ArgumentList "serve" -NoNewWindow
        }
        
        # Wait for service to be ready
        $maxAttempts = 30
        for ($i = 0; $i -lt $maxAttempts; $i++) {
            if (Test-OllamaRunning) {
                Write-Log "INFO" "Ollama service started successfully" $Colors.Green
                return $true
            }
            Start-Sleep 1
        }
        
        Write-Log "ERROR" "Ollama service failed to start within 30 seconds" $Colors.Red
        return $false
        
    } catch {
        Write-Log "ERROR" "Failed to start Ollama service: $($_.Exception.Message)" $Colors.Red
        return $false
    }
}

function Install-Ollama {
    if (Test-Command "ollama") {
        Write-Log "INFO" "Ollama is already installed" $Colors.Green
        return $true
    }
    
    Write-Log "INFO" "Installing Ollama..." $Colors.Yellow
    
    try {
        $osInfo = Get-OSInfo
        
        if ($IsWindows -or $PSVersionTable.PSEdition -eq "Desktop") {
            Write-Host "For Windows, please download and install Ollama from: https://ollama.ai/download" -ForegroundColor Yellow
            Write-Host "Press Enter after installation is complete..." -ForegroundColor Cyan
            if (-not $Global:IsAnsible) {
                Read-Host
            }
            
            if (-not (Test-Command "ollama")) {
                Write-Log "ERROR" "Ollama installation failed or not in PATH" $Colors.Red
                return $false
            }
        } else {
            # macOS and Linux
            $installScript = Invoke-WebRequest -Uri "https://ollama.ai/install.sh" -UseBasicParsing
            $installScript.Content | bash
        }
        
        Write-Log "INFO" "Ollama installed successfully" $Colors.Green
        return $true
        
    } catch {
        Write-Log "ERROR" "Failed to install Ollama: $($_.Exception.Message)" $Colors.Red
        return $false
    }
}

function Get-OllamaModels {
    try {
        $output = & ollama list 2>$null
        if ($LASTEXITCODE -eq 0) {
            $models = @()
            $lines = $output -split "`n" | Select-Object -Skip 1
            foreach ($line in $lines) {
                if ($line.Trim()) {
                    $modelName = ($line -split "\s+")[0]
                    $models += $modelName
                }
            }
            return $models
        }
    } catch {
        Write-Log "ERROR" "Failed to get models: $($_.Exception.Message)" $Colors.Red
    }
    return @()
}

function Invoke-OllamaPull {
    param([string]$ModelName)
    
    Write-Log "INFO" "Pulling model: $ModelName" $Colors.Yellow
    
    try {
        $process = Start-Process -FilePath "ollama" -ArgumentList "pull", $ModelName -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Log "INFO" "Successfully pulled $ModelName" $Colors.Green
            return $true
        } else {
            Write-Log "ERROR" "Failed to pull $ModelName" $Colors.Red
            return $false
        }
    } catch {
        Write-Log "ERROR" "Failed to pull $ModelName : $($_.Exception.Message)" $Colors.Red
        return $false
    }
}

function Remove-OllamaModel {
    param([string]$ModelName)
    
    Write-Log "INFO" "Removing model: $ModelName" $Colors.Yellow
    
    try {
        $process = Start-Process -FilePath "ollama" -ArgumentList "rm", $ModelName -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Log "INFO" "Successfully removed $ModelName" $Colors.Green
            return $true
        } else {
            Write-Log "ERROR" "Failed to remove $ModelName" $Colors.Red
            return $false
        }
    } catch {
        Write-Log "ERROR" "Failed to remove $ModelName : $($_.Exception.Message)" $Colors.Red
        return $false
    }
}

function Start-OllamaInteractive {
    param([string]$ModelName)
    
    if ($Global:IsAnsible) {
        Write-Log "INFO" "Ansible mode: Model $ModelName is ready" $Colors.Green
        return
    }
    
    Write-Log "INFO" "Starting interactive session with $ModelName" $Colors.Green
    Write-Host "Starting $ModelName... (Ctrl+C to exit)" -ForegroundColor Green
    
    try {
        & ollama run $ModelName
    } catch {
        Write-Log "ERROR" "Failed to run $ModelName : $($_.Exception.Message)" $Colors.Red
    }
}

function Save-Config {
    $config = @{
        selected_model = $Global:SelectedModel
        os_info = Get-OSInfo
        last_updated = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    
    try {
        $config | ConvertTo-Json -Depth 3 | Set-Content -Path $Global:ConfigFile
        Write-Log "DEBUG" "Configuration saved to $Global:ConfigFile" $Colors.Cyan
    } catch {
        Write-Log "ERROR" "Failed to save config: $($_.Exception.Message)" $Colors.Red
    }
}

function Load-Config {
    if (Test-Path $Global:ConfigFile) {
        try {
            $config = Get-Content -Path $Global:ConfigFile | ConvertFrom-Json
            $Global:SelectedModel = $config.selected_model
            Write-Log "DEBUG" "Configuration loaded from $Global:ConfigFile" $Colors.Cyan
        } catch {
            Write-Log "WARN" "Failed to load config: $($_.Exception.Message)" $Colors.Yellow
        }
    }
}

function Clear-Screen {
    if (-not $Global:IsAnsible) {
        Clear-Host
    }
}

function Wait-ForUser {
    param([string]$Message = "Press Enter to continue...")
    if (-not $Global:IsAnsible) {
        Write-Host $Message -ForegroundColor Cyan
        Read-Host
    }
}

function Install-AndRunModel {
    Clear-Screen
    
    # Install Ollama if needed
    if (-not (Install-Ollama)) {
        return
    }
    
    # Start Ollama service
    if (-not (Start-OllamaService)) {
        return
    }
    
    # Check if model exists
    $availableModels = Get-OllamaModels
    $modelExists = $availableModels -contains $Global:SelectedModel
    
    if (-not $modelExists) {
        if (-not (Invoke-OllamaPull $Global:SelectedModel)) {
            return
        }
    }
    
    # Run model
    Start-OllamaInteractive $Global:SelectedModel
}

function Select-ModelInteractive {
    while ($true) {
        Clear-Screen
        Write-Host "=== Model Selection ===" -ForegroundColor Blue
        Write-Host "Current model: $Global:SelectedModel" -ForegroundColor Green
        Write-Host ""
        Write-Host "Popular models:"
        Write-Host "1) mistral (7B) - Fast and efficient"
        Write-Host "2) llama2 (7B) - Meta's base model"
        Write-Host "3) llama2:13b (13B) - Larger variant"
        Write-Host "4) codellama (7B) - Code-focused model"
        Write-Host "5) phi (2.7B) - Microsoft's small model"
        Write-Host "6) Custom model name"
        Write-Host "7) Return to main menu"
        Write-Host ""
        
        if ($Global:IsAnsible) {
            $choice = $env:ANSIBLE_MODEL_CHOICE
            if (-not $choice) { $choice = "1" }
            Write-Log "INFO" "Ansible mode: Using model choice $choice" $Colors.Cyan
        } else {
            $choice = Read-Host "Enter your choice (1-7)"
        }
        
        switch ($choice) {
            "1" { $Global:SelectedModel = "mistral" }
            "2" { $Global:SelectedModel = "llama2" }
            "3" { $Global:SelectedModel = "llama2:13b" }
            "4" { $Global:SelectedModel = "codellama" }
            "5" { $Global:SelectedModel = "phi" }
            "6" {
                if ($Global:IsAnsible) {
                    $customModel = $env:ANSIBLE_CUSTOM_MODEL
                    if (-not $customModel) { $customModel = "mistral" }
                } else {
                    $customModel = Read-Host "Enter custom model name"
                }
                if ($customModel) {
                    $Global:SelectedModel = $customModel
                }
            }
            "7" { return }
            default {
                Write-Log "WARN" "Invalid choice, keeping current model: $Global:SelectedModel" $Colors.Yellow
                if (-not $Global:IsAnsible) { Start-Sleep 1 }
            }
        }
        
        Write-Log "INFO" "Selected model: $Global:SelectedModel" $Colors.Green
        Save-Config
        break
    }
}

function Show-AdvancedOperations {
    while ($true) {
        Clear-Screen
        Write-Host "=== Advanced Operations ===" -ForegroundColor Magenta
        Write-Host "1) List all models"
        Write-Host "2) Remove models"
        Write-Host "3) Model information"
        Write-Host "4) System information"
        Write-Host "5) Return to main menu"
        Write-Host ""
        
        if ($Global:IsAnsible) {
            $choice = $env:ANSIBLE_ADVANCED_CHOICE
            if (-not $choice) { $choice = "5" }
            Write-Log "INFO" "Ansible mode: Using advanced choice $choice" $Colors.Cyan
        } else {
            $choice = Read-Host "Enter your choice (1-5)"
        }
        
        switch ($choice) {
            "1" {
                $models = Get-OllamaModels
                if ($models.Count -gt 0) {
                    Write-Host "Available models:" -ForegroundColor Green
                    foreach ($model in $models) {
                        Write-Host "  - $model"
                    }
                } else {
                    Write-Host "No models installed." -ForegroundColor Yellow
                }
                Wait-ForUser
            }
            "2" {
                $models = Get-OllamaModels
                if ($models.Count -eq 0) {
                    Write-Host "No models to remove." -ForegroundColor Yellow
                    Wait-ForUser
                    continue
                }
                
                Write-Host "Available models:" -ForegroundColor Green
                for ($i = 0; $i -lt $models.Count; $i++) {
                    Write-Host "$($i + 1)) $($models[$i])"
                }
                
                if (-not $Global:IsAnsible) {
                    try {
                        $index = [int](Read-Host "Select model to remove (number)") - 1
                        if ($index -ge 0 -and $index -lt $models.Count) {
                            $modelToRemove = $models[$index]
                            $confirm = Read-Host "Remove $modelToRemove? (y/N)"
                            if ($confirm -eq "y") {
                                Remove-OllamaModel $modelToRemove
                                if ($modelToRemove -eq $Global:SelectedModel) {
                                    $Global:SelectedModel = "mistral"
                                    Save-Config
                                }
                            }
                        } else {
                            Write-Host "Invalid selection." -ForegroundColor Red
                        }
                    } catch {
                        Write-Host "Invalid input." -ForegroundColor Red
                    }
                }
                Wait-ForUser
            }
            "3" {
                if (Test-Command "ollama") {
                    Write-Host "Ollama version:" -ForegroundColor Green
                    & ollama --version
                    
                    Write-Host "Current model info:" -ForegroundColor Green
                    & ollama show $Global:SelectedModel 2>$null
                    if ($LASTEXITCODE -ne 0) {
                        Write-Host "Model $Global:SelectedModel not found." -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "Ollama not installed." -ForegroundColor Red
                }
                Wait-ForUser
            }
            "4" {
                $osInfo = Get-OSInfo
                Write-Host "System Information:" -ForegroundColor Green
                Write-Host "Platform: $($osInfo.Platform)"
                Write-Host "OS: $($osInfo.OS)"
                Write-Host "PowerShell Edition: $($osInfo.Edition)"
                Write-Host "PowerShell Version: $($osInfo.Version)"
                Write-Host "Package Manager: $($osInfo.PackageManager)"
                Write-Host "Script Directory: $PSScriptRoot"
                Write-Host "Config File: $Global:ConfigFile"
                Write-Host "Current Model: $Global:SelectedModel"
                Write-Host "Ansible Mode: $Global:IsAnsible"
                Wait-ForUser
            }
            "5" { return }
            default {
                Write-Log "WARN" "Invalid option" $Colors.Yellow
                if (-not $Global:IsAnsible) { Start-Sleep 1 }
            }
        }
    }
}

function Show-MainMenu {
    while ($true) {
        Clear-Screen
        Write-Host "====================================" -ForegroundColor Cyan
        Write-Host "    OllamaTrauma PowerShell v2.0    " -ForegroundColor Cyan
        Write-Host "====================================" -ForegroundColor Cyan
        Write-Host ""
        
        $osInfo = Get-OSInfo
        Write-Host "Current OS: $($osInfo.Platform)" -ForegroundColor Green
        Write-Host "Current Model: $Global:SelectedModel" -ForegroundColor Green
        if ($Global:IsAnsible) {
            Write-Host "Mode: Ansible Automation" -ForegroundColor Yellow
        } else {
            Write-Host "Mode: Interactive" -ForegroundColor Blue
        }
        Write-Host ""
        Write-Host "1) Install/Run Ollama Model"
        Write-Host "2) Select Different Model"
        Write-Host "3) Advanced Operations"
        Write-Host "4) View Logs"
        Write-Host "5) Exit"
        Write-Host "===================================="
        
        if ($Global:IsAnsible) {
            $choice = $env:ANSIBLE_MAIN_CHOICE
            if (-not $choice) { $choice = "1" }
            Write-Log "INFO" "Ansible mode: Using main choice $choice" $Colors.Cyan
        } else {
            $choice = Read-Host "Enter your choice (1-5)"
        }
        
        switch ($choice) {
            "1" { Install-AndRunModel }
            "2" { Select-ModelInteractive }
            "3" { Show-AdvancedOperations }
            "4" {
                if (Test-Path $Global:LogFile) {
                    Write-Host "Recent log entries:" -ForegroundColor Green
                    Get-Content -Path $Global:LogFile -Tail 20
                } else {
                    Write-Host "No log file found." -ForegroundColor Yellow
                }
                Wait-ForUser
            }
            "5" {
                Write-Log "INFO" "Exiting OllamaTrauma PowerShell" $Colors.Green
                Write-Host "Thank you for using OllamaTrauma!" -ForegroundColor Green
                return
            }
            default {
                Write-Log "WARN" "Invalid option: $choice" $Colors.Yellow
                if (-not $Global:IsAnsible) { Start-Sleep 1 }
            }
        }
        
        # In Ansible mode, exit after one operation
        if ($Global:IsAnsible) {
            Write-Log "INFO" "Ansible operation completed" $Colors.Cyan
            return
        }
    }
}

# Main execution
try {
    Write-Log "INFO" "Starting OllamaTrauma PowerShell v2.0" $Colors.Green
    
    # Ensure config directory exists
    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }
    
    # Load configuration
    Load-Config
    
    # Handle install-only mode
    if ($InstallOnly) {
        Test-Dependencies
        Install-Ollama
        exit 0
    }
    
    # Check dependencies (skip in Ansible if requested)
    if (-not $Global:IsAnsible -or -not $env:ANSIBLE_SKIP_DEPS) {
        Test-Dependencies
    }
    
    # Save initial config
    Save-Config
    
    # Start main menu
    Show-MainMenu
    
} catch {
    Write-Log "ERROR" "Unexpected error: $($_.Exception.Message)" $Colors.Red
    if (-not $Global:IsAnsible) {
        Wait-ForUser "Press Enter to exit..."
    }
    exit 1
} finally {
    Save-Config
}
