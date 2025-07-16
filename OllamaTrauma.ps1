# OllamaTrauma - PowerShell version for Windows
# This script provides Ollama management functionality for Windows users

# Global variables
$SELECTED_MODEL = "mistral"
$OS = "windows"

# Function to check and install dependencies
function Check-Dependencies {
    Write-Host "Checking for required dependencies..."
    
    # Check if jq is installed
    if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
        Write-Host "jq not found. Installing..."
        
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Using winget to install jq..."
            winget install jqlang.jq
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Using Chocolatey to install jq..."
            choco install jq
        } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
            Write-Host "Using Scoop to install jq..."
            scoop install jq
        } else {
            Write-Host "WARNING: No Windows package manager found (winget, choco, scoop)."
            Write-Host "Please install jq manually:"
            Write-Host "1. Download from: https://github.com/jqlang/jq/releases"
            Write-Host "2. Or install Chocolatey: https://chocolatey.org/install"
            Write-Host "3. Then run: choco install jq"
        }
    } else {
        Write-Host "jq is already installed."
    }
    
    # Check if git is installed
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "git not found. Installing..."
        
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Using winget to install git..."
            winget install Git.Git
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Using Chocolatey to install git..."
            choco install git
        } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
            Write-Host "Using Scoop to install git..."
            scoop install git
        } else {
            Write-Host "WARNING: No Windows package manager found."
            Write-Host "Please install Git manually:"
            Write-Host "1. Download from: https://git-scm.com/download/win"
            Write-Host "2. Or install Chocolatey: https://chocolatey.org/install"
            Write-Host "3. Then run: choco install git"
        }
    } else {
        Write-Host "git is already installed."
    }
    
    # Check if Git LFS is installed
    if (-not (Get-Command git-lfs -ErrorAction SilentlyContinue)) {
        Write-Host "Git LFS not found. Installing..."
        
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Installing Git LFS via winget..."
            winget install GitHub.GitLFS
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Installing Git LFS via Chocolatey..."
            choco install git-lfs
        } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
            Write-Host "Installing Git LFS via Scoop..."
            scoop install git-lfs
        } else {
            Write-Host "WARNING: No Windows package manager found."
            Write-Host "Please install Git LFS manually:"
            Write-Host "1. Download from: https://git-lfs.github.io/"
            Write-Host "2. Or install Chocolatey: https://chocolatey.org/install"
            Write-Host "3. Then run: choco install git-lfs"
        }
    } else {
        Write-Host "Git LFS is already installed."
    }
}

# Function to install/update Ollama
function Install-Ollama {
    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        Write-Host "Ollama not found. Installing..."
        
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Using winget to install Ollama..."
            winget install Ollama.Ollama
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Using Chocolatey to install Ollama..."
            choco install ollama
        } else {
            Write-Host "Please install Ollama manually:"
            Write-Host "1. Download from: https://ollama.com/download/windows"
            Write-Host "2. Or install a package manager first:"
            Write-Host "   - Chocolatey: https://chocolatey.org/install"
            Write-Host "   - Scoop: https://scoop.sh/"
            Write-Host "   - Winget: Built into Windows 10/11"
            Write-Host "3. Then run: choco install ollama"
            return $false
        }
    } else {
        Write-Host "Ollama is already installed."
        $version = ollama --version 2>$null
        if ($version) {
            Write-Host "Current Ollama version: $version"
        }
        
        # Check for update options
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "You can update via winget: winget upgrade Ollama.Ollama"
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "You can update via Chocolatey: choco upgrade ollama"
        } else {
            Write-Host "You can update manually by downloading from: https://ollama.com/download/windows"
        }
    }
    return $true
}

# Function to clear screen
function Clear-Screen {
    Clear-Host
}

# Function to show main menu
function Show-MainMenu {
    Clear-Screen
    Write-Host "===== Ollama Management Tool (Windows) ====="
    Write-Host "Current OS: $OS"
    Write-Host "1) Install/Update and Run Model (Current: $SELECTED_MODEL)"
    Write-Host "2) Import/Search for a Model from HuggingFace.co"
    Write-Host "3) Delete Models"
    Write-Host "4) Exit"
    Write-Host "============================================="
    
    $choice = Read-Host "Enter your choice (1-4)"
    
    switch ($choice) {
        "1" { Install-AndRunModel }
        "2" { Import-HuggingFaceModel }
        "3" { Delete-Models }
        "4" { 
            Write-Host "Exiting..."
            exit 0
        }
        default { 
            Write-Host "Invalid option. Please try again."
            Start-Sleep -Seconds 1
            Show-MainMenu
        }
    }
}

# Function to install and run model
function Install-AndRunModel {
    Clear-Screen
    
    if (-not (Install-Ollama)) {
        Read-Host "Press Enter to return to main menu..."
        Show-MainMenu
        return
    }
    
    Write-Host "Checking for available models..."
    
    try {
        $modelList = ollama list | Select-Object -Skip 1 | ForEach-Object { 
            ($_ -split '\s+')[0] -split ':' | Select-Object -First 1
        } | Sort-Object -Unique
        
        if ($modelList.Count -eq 0) {
            Write-Host "No models found. Would you like to:"
            Write-Host "1) Pull the Mistral model"
            Write-Host "2) Pull a different model"
            Write-Host "3) Return to main menu"
            
            $choice = Read-Host "Enter choice (1-3)"
            
            switch ($choice) {
                "1" {
                    Write-Host "Pulling Mistral model..."
                    ollama pull mistral
                    $script:SELECTED_MODEL = "mistral"
                }
                "2" {
                    $pullModel = Read-Host "Enter model name to pull"
                    Write-Host "Pulling $pullModel model..."
                    ollama pull $pullModel
                    $script:SELECTED_MODEL = $pullModel
                }
                "3" {
                    Show-MainMenu
                    return
                }
                default {
                    Write-Host "Invalid choice. Returning to main menu."
                    Show-MainMenu
                    return
                }
            }
        } else {
            Write-Host "Available models:"
            Write-Host "----------------------------"
            
            for ($i = 0; $i -lt $modelList.Count; $i++) {
                $modelNum = $i + 1
                $modelInfo = ollama list | Select-String $modelList[$i] | Select-Object -First 1
                $modelSize = if ($modelInfo) { ($modelInfo -split '\s+')[2,3] -join ' ' } else { "Unknown" }
                Write-Host "$modelNum) $($modelList[$i]) ($modelSize)"
            }
            
            $pullOption = $modelList.Count + 1
            $currentOption = $modelList.Count + 2
            $returnOption = $modelList.Count + 3
            
            Write-Host "----------------------------"
            Write-Host "$pullOption) Pull a new model"
            Write-Host "$currentOption) Use current selection ($SELECTED_MODEL)"
            Write-Host "$returnOption) Return to main menu"
            Write-Host "----------------------------"
            
            $choice = Read-Host "Enter choice (1-$returnOption)"
            
            if ($choice -eq $returnOption) {
                Show-MainMenu
                return
            } elseif ($choice -eq $currentOption) {
                Write-Host "Using current selection: $SELECTED_MODEL"
            } elseif ($choice -eq $pullOption) {
                $pullModel = Read-Host "Enter model name to pull"
                Write-Host "Pulling $pullModel model..."
                ollama pull $pullModel
                $script:SELECTED_MODEL = $pullModel
            } elseif ($choice -ge 1 -and $choice -le $modelList.Count) {
                $script:SELECTED_MODEL = $modelList[$choice - 1]
                Write-Host "Selected model: $SELECTED_MODEL"
            } else {
                Write-Host "Invalid choice. Returning to main menu."
                Show-MainMenu
                return
            }
        }
        
        if ($SELECTED_MODEL) {
            Write-Host "Starting $SELECTED_MODEL LLM..."
            ollama run $SELECTED_MODEL
        }
    } catch {
        Write-Host "Error: $($_.Exception.Message)"
    }
    
    Read-Host "Press Enter to return to main menu..."
    Show-MainMenu
}

# Function to import HuggingFace model
function Import-HuggingFaceModel {
    Clear-Screen
    Write-Host "===== Hugging Face Model Import ====="
    Write-Host "1) Enter model URL manually"
    Write-Host "2) Return to main menu"
    Write-Host "=================================="
    
    $choice = Read-Host "Enter your choice (1-2)"
    
    switch ($choice) {
        "1" { 
            $modelUrl = Read-Host "Enter Hugging Face model URL or ID (e.g., TheBloke/Mistral-7B-Instruct-v0.1-GGUF)"
            if ($modelUrl) {
                Import-DirectUrl $modelUrl
            } else {
                Write-Host "No model specified. Returning to menu."
                Start-Sleep -Seconds 1
                Import-HuggingFaceModel
            }
        }
        "2" { Show-MainMenu }
        default { 
            Write-Host "Invalid option. Please try again."
            Start-Sleep -Seconds 1
            Import-HuggingFaceModel
        }
    }
}

# Function to import model from URL
function Import-DirectUrl {
    param($modelUrl)
    
    Write-Host "Importing model: $modelUrl"
    
    $modelName = Split-Path $modelUrl -Leaf
    
    # Check if directory exists
    if (Test-Path $modelName) {
        Write-Host "Directory '$modelName' already exists."
        $choice = Read-Host "Do you want to (r)esume download, (d)elete and start fresh, or (c)ancel? [r/d/c]"
        
        switch ($choice.ToLower()) {
            "r" {
                Write-Host "Resuming download..."
                Set-Location $modelName
                git lfs install
                git lfs pull
            }
            "d" {
                Write-Host "Deleting directory and starting fresh..."
                Remove-Item $modelName -Recurse -Force
            }
            default {
                Write-Host "Import cancelled."
                Import-HuggingFaceModel
                return
            }
        }
    }
    
    if (-not (Test-Path $modelName)) {
        Write-Host "Cloning the model repository..."
        git lfs install
        git clone "https://huggingface.co/$modelUrl"
        Set-Location $modelName
        git lfs pull
    } else {
        Set-Location $modelName
    }
    
    # Find GGUF files
    $ggufFiles = Get-ChildItem -Recurse -Filter "*.gguf" | Select-Object -ExpandProperty Name
    
    if ($ggufFiles.Count -eq 0) {
        Write-Host "No .gguf files found in repository."
        $ggufFile = Read-Host "Enter the exact GGUF file path (or press Enter to cancel)"
        if (-not $ggufFile) {
            Write-Host "No GGUF file specified. Import cancelled."
            Set-Location ..
            Import-HuggingFaceModel
            return
        }
    } elseif ($ggufFiles.Count -eq 1) {
        $ggufFile = $ggufFiles[0]
        Write-Host "Found GGUF file: $ggufFile"
    } else {
        Write-Host "Multiple GGUF files found:"
        for ($i = 0; $i -lt $ggufFiles.Count; $i++) {
            Write-Host "$($i + 1)) $($ggufFiles[$i])"
        }
        $choice = Read-Host "Select file number (1-$($ggufFiles.Count))"
        $ggufFile = $ggufFiles[$choice - 1]
    }
    
    # Create Modelfile
    $modelFileContent = @"
FROM "./$ggufFile"
TEMPLATE """
<|system|> {{ .System }} <|end|>
<|user|> {{ .Prompt }} <|end|>
<|assistant|> {{ .Response }} <|end|>
"""
"@
    
    try {
        $modelFileContent | Out-File -FilePath "Modelfile" -Encoding UTF8
        Write-Host "Created Modelfile"
        
        # Build model in Ollama
        Write-Host "Building the model in Ollama..."
        ollama create $modelName -f Modelfile
        
        $script:SELECTED_MODEL = $modelName
        
        Set-Location ..
        
        Write-Host "Starting the model $modelName..."
        ollama run $modelName
        
    } catch {
        Write-Host "Error: $($_.Exception.Message)"
        Set-Location ..
    }
    
    Read-Host "Press Enter to return to main menu..."
    Show-MainMenu
}

# Function to delete models
function Delete-Models {
    Clear-Screen
    Write-Host "===== Delete Models ====="
    Write-Host "This will remove selected models from Ollama"
    Write-Host "--------------------------------"
    
    try {
        $modelList = ollama list | Select-Object -Skip 1 | ForEach-Object { 
            ($_ -split '\s+')[0] -split ':' | Select-Object -First 1
        } | Sort-Object -Unique
        
        if ($modelList.Count -eq 0) {
            Write-Host "No models found to delete."
            Start-Sleep -Seconds 2
            Show-MainMenu
            return
        }
        
        Write-Host "Available models:"
        Write-Host "----------------------------"
        
        for ($i = 0; $i -lt $modelList.Count; $i++) {
            $modelNum = $i + 1
            $modelInfo = ollama list | Select-String $modelList[$i] | Select-Object -First 1
            $modelSize = if ($modelInfo) { ($modelInfo -split '\s+')[2,3] -join ' ' } else { "Unknown" }
            Write-Host "$modelNum) $($modelList[$i]) ($modelSize)"
        }
        
        $returnOption = $modelList.Count + 1
        Write-Host "----------------------------"
        Write-Host "$returnOption) Return to main menu"
        Write-Host "----------------------------"
        
        $choice = Read-Host "Enter model number to delete (1-$returnOption)"
        
        if ($choice -eq $returnOption) {
            Show-MainMenu
            return
        } elseif ($choice -ge 1 -and $choice -le $modelList.Count) {
            $modelToDelete = $modelList[$choice - 1]
            Write-Host "You are about to delete model: $modelToDelete"
            $confirm = Read-Host "Are you sure? (y/n)"
            
            if ($confirm.ToLower() -eq "y") {
                Write-Host "Deleting $modelToDelete..."
                ollama rm $modelToDelete
                
                if ($modelToDelete -eq $SELECTED_MODEL) {
                    $script:SELECTED_MODEL = "mistral"
                    Write-Host "Current model was deleted. New selected model: $SELECTED_MODEL"
                }
                
                Write-Host "Model deleted successfully."
                Start-Sleep -Seconds 1
                
                $another = Read-Host "Delete another model? (y/n)"
                if ($another.ToLower() -eq "y") {
                    Delete-Models
                } else {
                    Show-MainMenu
                }
            } else {
                Write-Host "Deletion cancelled."
                Start-Sleep -Seconds 1
                Delete-Models
            }
        } else {
            Write-Host "Invalid choice."
            Start-Sleep -Seconds 1
            Delete-Models
        }
    } catch {
        Write-Host "Error: $($_.Exception.Message)"
    }
}

# Main execution
Write-Host "Detected OS: $OS"
Check-Dependencies
Show-MainMenu
