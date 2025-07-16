# OllamaTrauma - Cross-Platform Ollama Management Tool

A comprehensive tool for managing Ollama models across **Linux**, **macOS**, and **Windows** platforms.

## Features

- 🚀 **Cross-platform support**: Works on Linux, macOS, Windows, and WSL
- 📦 **Automatic dependency installation**: Handles jq, git, git-lfs installation
- 🔍 **HuggingFace model search**: Browse and import GGUF models
- 📊 **Model management**: Install, update, delete, and switch between models
- 🎯 **Smart OS detection**: Automatically adapts to your operating system
- 🛠 **Multiple Windows environments**: Support for PowerShell, Git Bash, and WSL

## Platform Support

| Platform | Status | Script | Requirements |
|----------|---------|--------|-------------|
| **Linux** | ✅ Full Support | `OllamaTrauma.sh` | bash, curl |
| **macOS** | ✅ Full Support | `OllamaTrauma.sh` | bash, curl |
| **Windows** | ✅ Full Support | `OllamaTrauma.bat` | PowerShell or Git Bash |
| **WSL** | ✅ Full Support | `OllamaTrauma.sh` | bash, curl |

## Quick Start

### Linux / macOS / WSL
```bash
chmod +x OllamaTrauma.sh
./OllamaTrauma.sh
```

### Windows
```cmd
# Double-click or run from command prompt
OllamaTrauma.bat
```

Or directly with PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File OllamaTrauma.ps1
```

## Installation Methods by Platform

### Linux
The script supports multiple package managers:
- **Debian/Ubuntu**: `apt`
- **Fedora/RHEL**: `dnf`, `yum`
- **Arch Linux**: `pacman`
- **openSUSE**: `zypper`

### macOS
- **Homebrew** (recommended): `brew install`
- **MacPorts**: `port install`
- **Manual installation**: Direct downloads

### Windows
- **winget** (Windows 10/11): `winget install`
- **Chocolatey**: `choco install`
- **Scoop**: `scoop install`
- **Manual installation**: Direct downloads

## Dependencies

The script automatically installs these dependencies:

| Dependency | Purpose | Auto-install |
|------------|---------|--------------|
| **jq** | JSON processing | ✅ |
| **git** | Repository cloning | ✅ |
| **git-lfs** | Large file support | ✅ |
| **curl** | HTTP requests | Usually pre-installed |

## Main Features

### 1. Model Management
- Install and update Ollama
- List installed models
- Pull new models from Ollama registry
- Delete unwanted models
- Switch between models

### 2. HuggingFace Integration
- Browse popular GGUF models
- Search models by keywords
- Direct model URL import
- Automatic GGUF file detection

### 3. Cross-Platform Compatibility
- Automatic OS detection
- Platform-specific installation methods
- Proper temporary directory handling
- Cross-platform screen clearing

## Menu Options

The OllamaTrauma tool provides the following main menu options:

```
===== Ollama Management Tool =====
1) Install/Update and Run Models
2) Import Model from HuggingFace
3) Advanced LLM Operations (Train/Fine-tune)
4) Delete Models
5) Exit
==================================
Enter your choice (1-5):
```

## Platform-Specific Usage Instructions

### Linux

#### Option 1: Install/Update and Run Models
```bash
# Make script executable first
chmod +x OllamaTrauma.sh

# Run the script
./OllamaTrauma.sh

# Select option 1 from the menu
# This will:
# - Install Ollama if not present
# - Download and run popular models like Mistral
# - Start interactive chat session
```

#### Option 2: Import from HuggingFace
```bash
./OllamaTrauma.sh

# Select option 2 from the menu
# Enter HuggingFace model URL when prompted
# Examples:
# - TheBloke/Mistral-7B-Instruct-v0.1-GGUF
# - NousResearch/Nous-Hermes-2-Yi-34B-GGUF
# - microsoft/DialoGPT-medium-GGUF
```

#### Option 3: Advanced LLM Operations
```bash
./OllamaTrauma.sh

# Select option 3 from the menu
# This provides:
# - Fine-tuning capabilities
# - RAG (Retrieval Augmented Generation)
# - Custom dataset training
```

#### Option 4: Delete Models
```bash
./OllamaTrauma.sh

# Select option 4 from the menu
# View installed models and select which to delete
```

### macOS

#### Option 1: Install/Update and Run Models
```bash
# Make script executable first
chmod +x OllamaTrauma.sh

# Run the script
./OllamaTrauma.sh

# Select option 1 from the menu
# macOS will automatically use Homebrew if available
# Or fall back to manual installation
```

#### Option 2: Import from HuggingFace
```bash
./OllamaTrauma.sh

# Select option 2 from the menu
# macOS supports all HuggingFace GGUF models
# Git LFS will be automatically installed via Homebrew
```

#### Option 3: Advanced LLM Operations
```bash
./OllamaTrauma.sh

# Select option 3 from the menu
# Ensure you have Python 3 installed:
# brew install python3
```

#### Option 4: Delete Models
```bash
./OllamaTrauma.sh

# Select option 4 from the menu
# Models are stored in ~/.ollama/models
```

### Windows

#### Option 1: Install/Update and Run Models

**Using Batch Launcher (Recommended):**
```cmd
# Double-click OllamaTrauma.bat or run:
OllamaTrauma.bat

# Select option 1 from the menu
# Windows will use winget, chocolatey, or manual installation
```

**Using PowerShell:**
```powershell
# Set execution policy if needed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run PowerShell script directly
powershell -ExecutionPolicy Bypass -File OllamaTrauma.ps1

# Select option 1 from the menu
```

**Using Git Bash:**
```bash
# Install Git for Windows first
# Then run:
bash OllamaTrauma.sh

# Select option 1 from the menu
```

**Using WSL:**
```bash
# In WSL terminal:
chmod +x OllamaTrauma.sh
./OllamaTrauma.sh

# Select option 1 from the menu
```

#### Option 2: Import from HuggingFace

**Using Batch Launcher:**
```cmd
OllamaTrauma.bat

# Select option 2 from the menu
# Enter HuggingFace model repository
# Git LFS will be automatically installed
```

**Using PowerShell:**
```powershell
.\OllamaTrauma.ps1

# Select option 2 from the menu
# Support for winget, chocolatey, or manual Git LFS installation
```

**Using Git Bash:**
```bash
bash OllamaTrauma.sh

# Select option 2 from the menu
# Uses Git Bash environment for cloning
```

**Using WSL:**
```bash
./OllamaTrauma.sh

# Select option 2 from the menu
# Full Linux compatibility in WSL environment
```

#### Option 3: Advanced LLM Operations

**Using Batch Launcher:**
```cmd
OllamaTrauma.bat

# Select option 3 from the menu
# Requires Python to be installed
# Install Python from: https://python.org
```

**Using PowerShell:**
```powershell
.\OllamaTrauma.ps1

# Select option 3 from the menu
# Python will be installed via winget/chocolatey if available
```

**Using WSL:**
```bash
./OllamaTrauma.sh

# Select option 3 from the menu
# Full Python environment available in WSL
```

#### Option 4: Delete Models

**All Windows Methods:**
```cmd
# Any of the above methods work
# Select option 4 from the menu
# Models are stored in %USERPROFILE%\.ollama\models
```

## Usage Examples

### Basic Model Management
```bash
# Linux/macOS/WSL
./OllamaTrauma.sh

# Windows (multiple options)
OllamaTrauma.bat
# or
powershell -ExecutionPolicy Bypass -File OllamaTrauma.ps1
# or
bash OllamaTrauma.sh

# Then choose option 1 to install/update and run models
# Choose option 2 to import from HuggingFace
# Choose option 4 to delete models
```

### Direct HuggingFace Import Examples
The script can import models like:
- `TheBloke/Mistral-7B-Instruct-v0.1-GGUF`
- `NousResearch/Nous-Hermes-2-Yi-34B-GGUF`
- `microsoft/DialoGPT-medium-GGUF`
- `TheBloke/CodeLlama-13B-Instruct-GGUF`
- `lmsys/vicuna-7b-v1.5-GGUF`

## Windows Environment Options

Windows users have multiple ways to run OllamaTrauma, each with different advantages:

### Option 1: Batch Launcher (Recommended for most users)
```cmd
# Double-click OllamaTrauma.bat or run from command prompt:
OllamaTrauma.bat

# Advantages:
# - No setup required
# - Automatic environment detection
# - Works with all Windows versions
# - Handles execution policy automatically
```

### Option 2: PowerShell Direct (For advanced users)
```powershell
# Run PowerShell as Administrator (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run the PowerShell script directly:
powershell -ExecutionPolicy Bypass -File OllamaTrauma.ps1

# Advantages:
# - Direct PowerShell execution
# - Full Windows integration
# - Access to all Windows package managers
```

### Option 3: Git Bash (For Unix-like experience)
```bash
# Install Git for Windows first: https://git-scm.com/download/win
# Then run in Git Bash:
bash OllamaTrauma.sh

# Advantages:
# - Unix-like environment
# - Full bash shell features
# - Compatible with Linux/macOS workflows
```

### Option 4: WSL (For Linux compatibility)
```bash
# In WSL terminal:
chmod +x OllamaTrauma.sh
./OllamaTrauma.sh

# Advantages:
# - Full Linux compatibility
# - Better performance for some operations
# - Access to Linux package managers
# - GPU acceleration support
```

## macOS Environment Options

### Option 1: Terminal (Recommended)
```bash
# Make script executable:
chmod +x OllamaTrauma.sh

# Run the script:
./OllamaTrauma.sh

# Advantages:
# - Native macOS environment
# - Automatic Homebrew integration
# - Full compatibility with macOS security
```

### Option 2: iTerm2 (Enhanced terminal)
```bash
# Install iTerm2: https://iterm2.com/
# Same commands as above but with enhanced features
./OllamaTrauma.sh

# Advantages:
# - Better terminal features
# - Improved text rendering
# - Advanced configuration options
```

## Linux Environment Options

### Option 1: Native Bash (Recommended)
```bash
# Make script executable:
chmod +x OllamaTrauma.sh

# Run the script:
./OllamaTrauma.sh

# Advantages:
# - Native Linux environment
# - Full package manager support
# - Optimal performance
```

### Option 2: Different Shells
```bash
# For zsh users:
zsh OllamaTrauma.sh

# For fish users:
fish OllamaTrauma.sh

# Advantages:
# - Use your preferred shell
# - Custom shell features available
```

## Package Managers

### Installing Package Managers (Windows)

#### Chocolatey
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

#### Scoop
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

#### winget
- Pre-installed on Windows 10 (version 1809+) and Windows 11
- Can be installed from Microsoft Store

## Troubleshooting

### Permission Issues
```bash
# Linux/macOS: Make script executable
chmod +x OllamaTrauma.sh

# Windows: Run as Administrator if needed
```

### PowerShell Execution Policy
```powershell
# Allow local scripts to run
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Git LFS Issues
```bash
# Manual Git LFS installation
git lfs install
git lfs pull
```

### WSL GPU Access
```bash
# For GPU acceleration in WSL
# Install NVIDIA drivers for WSL
# Set up CUDA in WSL environment
```

## Advanced Features

### Environment Variables
- `TMPDIR` (macOS): Temporary directory
- `TEMP`/`TMP` (Windows): Temporary directory
- `WSL_DISTRO_NAME`: WSL detection
- `WSLENV`: WSL environment detection

### Model Template Customization
The script uses a default chat template. You can modify the Modelfile template in the `import_direct_url` function.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test on multiple platforms
4. Submit a pull request

## License

This project is open source. Feel free to use and modify according to your needs.

## Support

- **Issues**: Report bugs and request features
- **Platform Testing**: Help test on different operating systems
- **Documentation**: Improve setup instructions

---

**Note**: This tool is designed to work with GGUF format models from HuggingFace. Make sure your models are in the correct format before importing.