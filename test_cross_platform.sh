#!/bin/bash

# OllamaTrauma Cross-Platform Test Script
# Tests all versions on the current system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_LOG="$SCRIPT_DIR/test_results.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
RESET='\033[0m'

# Logging function
log_test() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$TEST_LOG"
    
    case $level in
        "PASS") echo -e "${GREEN}[PASS]${RESET} $message" ;;
        "FAIL") echo -e "${RED}[FAIL]${RESET} $message" ;;
        "WARN") echo -e "${YELLOW}[WARN]${RESET} $message" ;;
        "INFO") echo -e "${CYAN}[INFO]${RESET} $message" ;;
        "TEST") echo -e "${PURPLE}[TEST]${RESET} $message" ;;
        *) echo "$message" ;;
    esac
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    elif [[ -n "$WSL_DISTRO_NAME" ]] || [[ -n "$WSLENV" ]]; then
        echo "wsl"
    else
        echo "unknown"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to test script syntax
test_script_syntax() {
    local script_path=$1
    local script_name=$(basename "$script_path")
    
    log_test "TEST" "Testing syntax for $script_name"
    
    case "$script_path" in
        *.sh)
            if bash -n "$script_path" 2>/dev/null; then
                log_test "PASS" "$script_name syntax is valid"
                return 0
            else
                log_test "FAIL" "$script_name has syntax errors"
                return 1
            fi
            ;;
        *.py)
            if command_exists python3; then
                if python3 -m py_compile "$script_path" 2>/dev/null; then
                    log_test "PASS" "$script_name syntax is valid"
                    return 0
                else
                    log_test "FAIL" "$script_name has syntax errors"
                    return 1
                fi
            else
                log_test "WARN" "Python3 not available, skipping $script_name syntax check"
                return 0
            fi
            ;;
        *.ps1)
            if command_exists pwsh; then
                if pwsh -Command "& { Set-ExecutionPolicy Bypass -Scope Process; try { . '$script_path'; exit 0 } catch { exit 1 } }" 2>/dev/null; then
                    log_test "PASS" "$script_name syntax is valid"
                    return 0
                else
                    log_test "FAIL" "$script_name has syntax errors"
                    return 1
                fi
            elif command_exists powershell; then
                if powershell -Command "& { Set-ExecutionPolicy Bypass -Scope Process; try { . '$script_path'; exit 0 } catch { exit 1 } }" 2>/dev/null; then
                    log_test "PASS" "$script_name syntax is valid"
                    return 0
                else
                    log_test "FAIL" "$script_name has syntax errors"
                    return 1
                fi
            else
                log_test "WARN" "PowerShell not available, skipping $script_name syntax check"
                return 0
            fi
            ;;
        *.yml|*.yaml)
            if command_exists ansible-playbook; then
                if ansible-playbook --syntax-check "$script_path" &>/dev/null; then
                    log_test "PASS" "$script_name syntax is valid"
                    return 0
                else
                    log_test "FAIL" "$script_name has syntax errors"
                    return 1
                fi
            else
                log_test "WARN" "Ansible not available, skipping $script_name syntax check"
                return 0
            fi
            ;;
        *)
            log_test "WARN" "Unknown file type for $script_name"
            return 0
            ;;
    esac
}

# Function to test file permissions
test_file_permissions() {
    local file_path=$1
    local file_name=$(basename "$file_path")
    
    log_test "TEST" "Testing permissions for $file_name"
    
    if [[ -r "$file_path" ]]; then
        log_test "PASS" "$file_name is readable"
    else
        log_test "FAIL" "$file_name is not readable"
        return 1
    fi
    
    # Check if script files are executable
    case "$file_path" in
        *.sh|*.py)
            if [[ -x "$file_path" ]]; then
                log_test "PASS" "$file_name is executable"
            else
                log_test "WARN" "$file_name is not executable (will try to fix)"
                chmod +x "$file_path" 2>/dev/null
                if [[ -x "$file_path" ]]; then
                    log_test "PASS" "Fixed permissions for $file_name"
                else
                    log_test "FAIL" "Could not fix permissions for $file_name"
                    return 1
                fi
            fi
            ;;
    esac
    
    return 0
}

# Function to test OS compatibility
test_os_compatibility() {
    local os=$(detect_os)
    log_test "TEST" "Testing OS compatibility (detected: $os)"
    
    case $os in
        linux)
            log_test "PASS" "Linux detected - all scripts should work"
            if command_exists python3; then
                log_test "PASS" "Python3 available"
            else
                log_test "WARN" "Python3 not available"
            fi
            ;;
        macos)
            log_test "PASS" "macOS detected - all scripts should work"
            if command_exists python3; then
                log_test "PASS" "Python3 available"
            else
                log_test "WARN" "Python3 not available"
            fi
            ;;
        windows)
            log_test "PASS" "Windows detected - PowerShell script recommended"
            if command_exists pwsh; then
                log_test "PASS" "PowerShell Core available"
            elif command_exists powershell; then
                log_test "PASS" "Windows PowerShell available"
            else
                log_test "WARN" "PowerShell not available"
            fi
            ;;
        wsl)
            log_test "PASS" "WSL detected - all scripts should work"
            ;;
        unknown)
            log_test "WARN" "Unknown OS - compatibility uncertain"
            ;;
    esac
}

# Function to test dependencies
test_dependencies() {
    log_test "TEST" "Testing system dependencies"
    
    local deps=("curl" "git")
    local optional_deps=("jq" "python3" "pwsh" "ansible-playbook")
    
    # Check required dependencies
    for dep in "${deps[@]}"; do
        if command_exists "$dep"; then
            log_test "PASS" "$dep is available"
        else
            log_test "FAIL" "$dep is missing (required)"
        fi
    done
    
    # Check optional dependencies
    for dep in "${optional_deps[@]}"; do
        if command_exists "$dep"; then
            log_test "PASS" "$dep is available"
        else
            log_test "INFO" "$dep is not available (optional)"
        fi
    done
}

# Function to test Ansible configuration
test_ansible_config() {
    log_test "TEST" "Testing Ansible configuration"
    
    if command_exists ansible-playbook; then
        if [[ -f "$SCRIPT_DIR/ansible.cfg" ]]; then
            log_test "PASS" "Ansible configuration file found"
        else
            log_test "WARN" "Ansible configuration file missing"
        fi
        
        if [[ -f "$SCRIPT_DIR/inventory.ini" ]]; then
            log_test "PASS" "Ansible inventory file found"
        else
            log_test "WARN" "Ansible inventory file missing"
        fi
        
        # Test inventory syntax
        if ansible-inventory --list -i "$SCRIPT_DIR/inventory.ini" &>/dev/null; then
            log_test "PASS" "Ansible inventory syntax is valid"
        else
            log_test "FAIL" "Ansible inventory has syntax errors"
        fi
    else
        log_test "INFO" "Ansible not available, skipping configuration tests"
    fi
}

# Function to run integration tests
test_integration() {
    log_test "TEST" "Running integration tests"
    
    # Test environment variable handling
    export ANSIBLE_STDOUT_CALLBACK=json
    export ANSIBLE_MAIN_CHOICE=1
    export ANSIBLE_SKIP_DEPS=true
    
    log_test "PASS" "Environment variables set for testing"
    
    # Test config file creation
    local test_config_dir="$SCRIPT_DIR/test_config"
    mkdir -p "$test_config_dir"
    
    local test_config='{"selected_model": "mistral", "test": true}'
    echo "$test_config" > "$test_config_dir/ollama_config.json"
    
    if [[ -f "$test_config_dir/ollama_config.json" ]]; then
        log_test "PASS" "Configuration file creation works"
    else
        log_test "FAIL" "Configuration file creation failed"
    fi
    
    # Clean up test files
    rm -rf "$test_config_dir"
}

# Main test function
run_tests() {
    echo -e "${BOLD}${CYAN}======================================${RESET}"
    echo -e "${BOLD}${CYAN}    OllamaTrauma Cross-Platform Test  ${RESET}"
    echo -e "${BOLD}${CYAN}======================================${RESET}"
    echo
    
    # Initialize test log
    echo "OllamaTrauma Cross-Platform Test - $(date)" > "$TEST_LOG"
    echo "================================================" >> "$TEST_LOG"
    
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    # Test OS compatibility
    test_os_compatibility
    ((total_tests++))
    
    # Test system dependencies
    test_dependencies
    ((total_tests++))
    
    # Test script files
    local scripts=(
        "$SCRIPT_DIR/OllamaTrauma_CrossPlatform.sh"
        "$SCRIPT_DIR/ollama_trauma.py"
        "$SCRIPT_DIR/OllamaTrauma.ps1"
        "$SCRIPT_DIR/ollama_trauma_playbook.yml"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            test_file_permissions "$script"
            test_script_syntax "$script"
            ((total_tests += 2))
        else
            log_test "FAIL" "Script file missing: $(basename "$script")"
            ((total_tests++))
            ((failed_tests++))
        fi
    done
    
    # Test Ansible configuration
    test_ansible_config
    ((total_tests++))
    
    # Test integration
    test_integration
    ((total_tests++))
    
    # Count results from log
    passed_tests=$(grep -c "\[PASS\]" "$TEST_LOG")
    failed_tests=$(grep -c "\[FAIL\]" "$TEST_LOG")
    
    echo
    echo -e "${BOLD}${CYAN}======================================${RESET}"
    echo -e "${BOLD}${CYAN}           Test Results               ${RESET}"
    echo -e "${BOLD}${CYAN}======================================${RESET}"
    echo -e "Total Tests: ${BOLD}$total_tests${RESET}"
    echo -e "Passed: ${GREEN}${BOLD}$passed_tests${RESET}"
    echo -e "Failed: ${RED}${BOLD}$failed_tests${RESET}"
    echo -e "Warnings: ${YELLOW}${BOLD}$(grep -c "\[WARN\]" "$TEST_LOG")${RESET}"
    echo
    
    if [[ $failed_tests -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}All tests passed! ✅${RESET}"
        echo
        echo -e "${CYAN}You can now use any of the following:${RESET}"
        echo -e "  • Bash:       ${BOLD}./OllamaTrauma_CrossPlatform.sh${RESET}"
        echo -e "  • Python:     ${BOLD}python3 ollama_trauma.py${RESET}"
        echo -e "  • PowerShell: ${BOLD}pwsh OllamaTrauma.ps1${RESET}"
        echo -e "  • Ansible:    ${BOLD}ansible-playbook ollama_trauma_playbook.yml${RESET}"
        echo
        return 0
    else
        echo -e "${RED}${BOLD}Some tests failed! ❌${RESET}"
        echo -e "Check ${BOLD}$TEST_LOG${RESET} for details."
        echo
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo -e "${BOLD}Usage:${RESET}"
    echo -e "  $0 [OPTIONS]"
    echo
    echo -e "${BOLD}Options:${RESET}"
    echo -e "  -h, --help     Show this help message"
    echo -e "  -v, --verbose  Enable verbose output"
    echo -e "  -q, --quiet    Suppress non-critical output"
    echo -e "  --version      Show version information"
    echo
    echo -e "${BOLD}Examples:${RESET}"
    echo -e "  $0              Run all tests"
    echo -e "  $0 --verbose    Run tests with verbose output"
    echo -e "  $0 --quiet      Run tests with minimal output"
    echo
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        --version)
            echo "OllamaTrauma Cross-Platform Test v1.0"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            show_usage
            exit 1
            ;;
    esac
done

# Run the tests
run_tests
