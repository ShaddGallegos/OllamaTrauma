# OllamaTrauma

**Created:** August 2025

## Synopsis

OllamaTrauma is a comprehensive cross-platform tool for managing Ollama AI model installations, configuration, and interactions. It provides automated installation, service management, and interactive model handling across multiple platforms and programming languages.

## Supported Operating Systems

- Linux (Ubuntu, Debian, CentOS, RHEL, Fedora, Arch, openSUSE)
- macOS (Intel and Apple Silicon)
- Windows 10/11
- Windows Subsystem for Linux (WSL)

## Quick Usage

### Basic Execution
```bash
# Bash version (Linux/macOS/WSL)
./OllamaTrauma.sh

# PowerShell version (Windows)
./OllamaTrauma.ps1

# Python version (Cross-platform)
python3 ollama_trauma.py

# Java version (Cross-platform)
java -jar ollama-trauma.jar
```

### Command Line Options
```bash
# Install only mode
./OllamaTrauma.sh --install-only

# Specify configuration directory
./OllamaTrauma.sh --config-dir /path/to/config

# Select specific model
./OllamaTrauma.sh --model llama2

# Quiet mode
./OllamaTrauma.sh --quiet
```

### Interactive Menu System

Main Menu Options:
1. Install System Dependencies
2. Install/Update Ollama
3. Start Ollama Service
4. Stop Ollama Service  
5. Check Ollama Status
6. Download AI Model
7. List Available Models
8. List Downloaded Models
9. Remove Model
10. Chat with Model
11. Configure Settings
12. View Logs
13. System Information
14. Exit

Model Management Menu:
- Download popular models (llama2, codellama, mistral, etc.)
- Interactive model selection
- Model removal with confirmation
- Model usage statistics

## Features and Capabilities

### Core Features
- Cross-platform package manager detection and integration
- Automated Ollama service installation and management
- Interactive AI model downloading and management
- Real-time chat interface with AI models
- Configuration file management with JSON support
- Comprehensive logging and error handling
- Color-coded console output for better usability

### Advanced Features
- Training data collection and organization
- URL crawling for training data with redirect handling
- Ansible automation integration
- Multi-language implementations (Bash, Python, PowerShell, Java)
- Native compilation support (Java with GraalVM)
- Service status monitoring and health checks
- Automatic dependency resolution

### Package Manager Support
- APT (Debian/Ubuntu)
- YUM/DNF (CentOS/RHEL/Fedora) 
- Pacman (Arch Linux)
- Homebrew (macOS)
- Chocolatey (Windows)
- Zypper (openSUSE)
- And many more

### Language-Specific Implementations
- **OllamaTrauma-java/**: Enterprise Java implementation with Maven/Gradle builds
- **OllamaTrauma-python/**: Python implementation with cross-platform support
- **OllamaTrauma-ansible/**: Ansible playbooks and automation
- **OllamaTrauma-TrainingData/**: Training data collection and management

## Limitations

- Requires internet connectivity for initial setup and model downloads
- Some features require administrative privileges for system-level installations
- Model downloads can be large (several GB) and require sufficient disk space
- Performance depends on available system resources (RAM, CPU, storage)
- Windows Subsystem for Linux may have limitations with service management

## Getting Help

### Documentation
- Check the language-specific subdirectories for detailed implementation guides
- Review the configuration files for available options
- Examine the log files for troubleshooting information

### Support Resources
- Use the --help option for command-line help
- Enable verbose logging with --verbose for detailed operation information
- Check system requirements before installation
- Ensure proper permissions for installation and service management

### Common Issues
- Network connectivity problems: Check internet access and firewall settings
- Permission errors: Run with appropriate privileges or adjust file permissions
- Service startup failures: Check system logs and service status
- Model download failures: Verify disk space and network stability

## Legal Disclaimer

This software is provided "as is" without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.

Use this software at your own risk. No warranty is implied or provided.

**By Shadd**
