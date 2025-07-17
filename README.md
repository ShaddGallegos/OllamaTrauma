# OllamaTrauma - Cross-Platform Ollama Management Tool

A comprehensive tool for managing Ollama models across **Linux**, **macOS**, and **Windows** platforms.

## Features

- **Cross-platform support**: Works on Linux, macOS, Windows, and WSL
- **Automatic dependency installation**: Handles jq, git, git-lfs installation
- **HuggingFace model search**: Browse and import GGUF models
- **Model management**: Install, update, delete, and switch between models
- **Smart OS detection**: Automatically adapts to your operating system
- **Multiple Windows environments**: Support for PowerShell, Git Bash, and WSL
- **Python implementation**: Pure Python script for cross-platform compatibility
- **Ansible automation**: Infrastructure-as-code approach for deployments
- **Multiple interfaces**: Choose between shell scripts, Python script, or Ansible playbook

## Platform Support

| Platform | Status | Shell Script | Python Script | Ansible | Requirements |
|----------|---------|--------------|---------------|---------|-------------|
| **Linux** | ✅ | `OllamaTrauma.sh` | `OllamaTrauma.py` | `OllamaTrauma.yml` | bash, curl, python3 |
| **macOS** | ✅ | `OllamaTrauma.sh` | `OllamaTrauma.py` | `OllamaTrauma.yml` | bash, curl, python3 |
| **Windows** | ✅ | `OllamaTrauma.bat` | `OllamaTrauma.py` | `OllamaTrauma.yml` (WSL/Git Bash) | PowerShell/Git Bash, python3 |
| **WSL** | ✅ | `OllamaTrauma.sh` | `OllamaTrauma.py` | `OllamaTrauma.yml` | bash, curl, python3 |

## Quick Start

### Shell Scripts

#### Linux / macOS / WSL
```bash
chmod +x OllamaTrauma.sh
./OllamaTrauma.sh
```

#### Windows
```cmd
# Double-click or run from command prompt
OllamaTrauma.bat
```

Or directly with PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File OllamaTrauma.ps1
```

### Python Script

#### All Platforms (Requires Python 3.6+)
```bash
# Make executable (Linux/macOS/WSL)
chmod +x OllamaTrauma.py

# Run the Python script
python3 OllamaTrauma.py
# or
./OllamaTrauma.py

# Windows
python OllamaTrauma.py
```

### Ansible Playbook

#### Prerequisites
First, install Ansible on your system:

**Linux (RHEL/CentOS/Fedora):**
```bash
sudo dnf install ansible-core
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update && sudo apt install ansible
```

**macOS:**
```bash
brew install ansible
```

**Windows (WSL/Git Bash):**
```bash
# In WSL or Git Bash
sudo apt install ansible  # WSL Ubuntu
# or
brew install ansible      # Git Bash with Homebrew
```

#### Running the Ansible Playbook
```bash
# Navigate to the project directory
cd /path/to/OllamaTrauma

# Run the playbook
ansible-playbook OllamaTrauma.yml

# Follow the interactive prompts to select options
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

## Ansible Playbook Alternative

In addition to the shell scripts, OllamaTrauma provides an Ansible playbook (`OllamaTrauma.yml`) for automated, infrastructure-as-code management of Ollama models.

### Ansible Playbook Features

The `OllamaTrauma.yml` playbook provides the same functionality as the shell scripts but with the following advantages:

- **Idempotent operations**: Tasks only run when needed
- **Better error handling**: Comprehensive error checking and reporting
- **Structured approach**: Clear task organization and flow
- **Cross-platform compatibility**: Works on Linux, macOS, and Windows (via WSL/Git Bash)
- **Infrastructure as Code**: Version-controlled automation

### Ansible Menu Options

```
===== Ollama Management Tool =====
1) Install/Update and Run Mistral
2) Import Model from Hugging Face
3) Advanced LLM Operations
4) Exit
==================================
Enter your choice (1-4)
```

### Ansible Playbook Usage

#### Option 1: Install/Update and Run Mistral
```bash
ansible-playbook OllamaTrauma.yml
# Select option 1

# This will:
# - Check if Ollama is installed
# - Install Ollama if not present (via curl script)
# - Update Ollama if already installed
# - List available models
# - Pull Mistral model if not available
# - Run Mistral model interactively
# - Display connection information
```

#### Option 2: Import Model from Hugging Face
```bash
ansible-playbook OllamaTrauma.yml
# Select option 2

# This will:
# - Prompt for HuggingFace model URL
# - Install Git LFS if not present
# - Clone the model repository
# - Find GGUF files in the repository
# - Create Ollama Modelfile with proper template
# - Build the model in Ollama
# - Run the imported model
```

**Example HuggingFace URLs:**
- `hf.co/TheBloke/Mistral-7B-Instruct-v0.1-GGUF`
- `hf.co/NousResearch/Nous-Hermes-2-Yi-34B-GGUF`
- `hf.co/microsoft/DialoGPT-medium-GGUF`

#### Option 3: Advanced LLM Operations
```bash
ansible-playbook OllamaTrauma.yml
# Select option 3

# Choose from:
# 1) Fine-tune an LLM with a dataset
# 2) Use embeddings for retrieval (RAG)
# 3) Fine-tune an LLM in Ollama
```

**Sub-option 1: Fine-tune with Dataset**
- Prompts for model name and dataset file
- Runs custom training script (`train.py`)
- Displays fine-tuning output

**Sub-option 2: Embeddings for RAG**
- Prompts for text data
- Installs sentence-transformers library
- Creates embeddings using SentenceTransformer
- Displays embedding output

**Sub-option 3: Fine-tune in Ollama**
- Prompts for dataset file
- Runs Ollama fine-tuning command
- Outputs fine-tuned model

### Ansible Playbook Structure

The playbook consists of several key sections:

#### Variables and Prompts
```yaml
vars_prompt:
  - name: main_choice
    prompt: |
      ===== Ollama Management Tool =====
      1) Install/Update and Run Mistral
      2) Import Model from Hugging Face
      3) Advanced LLM Operations
      4) Exit
      ==================================
      Enter your choice (1-4)
    private: false
```

#### Pre-tasks
```yaml
pre_tasks:
  - name: Exit if chosen
    meta: end_play
    when: main_choice == "4"
```

#### Main Tasks
The playbook uses conditional blocks (`when:`) to execute different task sets based on user choice:

- **Block 1**: Ollama installation and Mistral setup
- **Block 2**: HuggingFace model import workflow
- **Block 3**: Advanced LLM operations with sub-choices

### Key Ansible Features Used

#### Error Handling
```yaml
- name: Check if GGUF files exist
  fail:
    msg: "No GGUF file found in the repository. Make sure the model supports GGUF format."
  when: gguf_files.matched == 0
```

#### Conditional Execution
```yaml
- name: Install Ollama
  shell: curl -fsSL https://ollama.com/install.sh | sh
  when: ollama_check.rc != 0
```

#### File Operations
```yaml
- name: Create Modelfile
  copy:
    dest: "/tmp/{{ model_name }}/Modelfile"
    content: |
      FROM "./{{ gguf_file }}"
      TEMPLATE """
      <|system|> {{ '{{' }} .System {{ '}}' }} <|end|>
      <|user|> {{ '{{' }} .Prompt {{ '}}' }} <|end|>
      <|assistant|> {{ '{{' }} .Response {{ '}}' }} <|end|>
      """
```

#### Git Operations
```yaml
- name: Clone model repository
  git:
    repo: "https://huggingface.co/{{ model_url }}"
    dest: "/tmp/{{ model_name }}"
    force: yes
```

### Ansible vs Shell Scripts Comparison

| Feature | Shell Scripts | Ansible Playbook |
|---------|---------------|------------------|
| **Ease of Use** | Simple execution | Requires Ansible installation |
| **Error Handling** | Basic | Advanced with structured error messages |
| **Idempotency** | Limited | Full idempotent operations |
| **Logging** | Basic output | Structured task reporting |
| **Modularity** | Single script | Modular task-based approach |
| **Version Control** | Good | Excellent (Infrastructure as Code) |
| **Cross-platform** | Native scripts | Unified approach |
| **Debugging** | Manual | Built-in debugging features |

### Running Ansible Playbook on Different Platforms

#### Linux
```bash
# Install Ansible
sudo dnf install ansible-core  # RHEL/CentOS/Fedora
sudo apt install ansible       # Ubuntu/Debian
sudo pacman -S ansible         # Arch Linux

# Run playbook
ansible-playbook OllamaTrauma.yml
```

#### macOS
```bash
# Install Ansible
brew install ansible

# Run playbook
ansible-playbook OllamaTrauma.yml
```

#### Windows
**Using WSL:**
```bash
# In WSL terminal
sudo apt install ansible
ansible-playbook OllamaTrauma.yml
```

**Using Git Bash (with Homebrew):**
```bash
# Install Homebrew for Git Bash first
brew install ansible
ansible-playbook OllamaTrauma.yml
```

### Ansible Playbook Advantages

1. **Idempotent Operations**: Tasks only run when changes are needed
2. **Better Error Handling**: Comprehensive error checking and user-friendly messages
3. **Structured Workflow**: Clear task organization and dependencies
4. **Version Control Friendly**: YAML format works well with Git
5. **Extensible**: Easy to add new features and modify existing ones
6. **Cross-platform Consistency**: Same playbook works across different operating systems
7. **Infrastructure as Code**: Treat your LLM management as code
8. **Debugging Support**: Built-in verbose mode and debugging capabilities

## Python Script Alternative

OllamaTrauma also provides a Python script (`OllamaTrauma.py`) that offers the same functionality as the shell scripts but with Python's cross-platform capabilities and additional features.

### Python Script Features

The `OllamaTrauma.py` script provides all the functionality of the shell scripts with these additional advantages:

- **Pure Python**: No shell dependencies, works wherever Python runs
- **Cross-platform compatibility**: Single script works on Linux, macOS, and Windows
- **Better error handling**: Comprehensive exception handling and user feedback
- **Modular design**: Object-oriented structure for easy maintenance and extension
- **Type hints**: Better code documentation and IDE support
- **Timeout handling**: Prevents hanging on long-running operations
- **Automatic dependency detection**: Smart package manager detection per platform

### Python Script Requirements

- **Python 3.6+**: Required for all platforms
- **Standard library**: Uses only built-in Python modules for core functionality
- **Optional dependencies**: Automatically installs required packages when needed

### Python Script Usage

#### Basic Usage
```python
# Run the Python script
python3 OllamaTrauma.py

# Or make it executable and run directly (Linux/macOS/WSL)
chmod +x OllamaTrauma.py
./OllamaTrauma.py
```

#### Menu Options (Same as Shell Scripts)
```
===== Ollama Management Tool =====
1) Install/Update and Run Models
2) Import Model from HuggingFace
3) Advanced LLM Operations
4) Delete Models
5) Exit
==================================
```

#### Option 1: Install/Update and Run Models
```python
# The Python script will:
# - Check Python version compatibility
# - Detect operating system automatically
# - Install Ollama using appropriate method
# - Pull Mistral model if not available
# - Run Mistral interactively
# - Display connection information
```

#### Option 2: Import Model from HuggingFace
```python
# The Python script will:
# - Prompt for HuggingFace model URL
# - Auto-detect and install Git/Git LFS
# - Clone repository to temporary directory
# - Find GGUF files automatically
# - Create proper Modelfile
# - Build and optionally run the model
```

#### Option 3: Advanced LLM Operations
```python
# Sub-options available:
# 1) Fine-tune with dataset (creates train.py template)
# 2) Create embeddings for RAG (auto-installs sentence-transformers)
# 3) Fine-tune in Ollama (if supported)
```

#### Option 4: Delete Models
```python
# The Python script will:
# - List all installed models
# - Allow selection and confirmation
# - Delete selected models safely
```

### Python Script Platform Support

#### Linux
```bash
# Install Python 3 (if not already installed)
sudo apt install python3 python3-pip  # Ubuntu/Debian
sudo dnf install python3 python3-pip  # RHEL/CentOS/Fedora

# Run the script
python3 OllamaTrauma.py
```

#### macOS
```bash
# Python 3 is usually pre-installed
# Or install via Homebrew
brew install python3

# Run the script
python3 OllamaTrauma.py
```

#### Windows
```cmd
# Download Python from https://python.org
# Or install via package manager
winget install Python.Python.3
# or
choco install python

# Run the script
python OllamaTrauma.py
```

#### WSL
```bash
# Same as Linux
sudo apt install python3 python3-pip
python3 OllamaTrauma.py
```

### Python Script Architecture

The Python script is organized into a main `OllamaTrauma` class with the following key methods:

#### Core Methods
```python
class OllamaTrauma:
    def __init__(self):              # Initialize with OS detection
    def clear_screen(self):          # Cross-platform screen clearing
    def run_command(self):           # Execute system commands safely
    def check_dependency(self):      # Check if tools are installed
    def install_dependency(self):    # Install missing dependencies
```

#### Ollama Management
```python
    def install_ollama(self):        # Install/update Ollama
    def list_models(self):           # List installed models
    def pull_model(self):            # Pull models from registry
    def run_model(self):             # Run models interactively
    def delete_model(self):          # Delete models safely
```

#### Advanced Features
```python
    def import_huggingface_model(self):  # Import from HuggingFace
    def advanced_operations(self):       # Advanced LLM operations
    def finetune_with_dataset(self):     # Fine-tuning with datasets
    def create_embeddings(self):         # RAG embeddings
```

### Python Script vs Other Approaches

| Feature | Shell Scripts | Python Script | Ansible Playbook |
|---------|---------------|---------------|------------------|
| **Installation** | None required | Python 3.6+ required | Ansible required |
| **Cross-platform** | Multiple scripts | Single script | Single playbook |
| **Dependencies** | OS-specific tools | Pure Python | Ansible + Python |
| **Error Handling** | Basic | Advanced | Advanced |
| **Modularity** | Limited | High (OOP) | High (tasks) |
| **Extensibility** | Medium | High | High |
| **Debugging** | Manual | Built-in | Built-in |
| **Type Safety** | None | Type hints | Limited |
| **Performance** | Fast | Good | Good |
| **Learning Curve** | Low | Medium | Medium |

### Python Script Advantages

1. **Single File**: One script works across all platforms
2. **No Shell Dependencies**: Pure Python implementation
3. **Better Error Messages**: Detailed exception handling
4. **Timeout Protection**: Prevents hanging operations
5. **Automatic Detection**: Smart OS and package manager detection
6. **Modular Design**: Easy to extend and maintain
7. **Type Hints**: Better code documentation
8. **Standard Library**: Minimal external dependencies

### Python Script Examples

#### Basic Model Management
```bash
# Run the Python script
python3 OllamaTrauma.py

# Same menu as shell scripts
# Select option 1 for model installation
# Select option 2 for HuggingFace import
# Select option 4 for model deletion
```

#### Advanced Usage
```python
# The script automatically handles:
# - OS detection (Linux/macOS/Windows)
# - Package manager detection
# - Dependency installation
# - Error recovery
# - User input validation
```

#### Import HuggingFace Model Example
```python
# Example workflow:
# 1. Run: python3 OllamaTrauma.py
# 2. Select option 2
# 3. Enter: TheBloke/Mistral-7B-Instruct-v0.1-GGUF
# 4. Script automatically:
#    - Installs git and git-lfs if needed
#    - Clones the repository
#    - Finds GGUF files
#    - Creates Modelfile
#    - Builds model in Ollama
#    - Offers to run the model
```

### Python Script Troubleshooting

#### Common Issues

**Python Version Error**
```bash
# Check Python version
python3 --version

# Install Python 3.6+ if needed
sudo apt install python3  # Linux
brew install python3      # macOS
```

**Permission Errors**
```bash
# Make script executable (Linux/macOS)
chmod +x OllamaTrauma.py

# Run with appropriate permissions
sudo python3 OllamaTrauma.py  # If needed
```

**Module Import Errors**
```bash
# The script auto-installs required modules
# If manual installation needed:
pip3 install sentence-transformers  # For embeddings
```

**Git/Git LFS Issues**
```bash
# The script will attempt to install automatically
# Manual installation if needed:
sudo apt install git git-lfs      # Linux
brew install git git-lfs          # macOS
```

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

### Shell Scripts

#### Basic Model Management
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

### Python Script

#### Basic Model Management
```bash
# All platforms (requires Python 3.6+)
python3 OllamaTrauma.py

# Linux/macOS/WSL (if made executable)
./OllamaTrauma.py

# Windows
python OllamaTrauma.py

# Same menu options as shell scripts
# Choose option 1 for model installation
# Choose option 2 for HuggingFace import
# Choose option 3 for advanced operations
# Choose option 4 for model deletion
```

#### Python Script Advanced Examples
```bash
# The Python script automatically handles:
# - Cross-platform compatibility
# - Dependency detection and installation
# - Error handling and recovery
# - User input validation
# - Temporary file cleanup
```

### Ansible Playbook

#### Basic Model Management
```bash
# Run the playbook
ansible-playbook OllamaTrauma.yml

# Select option 1 for Mistral installation
# Select option 2 for HuggingFace import
# Select option 3 for advanced operations
```

#### Advanced Usage Examples
```bash
# Run with verbose output
ansible-playbook -v OllamaTrauma.yml

# Run in check mode (dry run)
ansible-playbook --check OllamaTrauma.yml

# Run with custom variables
ansible-playbook OllamaTrauma.yml -e "model_name=custom_model"
```

### Direct HuggingFace Import Examples
All scripts/playbooks can import models like:
- `TheBloke/Mistral-7B-Instruct-v0.1-GGUF`
- `NousResearch/Nous-Hermes-2-Yi-34B-GGUF`
- `microsoft/DialoGPT-medium-GGUF`
- `TheBloke/CodeLlama-13B-Instruct-GGUF`
- `lmsys/vicuna-7b-v1.5-GGUF`

### Comparison Examples

#### Shell Script Approach
```bash
# Quick and simple
./OllamaTrauma.sh
# Interactive menu appears immediately
```

#### Python Script Approach
```bash
# Cross-platform and robust
python3 OllamaTrauma.py
# Same menu with better error handling
```

#### Ansible Playbook Approach
```bash
# Infrastructure as code
ansible-playbook OllamaTrauma.yml
# Same menu with idempotent operations
```

### Integration Examples

#### Using All Three Together
```bash
# Use shell script for quick local testing
./OllamaTrauma.sh

# Use Python script for cross-platform deployments
python3 OllamaTrauma.py

# Use Ansible playbook for infrastructure automation
ansible-playbook OllamaTrauma.yml

# Use Ansible for automated CI/CD pipelines
ansible-playbook OllamaTrauma.yml --extra-vars "main_choice=1"
```

### Platform-Specific Examples

#### Linux Examples
```bash
# Shell script
./OllamaTrauma.sh

# Python script
python3 OllamaTrauma.py

# Ansible playbook
ansible-playbook OllamaTrauma.yml
```

#### macOS Examples
```bash
# Shell script
./OllamaTrauma.sh

# Python script
python3 OllamaTrauma.py

# Ansible playbook
ansible-playbook OllamaTrauma.yml
```

#### Windows Examples
```cmd
# Batch script
OllamaTrauma.bat

# Python script
python OllamaTrauma.py

# PowerShell script
powershell -ExecutionPolicy Bypass -File OllamaTrauma.ps1

# Ansible (in WSL/Git Bash)
ansible-playbook OllamaTrauma.yml
```

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

### Shell Scripts

#### Permission Issues
```bash
# Linux/macOS: Make script executable
chmod +x OllamaTrauma.sh

# Windows: Run as Administrator if needed
```

#### PowerShell Execution Policy
```powershell
# Allow local scripts to run
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Git LFS Issues
```bash
# Manual Git LFS installation
git lfs install
git lfs pull
```

#### WSL GPU Access
```bash
# For GPU acceleration in WSL
# Install NVIDIA drivers for WSL
# Set up CUDA in WSL environment
```

### Python Script

#### Python Version Issues
```bash
# Check Python version (requires 3.6+)
python3 --version

# Install Python 3 if needed
sudo apt install python3 python3-pip  # Ubuntu/Debian
sudo dnf install python3 python3-pip  # RHEL/CentOS/Fedora
brew install python3                  # macOS
```

#### Permission Issues
```bash
# Make script executable (Linux/macOS/WSL)
chmod +x OllamaTrauma.py

# Run with appropriate permissions
python3 OllamaTrauma.py
```

#### Module Import Errors
```bash
# Most dependencies are auto-installed
# For manual installation:
pip3 install sentence-transformers  # For RAG embeddings

# If pip is missing:
sudo apt install python3-pip  # Ubuntu/Debian
sudo dnf install python3-pip  # RHEL/CentOS/Fedora
```

#### Cross-Platform Path Issues
```bash
# The Python script handles paths automatically
# If you encounter issues, check:
python3 -c "import tempfile; print(tempfile.gettempdir())"
```

#### Timeout Issues
```bash
# The script has built-in timeout handling
# If operations hang, interrupt with Ctrl+C
# The script will handle cleanup automatically
```

### Ansible Playbook

#### Ansible Installation Issues
```bash
# If ansible-config command not found
# RHEL/CentOS/Fedora:
sudo dnf install ansible-core

# Ubuntu/Debian:
sudo apt update && sudo apt install ansible

# macOS:
brew install ansible

# Verify installation:
ansible --version
```

#### Playbook Execution Issues
```bash
# Run with verbose output for debugging
ansible-playbook -v OllamaTrauma.yml

# Run with extra verbose output
ansible-playbook -vv OllamaTrauma.yml

# Check syntax without running
ansible-playbook --syntax-check OllamaTrauma.yml
```

#### Common Ansible Errors

**Error: "No module named 'sentence_transformers'"**
```bash
# Install Python dependencies
pip install sentence-transformers
# or
pip3 install sentence-transformers
```

**Error: "Git LFS not installed"**
```bash
# Install Git LFS manually
git lfs install
# Verify installation
git lfs version
```

**Error: "Permission denied" when running Ollama**
```bash
# Add user to ollama group (if exists)
sudo usermod -a -G ollama $USER

# Or run with sudo (not recommended for production)
sudo ansible-playbook OllamaTrauma.yml
```

**Error: "Python module not found"**
```bash
# Ensure Python 3 is installed
python3 --version

# Install pip if missing
sudo apt install python3-pip  # Ubuntu/Debian
sudo dnf install python3-pip  # RHEL/CentOS/Fedora
```

#### Debugging Ansible Playbook
```bash
# Run specific tasks only
ansible-playbook OllamaTrauma.yml --tags "install"

# Skip certain tasks
ansible-playbook OllamaTrauma.yml --skip-tags "huggingface"

# Run in check mode (dry run)
ansible-playbook OllamaTrauma.yml --check

# Start at specific task
ansible-playbook OllamaTrauma.yml --start-at-task "Install Ollama"
```

#### HuggingFace Model Issues
```bash
# If model repository is private
git config --global credential.helper store
# Then enter HuggingFace credentials when prompted

# If GGUF files are missing
# Make sure the model repository contains .gguf files
# Check the model card on HuggingFace for supported formats
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