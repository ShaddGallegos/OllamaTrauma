#!/bin/bash

# OllamaTrauma Cross-Platform Script
# Compatible with Linux, macOS, Windows (WSL/Git Bash/Cygwin), and Ansible
# Version: 2.0

# Global variables
SELECTED_MODEL="mistral"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/ollama_trauma.log"
CONFIG_FILE="${SCRIPT_DIR}/ollama_config.json"

# Color codes (cross-platform compatible)
if [[ -t 1 ]] && command -v tput &> /dev/null; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    PURPLE=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    WHITE=$(tput setaf 7)
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
else
    RED="" GREEN="" YELLOW="" BLUE="" PURPLE="" CYAN="" WHITE="" BOLD="" RESET=""
fi

# Logging function
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case $level in
        "ERROR") echo "${RED}[ERROR]${RESET} $message" ;;
        "WARN") echo "${YELLOW}[WARN]${RESET} $message" ;;
        "INFO") echo "${GREEN}[INFO]${RESET} $message" ;;
        "DEBUG") echo "${CYAN}[DEBUG]${RESET} $message" ;;
        *) echo "$message" ;;
    esac
}

# Function to detect operating system with enhanced Windows detection
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PACKAGE_MANAGER="brew"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        # Detect Linux package manager
        if command -v dnf &> /dev/null; then
            PACKAGE_MANAGER="dnf"
        elif command -v apt &> /dev/null; then
            PACKAGE_MANAGER="apt"
        elif command -v yum &> /dev/null; then
            PACKAGE_MANAGER="yum"
        elif command -v pacman &> /dev/null; then
            PACKAGE_MANAGER="pacman"
        elif command -v zypper &> /dev/null; then
            PACKAGE_MANAGER="zypper"
        else
            PACKAGE_MANAGER="unknown"
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
        PACKAGE_MANAGER="winget"
    elif [[ -n "$WSL_DISTRO_NAME" ]] || [[ -n "$WSLENV" ]]; then
        OS="wsl"
        PACKAGE_MANAGER="apt"
    else
        # Additional detection methods
        if command -v powershell.exe &> /dev/null || command -v cmd.exe &> /dev/null; then
            OS="windows"
            PACKAGE_MANAGER="winget"
        elif [[ -f "/proc/version" ]] && grep -q "Microsoft\|WSL" /proc/version 2>/dev/null; then
            OS="wsl"
            PACKAGE_MANAGER="apt"
        elif uname -s | grep -q "MINGW\|MSYS"; then
            OS="windows"
            PACKAGE_MANAGER="pacman"
        else
            OS="unknown"
            PACKAGE_MANAGER="unknown"
        fi
    fi
    
    log_message "INFO" "Detected OS: $OS, Package Manager: $PACKAGE_MANAGER"
}

# Cross-platform clear screen function
clear_screen() {
    if command -v clear &> /dev/null; then
        clear
    elif command -v cls &> /dev/null; then
        cls
    else
        printf '\033[2J\033[H'
    fi
}

# Cross-platform pause function
pause() {
    local message=${1:-"Press any key to continue..."}
    echo "$message"
    if command -v read &> /dev/null; then
        read -n 1 -s
    else
        read -p ""
    fi
}

# Function to check if running in Ansible
is_ansible() {
    [[ -n "$ANSIBLE_STDOUT_CALLBACK" ]] || [[ -n "$ANSIBLE_REMOTE_USER" ]] || [[ -n "$ANSIBLE_PLAYBOOK" ]]
}

# Function to install packages cross-platform
install_package() {
    local package=$1
    local package_windows=${2:-$package}
    local package_macos=${3:-$package}
    
    log_message "INFO" "Installing package: $package"
    
    case $OS in
        macos)
            if command -v brew &> /dev/null; then
                brew install "$package_macos"
            elif command -v port &> /dev/null; then
                sudo port install "$package_macos"
            else
                log_message "ERROR" "No package manager found on macOS. Please install Homebrew."
                return 1
            fi
            ;;
        linux)
            case $PACKAGE_MANAGER in
                dnf) sudo dnf install -y "$package" ;;
                apt) sudo apt update && sudo apt install -y "$package" ;;
                yum) sudo yum install -y "$package" ;;
                pacman) sudo pacman -S --noconfirm "$package" ;;
                zypper) sudo zypper install -y "$package" ;;
                *) log_message "ERROR" "Unknown package manager: $PACKAGE_MANAGER"; return 1 ;;
            esac
            ;;
        windows|wsl)
            if command -v winget &> /dev/null; then
                winget install "$package_windows"
            elif command -v choco &> /dev/null; then
                choco install -y "$package_windows"
            elif command -v scoop &> /dev/null; then
                scoop install "$package_windows"
            elif [[ "$OS" == "wsl" ]] && command -v apt &> /dev/null; then
                sudo apt update && sudo apt install -y "$package"
            else
                log_message "ERROR" "No package manager found on Windows. Please install winget, chocolatey, or scoop."
                return 1
            fi
            ;;
        *)
            log_message "ERROR" "Unknown operating system: $OS"
            return 1
            ;;
    esac
}

# Function to check and install dependencies
check_dependencies() {
    log_message "INFO" "Checking for required dependencies..."

    # Check if curl is installed (required for downloads)
    if ! command -v curl &> /dev/null; then
        log_message "WARN" "curl not found. Installing..."
        install_package "curl" "curl" "curl"
    else
        log_message "INFO" "curl is already installed."
    fi

    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        log_message "WARN" "jq not found. Installing..."
        install_package "jq" "jqlang.jq" "jq"
    else
        log_message "INFO" "jq is already installed."
    fi

    # Check if git is installed (required for cloning models)
    if ! command -v git &> /dev/null; then
        log_message "WARN" "git not found. Installing..."
        install_package "git" "Git.Git" "git"
    else
        log_message "INFO" "git is already installed."
    fi

    # Check if python3 is installed (for advanced features)
    if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
        log_message "WARN" "Python not found. Installing..."
        install_package "python3" "Python.Python.3" "python3"
    else
        log_message "INFO" "Python is already installed."
    fi

    # Install Python packages if Python is available
    if command -v python3 &> /dev/null || command -v python &> /dev/null; then
        local python_cmd
        if command -v python3 &> /dev/null; then
            python_cmd="python3"
        else
            python_cmd="python"
        fi

        # Check and install pip if needed
        if ! $python_cmd -m pip --version &> /dev/null; then
            log_message "WARN" "pip not found. Installing..."
            case $OS in
                linux|wsl)
                    install_package "python3-pip" "python3-pip" "python3-pip"
                    ;;
                macos)
                    $python_cmd -m ensurepip --upgrade
                    ;;
                windows)
                    $python_cmd -m ensurepip --upgrade
                    ;;
            esac
        fi

        # Install Python dependencies
        local python_packages=("requests" "beautifulsoup4" "sentence-transformers" "numpy" "json5")
        for pkg in "${python_packages[@]}"; do
            if ! $python_cmd -c "import $pkg" &> /dev/null; then
                log_message "INFO" "Installing Python package: $pkg"
                $python_cmd -m pip install "$pkg" --user
            fi
        done
    fi
}

# Function to get Ollama installation command based on OS
get_ollama_install_cmd() {
    case $OS in
        macos)
            echo "curl -fsSL https://ollama.ai/install.sh | sh"
            ;;
        linux|wsl)
            echo "curl -fsSL https://ollama.ai/install.sh | sh"
            ;;
        windows)
            echo "Visit https://ollama.ai/download and download the Windows installer"
            ;;
        *)
            echo "Unknown OS, visit https://ollama.ai for installation instructions"
            ;;
    esac
}

# Function to start Ollama service cross-platform
start_ollama_service() {
    log_message "INFO" "Starting Ollama service..."
    
    case $OS in
        macos)
            if command -v brew &> /dev/null && brew services list | grep -q ollama; then
                brew services start ollama
            else
                ollama serve &
                OLLAMA_PID=$!
                log_message "INFO" "Ollama started with PID: $OLLAMA_PID"
            fi
            ;;
        linux|wsl)
            if systemctl is-active --quiet ollama; then
                log_message "INFO" "Ollama service is already running"
            elif command -v systemctl &> /dev/null; then
                sudo systemctl start ollama
            else
                ollama serve &
                OLLAMA_PID=$!
                log_message "INFO" "Ollama started with PID: $OLLAMA_PID"
            fi
            ;;
        windows)
            if ! pgrep -f "ollama" &> /dev/null; then
                ollama serve &
                OLLAMA_PID=$!
                log_message "INFO" "Ollama started with PID: $OLLAMA_PID"
            fi
            ;;
    esac
    
    # Wait for Ollama to be ready
    local max_attempts=30
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:11434/api/tags &> /dev/null; then
            log_message "INFO" "Ollama service is ready"
            return 0
        fi
        sleep 1
        ((attempt++))
    done
    
    log_message "ERROR" "Ollama service failed to start within 30 seconds"
    return 1
}

# Function to install/update Ollama and run selected model
install_and_run_model() {
    clear_screen
    log_message "INFO" "Installing/updating Ollama and running model: $SELECTED_MODEL"

    # Check if Ollama is installed
    if ! command -v ollama &> /dev/null; then
        log_message "WARN" "Ollama not found. Installing..."
        
        case $OS in
            macos)
                if command -v brew &> /dev/null; then
                    log_message "INFO" "Using Homebrew to install Ollama..."
                    brew install ollama
                    brew services start ollama
                else
                    log_message "INFO" "Installing Ollama using curl..."
                    curl -fsSL https://ollama.ai/install.sh | sh
                fi
                ;;
            linux|wsl)
                log_message "INFO" "Installing Ollama using curl..."
                curl -fsSL https://ollama.ai/install.sh | sh
                ;;
            windows)
                log_message "ERROR" "Please install Ollama manually from https://ollama.ai/download"
                if ! is_ansible; then
                    pause "Press Enter after installing Ollama..."
                fi
                if ! command -v ollama &> /dev/null; then
                    log_message "ERROR" "Ollama installation failed or not in PATH"
                    return 1
                fi
                ;;
        esac
    else
        log_message "INFO" "Ollama is already installed."
    fi

    # Start Ollama service
    start_ollama_service

    # Check if model is already installed
    if ollama list | grep -q "^${SELECTED_MODEL}"; then
        log_message "INFO" "Model $SELECTED_MODEL is already installed."
    else
        log_message "INFO" "Pulling model: $SELECTED_MODEL"
        if ! ollama pull "$SELECTED_MODEL"; then
            log_message "ERROR" "Failed to pull model: $SELECTED_MODEL"
            return 1
        fi
    fi

    # Run the model interactively if not in Ansible
    if ! is_ansible; then
        log_message "INFO" "Starting interactive session with $SELECTED_MODEL"
        echo "${GREEN}Starting $SELECTED_MODEL... (type '/bye' to exit)${RESET}"
        ollama run "$SELECTED_MODEL"
    else
        log_message "INFO" "Model $SELECTED_MODEL is ready for use"
    fi
}

# Function to select model (simplified for cross-platform compatibility)
select_model() {
    clear_screen
    echo "${BOLD}${BLUE}=== Model Selection ===${RESET}"
    echo "Current model: ${GREEN}$SELECTED_MODEL${RESET}"
    echo
    echo "Popular models:"
    echo "1) mistral (7B) - Fast and efficient"
    echo "2) llama2 (7B) - Meta's base model"
    echo "3) llama2:13b (13B) - Larger variant"
    echo "4) codellama (7B) - Code-focused model"
    echo "5) phi (2.7B) - Microsoft's small model"
    echo "6) Custom model name"
    echo "7) Return to main menu"
    echo

    if ! is_ansible; then
        read -p "Enter your choice (1-7): " choice
    else
        choice=${ANSIBLE_MODEL_CHOICE:-1}
        log_message "INFO" "Ansible mode: Using model choice $choice"
    fi

    case $choice in
        1) SELECTED_MODEL="mistral" ;;
        2) SELECTED_MODEL="llama2" ;;
        3) SELECTED_MODEL="llama2:13b" ;;
        4) SELECTED_MODEL="codellama" ;;
        5) SELECTED_MODEL="phi" ;;
        6)
            if ! is_ansible; then
                read -p "Enter custom model name: " SELECTED_MODEL
            else
                SELECTED_MODEL=${ANSIBLE_CUSTOM_MODEL:-"mistral"}
                log_message "INFO" "Ansible mode: Using custom model $SELECTED_MODEL"
            fi
            ;;
        7) return ;;
        *) 
            log_message "WARN" "Invalid choice, keeping current model: $SELECTED_MODEL"
            ;;
    esac

    log_message "INFO" "Selected model: $SELECTED_MODEL"
    save_config
}

# Function to save configuration
save_config() {
    local config_json="{
        \"selected_model\": \"$SELECTED_MODEL\",
        \"os\": \"$OS\",
        \"package_manager\": \"$PACKAGE_MANAGER\",
        \"last_updated\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
    }"
    
    echo "$config_json" > "$CONFIG_FILE"
    log_message "DEBUG" "Configuration saved to $CONFIG_FILE"
}

# Function to load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]] && command -v jq &> /dev/null; then
        SELECTED_MODEL=$(jq -r '.selected_model // "mistral"' "$CONFIG_FILE")
        log_message "DEBUG" "Configuration loaded from $CONFIG_FILE"
    fi
}

# Function to list available models
list_models() {
    clear_screen
    echo "${BOLD}${BLUE}=== Available Models ===${RESET}"
    
    if command -v ollama &> /dev/null; then
        log_message "INFO" "Fetching available models..."
        ollama list
    else
        log_message "ERROR" "Ollama not installed. Please install Ollama first."
    fi
    
    if ! is_ansible; then
        pause
    fi
}

# Function to remove models
remove_model() {
    clear_screen
    echo "${BOLD}${BLUE}=== Remove Models ===${RESET}"
    
    if ! command -v ollama &> /dev/null; then
        log_message "ERROR" "Ollama not installed."
        return 1
    fi

    # List available models
    echo "Available models:"
    local models=($(ollama list | tail -n +2 | awk '{print $1}' | cut -d':' -f1 | sort -u))
    
    if [ ${#models[@]} -eq 0 ]; then
        log_message "INFO" "No models installed."
        return 0
    fi

    for i in "${!models[@]}"; do
        echo "$((i+1))) ${models[i]}"
    done
    echo "$((${#models[@]}+1))) Return to main menu"

    if ! is_ansible; then
        read -p "Select model to remove (1-$((${#models[@]}+1))): " choice
    else
        choice=${ANSIBLE_REMOVE_CHOICE:-$((${#models[@]}+1))}
        log_message "INFO" "Ansible mode: Using remove choice $choice"
    fi

    if [ "$choice" -eq "$((${#models[@]}+1))" ]; then
        return 0
    elif [ "$choice" -ge 1 ] && [ "$choice" -le "${#models[@]}" ]; then
        local model_to_remove="${models[$((choice-1))]}"
        log_message "INFO" "Removing model: $model_to_remove"
        
        if ollama rm "$model_to_remove"; then
            log_message "INFO" "Model $model_to_remove removed successfully."
            
            # Reset selected model if it was removed
            if [ "$model_to_remove" == "$SELECTED_MODEL" ]; then
                SELECTED_MODEL="mistral"
                log_message "INFO" "Reset selected model to: $SELECTED_MODEL"
                save_config
            fi
        else
            log_message "ERROR" "Failed to remove model: $model_to_remove"
        fi
    else
        log_message "WARN" "Invalid choice."
    fi

    if ! is_ansible; then
        pause
    fi
}

# Python integration function
run_python_script() {
    local script_name="$1"
    local script_content="$2"
    
    # Determine Python command
    local python_cmd
    if command -v python3 &> /dev/null; then
        python_cmd="python3"
    elif command -v python &> /dev/null; then
        python_cmd="python"
    else
        log_message "ERROR" "Python not found. Please install Python."
        return 1
    fi

    # Create temporary script file
    local temp_script="${SCRIPT_DIR}/${script_name}"
    echo "$script_content" > "$temp_script"
    
    log_message "INFO" "Running Python script: $script_name"
    $python_cmd "$temp_script"
    local exit_code=$?
    
    # Clean up temporary file
    rm -f "$temp_script"
    
    return $exit_code
}

# Advanced operations menu
advanced_operations() {
    while true; do
        clear_screen
        echo "${BOLD}${PURPLE}=== Advanced Operations ===${RESET}"
        echo "1) List all models"
        echo "2) Remove models"
        echo "3) Model information"
        echo "4) System information"
        echo "5) Python integration test"
        echo "6) Return to main menu"
        echo

        if ! is_ansible; then
            read -p "Enter your choice (1-6): " choice
        else
            choice=${ANSIBLE_ADVANCED_CHOICE:-6}
            log_message "INFO" "Ansible mode: Using advanced choice $choice"
        fi

        case $choice in
            1) list_models ;;
            2) remove_model ;;
            3) 
                if command -v ollama &> /dev/null; then
                    echo "${GREEN}Ollama version:${RESET}"
                    ollama --version
                    echo "${GREEN}Current model info:${RESET}"
                    ollama show "$SELECTED_MODEL" 2>/dev/null || echo "Model not found: $SELECTED_MODEL"
                    if ! is_ansible; then pause; fi
                else
                    log_message "ERROR" "Ollama not installed."
                fi
                ;;
            4)
                echo "${GREEN}System Information:${RESET}"
                echo "OS: $OS"
                echo "Package Manager: $PACKAGE_MANAGER"
                echo "Script Directory: $SCRIPT_DIR"
                echo "Log File: $LOG_FILE"
                echo "Config File: $CONFIG_FILE"
                echo "Current Model: $SELECTED_MODEL"
                if ! is_ansible; then pause; fi
                ;;
            5)
                local python_test='
import sys
import platform
import os

print("Python Integration Test")
print("=" * 30)
print(f"Python Version: {sys.version}")
print(f"Platform: {platform.system()} {platform.release()}")
print(f"Architecture: {platform.architecture()[0]}")
print(f"Current Directory: {os.getcwd()}")

try:
    import requests
    print("✓ requests module available")
except ImportError:
    print("✗ requests module not available")

try:
    import json
    print("✓ json module available")
except ImportError:
    print("✗ json module not available")

print("Test completed successfully!")
'
                run_python_script "test_python.py" "$python_test"
                if ! is_ansible; then pause; fi
                ;;
            6) break ;;
            *) 
                log_message "WARN" "Invalid option."
                if ! is_ansible; then sleep 1; fi
                ;;
        esac
    done
}

# Main menu function
main_menu() {
    while true; do
        clear_screen
        echo "${BOLD}${CYAN}====================================${RESET}"
        echo "${BOLD}${CYAN}    OllamaTrauma Cross-Platform     ${RESET}"
        echo "${BOLD}${CYAN}====================================${RESET}"
        echo
        echo "Current OS: ${GREEN}$OS${RESET}"
        echo "Current Model: ${GREEN}$SELECTED_MODEL${RESET}"
        if is_ansible; then
            echo "Mode: ${YELLOW}Ansible Automation${RESET}"
        else
            echo "Mode: ${BLUE}Interactive${RESET}"
        fi
        echo
        echo "1) Install/Run Ollama Model"
        echo "2) Select Different Model"
        echo "3) Advanced Operations"
        echo "4) View Logs"
        echo "5) Exit"
        echo "====================================="

        if ! is_ansible; then
            read -p "Enter your choice (1-5): " choice
        else
            choice=${ANSIBLE_MAIN_CHOICE:-1}
            log_message "INFO" "Ansible mode: Using main choice $choice"
        fi

        case $choice in
            1) install_and_run_model ;;
            2) select_model ;;
            3) advanced_operations ;;
            4) 
                if [[ -f "$LOG_FILE" ]]; then
                    echo "${GREEN}Recent log entries:${RESET}"
                    tail -20 "$LOG_FILE"
                else
                    echo "No log file found."
                fi
                if ! is_ansible; then pause; fi
                ;;
            5) 
                log_message "INFO" "Exiting OllamaTrauma Cross-Platform"
                echo "${GREEN}Thank you for using OllamaTrauma!${RESET}"
                exit 0 
                ;;
            *) 
                log_message "WARN" "Invalid option: $choice"
                if ! is_ansible; then sleep 1; fi
                ;;
        esac

        # In Ansible mode, exit after one operation
        if is_ansible; then
            log_message "INFO" "Ansible operation completed"
            break
        fi
    done
}

# Cleanup function
cleanup() {
    log_message "INFO" "Performing cleanup..."
    
    # Kill background Ollama process if we started it
    if [[ -n "$OLLAMA_PID" ]]; then
        if kill -0 "$OLLAMA_PID" 2>/dev/null; then
            log_message "INFO" "Stopping Ollama service (PID: $OLLAMA_PID)"
            kill "$OLLAMA_PID"
        fi
    fi
}

# Signal handlers
trap cleanup EXIT INT TERM

# Main execution
main() {
    # Initialize
    log_message "INFO" "Starting OllamaTrauma Cross-Platform v2.0"
    
    # Detect OS and load config
    detect_os
    load_config
    
    # Check dependencies (skip in Ansible if ANSIBLE_SKIP_DEPS is set)
    if ! is_ansible || [[ -z "$ANSIBLE_SKIP_DEPS" ]]; then
        check_dependencies
    fi
    
    # Save initial config
    save_config
    
    # Start main menu
    main_menu
}

# Run main function
main "$@"
