#!/usr/bin/env bash
#
# OllamaTrauma Universal Installer
# Detects OS, copies appropriate script, and runs initial setup
#

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INSTALL_DIR="${SCRIPT_DIR}"

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step() { echo -e "${BLUE}[STEP]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }

# Show banner
show_banner() {
  clear
  cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║                    OllamaTrauma Installer                        ║
║                         Version 2.1.0                            ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
  echo
}

# Detect operating system
detect_os() {
  local os=""
  local os_type=""
  
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    os_type="linux"
    
    # Detect specific Linux distribution
    if [[ -f /etc/os-release ]]; then
      source /etc/os-release
      case "$ID" in
        rhel|centos|rocky|almalinux)
          os="rhel"
          ;;
        fedora)
          os="fedora"
          ;;
        debian|ubuntu|mint|pop)
          os="debian"
          ;;
        arch|manjaro)
          os="arch"
          ;;
        *)
          log_warn "Unknown Linux distribution: $ID"
          os="linux"
          ;;
      esac
    else
      os="linux"
    fi
    
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    os="macos"
    os_type="macos"
    
  elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    os="windows"
    os_type="windows"
    
  elif [[ "$OSTYPE" == "freebsd"* ]]; then
    os="freebsd"
    os_type="freebsd"
    
  else
    log_error "Unsupported operating system: $OSTYPE"
    return 1
  fi
  
  echo "$os"
}

# Check if OS-specific script exists
check_os_script() {
  local os="$1"
  local script_path=""
  
  # Check for OS-specific script
  if [[ -f "${SCRIPT_DIR}/scripts/${os}/OllamaTrauma_v2.sh" ]]; then
    script_path="${SCRIPT_DIR}/scripts/${os}/OllamaTrauma_v2.sh"
  elif [[ -f "${SCRIPT_DIR}/scripts/${os}/OllamaTrauma_v2.ps1" ]]; then
    script_path="${SCRIPT_DIR}/scripts/${os}/OllamaTrauma_v2.ps1"
  # Fallback to generic Linux script if specific distro not found
  elif [[ "$os" == "debian" ]] || [[ "$os" == "arch" ]] || [[ "$os" == "linux" ]]; then
    if [[ -f "${SCRIPT_DIR}/scripts/linux/OllamaTrauma_v2.sh" ]]; then
      script_path="${SCRIPT_DIR}/scripts/linux/OllamaTrauma_v2.sh"
    fi
  fi
  
  # Final fallback to current script if no OS-specific version
  if [[ -z "$script_path" ]] && [[ -f "${SCRIPT_DIR}/OllamaTrauma_v2.sh" ]]; then
    log_warn "No OS-specific script found, using universal version"
    script_path="${SCRIPT_DIR}/OllamaTrauma_v2.sh"
  fi
  
  echo "$script_path"
}

# Copy and setup OS-specific script
setup_os_script() {
  local os="$1"
  local source_script="$2"
  local target_script="${SCRIPT_DIR}/OllamaTrauma_v2.sh"
  
  log_step "Setting up OllamaTrauma for: $os"
  echo
  
  # If source and target are the same, no need to copy
  if [[ "$source_script" == "$target_script" ]]; then
    log_info "Using existing universal script"
    return 0
  fi
  
  # Backup existing script if it exists
  if [[ -f "$target_script" ]]; then
    local backup_file="${target_script}.backup.$(date +%Y%m%d-%H%M%S)"
    log_info "Backing up existing script to: $(basename $backup_file)"
    cp "$target_script" "$backup_file"
  fi
  
  # Copy OS-specific script to main location
  log_info "Copying OS-specific script..."
  cp "$source_script" "$target_script"
  chmod +x "$target_script"
  
  log_success "Script setup complete"
}

# Run initial setup
run_initial_setup() {
  local script="${SCRIPT_DIR}/OllamaTrauma_v2.sh"
  
  log_step "Running initial project setup..."
  echo
  
  if [[ ! -f "$script" ]]; then
    log_error "Main script not found: $script"
    return 1
  fi
  
  # Run the script's initialization
  log_info "Launching OllamaTrauma..."
  echo
  sleep 1
  
  # Execute the script
  exec "$script"
}

# Main installation process
main() {
  show_banner
  
  log_step "Starting OllamaTrauma installation..."
  echo
  
  # Detect operating system
  log_info "Detecting operating system..."
  local detected_os
  detected_os=$(detect_os)
  
  if [[ -z "$detected_os" ]]; then
    log_error "Could not detect operating system"
    exit 1
  fi
  
  log_success "Detected OS: $detected_os"
  echo
  
  # Check for OS-specific script
  log_info "Looking for OS-specific script..."
  local os_script
  os_script=$(check_os_script "$detected_os")
  
  if [[ -z "$os_script" ]]; then
    log_error "No compatible script found for: $detected_os"
    log_info "Please check scripts/ directory for available OS versions"
    exit 1
  fi
  
  log_success "Found script: $(basename $(dirname $os_script))/$(basename $os_script)"
  echo
  
  # Setup the OS-specific script
  setup_os_script "$detected_os" "$os_script"
  echo
  
  # Run initial setup
  log_success "Installation preparation complete!"
  echo
  log_info "Starting OllamaTrauma..."
  echo
  sleep 1
  
  run_initial_setup
}

# Handle script interruption
trap 'log_error "Installation interrupted"; exit 130' INT TERM

# Run main installation
main "$@"
