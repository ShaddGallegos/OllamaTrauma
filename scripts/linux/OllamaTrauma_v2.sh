#!/usr/bin/env bash
#
# OllamaTrauma v2 - Unified Bootstrap + AI Runner Manager
# Combines project initialization, dependency management, and AI runner operations
# Supports: Ollama, LocalAI, llama.cpp, text-generation-webui
# Container Runtime: Podman (preferred) or Docker
#

# Ensure we're running with bash, not sh
if [ -z "$BASH_VERSION" ]; then
  echo "ERROR: This script requires bash, not sh"
  echo "Please run with: bash $0"
  exit 1
fi

set -uo pipefail
IFS=$'\n\t'

# ============================================================================
# CONFIGURATION
# ============================================================================
readonly SCRIPT_VERSION="2.1.0"
readonly PROJECT_NAME="OllamaTrauma"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="${SCRIPT_DIR}"

# Paths
readonly LLAMACPP_DIR="${PROJECT_ROOT}/llama.cpp"
readonly LOCALAI_CONTAINER="localai"
readonly TEXTGEN_DIR="${PROJECT_ROOT}/text-generation-webui"
readonly BACKUP_DIR="${PROJECT_ROOT}/.backups"
readonly LOG_DIR="${PROJECT_ROOT}/data/logs"
readonly LOG_FILE="${LOG_DIR}/ollamatrauma_$(date +%Y%m%d_%H%M%S).log"
readonly ERROR_LOG="${LOG_DIR}/ollamatrauma_errors_$(date +%Y%m%d_%H%M%S).log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m'

# OS Detection
OS=""
OS_VERSION=""
PACKAGE_MANAGER=""

# Container runtime - Podman is preferred (rootless capable), Docker as fallback
CONTAINER_CMD=""

# Lock file - use /tmp for better compatibility
readonly LOCK_FILE="/tmp/ollamatrauma_${USER}.lock"
readonly SCRIPT_PID=$$

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log_info() { 
  echo -e "${GREEN}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

log_warn() { 
  echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE" "$ERROR_LOG" >&2
}

log_error() { 
  echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE" "$ERROR_LOG" >&2
}

log_step() { 
  echo -e "${BLUE}[STEP]${NC} $*" | tee -a "$LOG_FILE"
}

log_success() {
  echo -e "${GREEN}[OK]${NC} $*" | tee -a "$LOG_FILE"
}

log_debug() {
  if [[ "${DEBUG:-0}" == "1" ]]; then
    echo -e "${CYAN}[DEBUG]${NC} $*" | tee -a "$LOG_FILE"
  fi
}

# ============================================================================
# DEBUG MODE FUNCTIONS
# ============================================================================

readonly DEBUG_LOG="${LOG_DIR}/debug_$(date +%Y%m%d_%H%M%S).log"
readonly DEBUG_REPORT="${LOG_DIR}/debug_report_$(date +%Y%m%d_%H%M%S).txt"

debug_test_function() {
  local func_name="$1"
  local description="$2"
  
  echo "===========================================================" | tee -a "$DEBUG_LOG"
  echo "Testing: $func_name - $description" | tee -a "$DEBUG_LOG"
  echo "Time: $(date)" | tee -a "$DEBUG_LOG"
  echo "───────────────────────────────────────────────────────────" | tee -a "$DEBUG_LOG"
  
  if type "$func_name" &>/dev/null; then
    echo "[PASS] Function exists: $func_name" | tee -a "$DEBUG_LOG"
    
    # Try to get function definition
    if declare -f "$func_name" &>/dev/null; then
      echo "[PASS] Function is properly defined" | tee -a "$DEBUG_LOG"
    else
      echo "[FAIL] Function exists but is not properly defined" | tee -a "$DEBUG_LOG" "$DEBUG_REPORT"
      return 1
    fi
  else
    echo "[FAIL] Function missing: $func_name" | tee -a "$DEBUG_LOG" "$DEBUG_REPORT"
    return 1
  fi
  
  echo "" | tee -a "$DEBUG_LOG"
  return 0
}

debug_mode() {
  clear_screen
  echo "==========================================================="
  echo "  DEBUG MODE - Testing All Functions"
  echo "==========================================================="
  echo
  echo "Debug Log: $DEBUG_LOG"
  echo "Report: $DEBUG_REPORT"
  echo "==========================================================="
  echo
  
  mkdir -p "$LOG_DIR"
  : > "$DEBUG_LOG"
  : > "$DEBUG_REPORT"
  
  local total_tests=0
  local passed_tests=0
  local failed_tests=0
  
  # Test utility functions
  echo "Testing Utility Functions..." | tee -a "$DEBUG_LOG"
  echo "─────────────────────────────────────────────────────────" | tee -a "$DEBUG_LOG"
  
  local util_funcs=(
    "clear_screen:Clear screen utility"
    "pause:Pause for user input"
    "show_banner:Display banner"
    "open_browser:Open browser utility"
    "run_menu_action:Menu action wrapper"
    "detect_os:OS detection"
    "detect_container_runtime:Container runtime detection"
  )
  
  for func_info in "${util_funcs[@]}"; do
    IFS=':' read -r func desc <<< "$func_info"
    ((total_tests++))
    if debug_test_function "$func" "$desc"; then
      ((passed_tests++))
    else
      ((failed_tests++))
    fi
  done
  
  # Test setup functions
  echo "Testing Setup Functions..." | tee -a "$DEBUG_LOG"
  echo "─────────────────────────────────────────────────────────" | tee -a "$DEBUG_LOG"
  
  local setup_funcs=(
    "initialize_project:Project initialization"
    "check_dependencies:Dependency checker"
    "install_system_dependencies:System package installer"
    "install_python_packages:Python package installer"
    "setup_container_runtime:Container runtime setup"
    "setup_rootless_podman:Rootless Podman setup"
  )
  
  for func_info in "${setup_funcs[@]}"; do
    IFS=':' read -r func desc <<< "$func_info"
    ((total_tests++))
    if debug_test_function "$func" "$desc"; then
      ((passed_tests++))
    else
      ((failed_tests++))
    fi
  done
  
  # Test AI runner functions
  echo "Testing AI Runner Functions..." | tee -a "$DEBUG_LOG"
  echo "─────────────────────────────────────────────────────────" | tee -a "$DEBUG_LOG"
  
  local runner_funcs=(
    "install_ollama:Ollama installer"
    "uninstall_ollama:Ollama uninstaller"
    "install_localai:LocalAI installer"
    "uninstall_localai:LocalAI uninstaller"
    "install_llamacpp:llama.cpp installer"
    "uninstall_llamacpp:llama.cpp uninstaller"
    "install_textgen_webui:text-generation-webui installer"
    "uninstall_textgen_webui:text-generation-webui uninstaller"
    "start_runner:Start AI runner"
    "stop_runner:Stop AI runner"
    "check_installed_runners:Check installed runners"
  )
  
  for func_info in "${runner_funcs[@]}"; do
    IFS=':' read -r func desc <<< "$func_info"
    ((total_tests++))
    if debug_test_function "$func" "$desc"; then
      ((passed_tests++))
    else
      ((failed_tests++))
    fi
  done
  
  # Test menu functions
  echo "Testing Menu Functions..." | tee -a "$DEBUG_LOG"
  echo "─────────────────────────────────────────────────────────" | tee -a "$DEBUG_LOG"
  
  local menu_funcs=(
    "main_menu:Main menu"
    "setup_menu:Setup menu"
    "ai_runners_menu:AI runners menu"
    "models_menu:Models menu"
    "maintenance_menu:Maintenance menu"
    "uninstall_submenu:Uninstall submenu"
  )
  
  for func_info in "${menu_funcs[@]}"; do
    IFS=':' read -r func desc <<< "$func_info"
    ((total_tests++))
    if debug_test_function "$func" "$desc"; then
      ((passed_tests++))
    else
      ((failed_tests++))
    fi
  done
  
  # Generate summary
  echo "===========================================================" | tee -a "$DEBUG_LOG" "$DEBUG_REPORT"
  echo "DEBUG SUMMARY" | tee -a "$DEBUG_LOG" "$DEBUG_REPORT"
  echo "===========================================================" | tee -a "$DEBUG_LOG" "$DEBUG_REPORT"
  echo "Total Tests: $total_tests" | tee -a "$DEBUG_LOG" "$DEBUG_REPORT"
  echo "Passed: $passed_tests" | tee -a "$DEBUG_LOG" "$DEBUG_REPORT"
  echo "Failed: $failed_tests" | tee -a "$DEBUG_LOG" "$DEBUG_REPORT"
  echo "===========================================================" | tee -a "$DEBUG_LOG" "$DEBUG_REPORT"
  echo
  
  if [[ $failed_tests -gt 0 ]]; then
    echo "Failures detected. See report: $DEBUG_REPORT"
    echo
    echo "Attempting to fix common errors..."
    debug_auto_fix
  else
    echo "All tests passed!"
  fi
  
  echo
  read -p "Press Enter to continue..." -r
}

debug_auto_fix() {
  echo
  echo "==========================================================="
  echo "AUTO-FIX MODE"
  echo "==========================================================="
  echo
  
  local fixes_applied=0
  
  # Parse debug report for missing functions
  if grep -q "Function missing" "$DEBUG_REPORT"; then
    echo "Found missing functions. Analyzing..." | tee -a "$DEBUG_LOG"
    
    # Extract missing function names
    local missing_funcs
    missing_funcs=$(grep "Function missing" "$DEBUG_REPORT" | awk '{print $4}')
    
    for func in $missing_funcs; do
      case "$func" in
        setup_rootless_podman)
          echo "  [FIX] Creating stub for setup_rootless_podman" | tee -a "$DEBUG_LOG"
          echo "Missing setup_rootless_podman function - needs to be defined" >> "$DEBUG_REPORT"
          ((fixes_applied++))
          ;;
        run_menu_action)
          echo "  [FIX] Creating run_menu_action helper" | tee -a "$DEBUG_LOG"
          echo "Missing run_menu_action - add helper function" >> "$DEBUG_REPORT"
          ((fixes_applied++))
          ;;
        *)
          echo "  [INFO] Unknown missing function: $func" | tee -a "$DEBUG_LOG"
          ;;
      esac
    done
  fi
  
  # Check for common issues
  echo
  echo "Checking for common issues..." | tee -a "$DEBUG_LOG"
  
  # Check if set -e is present
  if grep -q "^set -euo pipefail" "$0"; then
    echo "  [ISSUE] Found 'set -e' which may cause premature exits" | tee -a "$DEBUG_LOG" "$DEBUG_REPORT"
    echo "  [FIX] Should be: set -uo pipefail" | tee -a "$DEBUG_REPORT"
    ((fixes_applied++))
  fi
  
  # Check for duplicate functions
  local duplicate_count
  duplicate_count=$(grep -c "^run_menu_action()" "$0" 2>/dev/null || echo 0)
  if [[ $duplicate_count -gt 1 ]]; then
    echo "  [ISSUE] Found $duplicate_count duplicate run_menu_action definitions" | tee -a "$DEBUG_LOG" "$DEBUG_REPORT"
    echo "  [FIX] Keep only one definition" | tee -a "$DEBUG_REPORT"
    ((fixes_applied++))
  fi
  
  # Check for exit statements in menu functions
  if grep -A 50 "^setup_menu()" "$0" | grep -q "exit 1"; then
    echo "  [ISSUE] Found 'exit' statements in menu functions" | tee -a "$DEBUG_LOG" "$DEBUG_REPORT"
    echo "  [FIX] Replace 'exit' with 'return' in menu functions" | tee -a "$DEBUG_REPORT"
    ((fixes_applied++))
  fi
  
  echo
  echo "==========================================================="
  echo "Auto-fix summary: $fixes_applied potential fixes identified"
  echo "See detailed report: $DEBUG_REPORT"
  echo "==========================================================="
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

clear_screen() {
  clear 2>/dev/null || printf '\033[2J\033[H'
}

pause() {
  echo
  read -p "Press Enter to continue..." -r
}

show_banner() {
  clear_screen
  cat << "EOF"
=================================================================
   ___  _ _                 _____                          
  / _ \| | | __ _ _ __ ___ |_   _| __ __ _ _   _ _ __ ___   __ _
 | | | | | |/ _` | '_ ` _ \  | || '__/ _` | | | | '_ ` _ \ / _` |
 | |_| | | | (_| | | | | | | | || | | (_| | |_| | | | | | | (_| |
  \___/|_|_|\__,_|_| |_| |_| |_||_|  \__,_|\__,_|_| |_| |_|\__,_|
                                                           
           Cross-Platform AI Runner Manager & Bootstrap
=================================================================
EOF
  echo "  Version: ${SCRIPT_VERSION}"
  echo "  Project: ${PROJECT_ROOT}"
  if [[ -n "$CONTAINER_CMD" ]]; then
    echo "  Container: ${CONTAINER_CMD}"
  fi
  echo "==========================================================="
  echo
}

open_browser() {
  local url="$1"
  
  if command -v xdg-open &>/dev/null; then
    xdg-open "$url" &>/dev/null &
  elif command -v open &>/dev/null; then
    open "$url" &>/dev/null &
  elif command -v firefox &>/dev/null; then
    firefox "$url" &>/dev/null &
  elif command -v google-chrome &>/dev/null; then
    google-chrome "$url" &>/dev/null &
  else
    log_warn "Could not auto-open browser. Please open manually: $url"
    return 1
  fi
  
  log_info "Opening browser..."
  return 0
}

# ============================================================================
# CONTAINER RUNTIME DETECTION
# Podman is preferred for rootless operation
# ============================================================================

detect_container_runtime() {
  # Check for Podman first (preferred - supports rootless mode natively)
  if command -v podman &>/dev/null; then
    CONTAINER_CMD="podman"
    log_info "Using Podman as container runtime (rootless capable)"
    
    # Check and enable Podman socket for rootless mode
    if [[ $EUID -ne 0 ]]; then
      log_debug "Checking Podman socket for rootless operation..."
      
      # Check if socket exists and is active
      if ! systemctl --user is-active --quiet podman.socket 2>/dev/null; then
        log_warn "Podman socket not active. Enabling..."
        
        # Enable user lingering first
        if ! loginctl show-user "$USER" 2>/dev/null | grep -q "Linger=yes"; then
          log_info "Enabling user lingering..."
          loginctl enable-linger "$USER" 2>/dev/null || {
            log_warn "Could not enable lingering (may need sudo)"
          }
        fi
        
        # Enable and start podman socket
        if systemctl --user enable --now podman.socket 2>/dev/null; then
          log_success "Podman socket enabled"
          sleep 2  # Give socket time to start
        else
          log_warn "Could not enable Podman socket automatically"
          log_info "Run manually: systemctl --user enable --now podman.socket"
        fi
      else
        log_debug "Podman socket is active"
      fi
    fi
    
  # Fall back to Docker if Podman not available
  elif command -v docker &>/dev/null; then
    CONTAINER_CMD="docker"
    log_info "Using Docker as container runtime (Podman recommended for rootless)"
  else
    CONTAINER_CMD=""
    log_debug "No container runtime detected (Podman recommended)"
  fi
}

setup_rootless_podman() {
  local current_user="$USER"
  local user_id
  user_id=$(id -u)

  show_banner
  echo "Rootless Podman Setup Wizard"
  echo "==========================================================="
  echo
  log_info "Setting up Podman for user: $current_user (UID: $user_id)"
  echo

  # Check and enable Podman socket for rootless mode
  if [[ $EUID -ne 0 ]]; then
    log_debug "Checking Podman socket for rootless operation..."
    
    # Check if socket exists and is active
    if ! systemctl --user is-active --quiet podman.socket 2>/dev/null; then
      log_warn "Podman socket not active. Enabling..."
      
      # Enable user lingering first
      if ! loginctl show-user "$USER" 2>/dev/null | grep -q "Linger=yes"; then
        log_info "Enabling user lingering..."
        loginctl enable-linger "$USER" 2>/dev/null || {
          log_warn "Could not enable lingering (may need sudo)"
        }
      fi
      
      # Enable and start podman socket
      if systemctl --user enable --now podman.socket 2>/dev/null; then
        log_success "Podman socket enabled"
        sleep 2  # Give socket time to start
      else
        log_warn "Could not enable Podman socket automatically"
        log_info "Run manually: systemctl --user enable --now podman.socket"
      fi
    else
      log_debug "Podman socket is active"
    fi
  fi
  
  # Final test
  echo
  log_step "Testing Podman with 'podman info' and 'podman run --rm hello-world'..."
  echo "─────────────────────────────────────────────────────────"
  podman info || log_error "podman info failed"
  echo "─────────────────────────────────────────────────────────"
  podman run --rm hello-world || log_error "podman run --rm hello-world failed"
  echo "─────────────────────────────────────────────────────────"
  pause
}

# ============================================================================
# LOCK MANAGEMENT
# ============================================================================

acquire_lock() {
  if [[ -f "$LOCK_FILE" ]]; then
    local lock_pid
    lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    
    if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
      log_error "Another instance is running (PID: $lock_pid)"
      return 1
    fi
  fi
  
  echo "$SCRIPT_PID" > "$LOCK_FILE" || {
    log_error "Failed to create lock file"
    return 1
  }
  
  log_debug "Lock acquired (PID: $SCRIPT_PID)"
  return 0
}

release_lock() {
  if [[ -f "$LOCK_FILE" ]]; then
    local lock_pid
    lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    
    if [[ "$lock_pid" == "$SCRIPT_PID" ]]; then
      rm -f "$LOCK_FILE"
      log_debug "Lock released"
    fi
  fi
}

cleanup_on_exit() {
  local exit_code=$?
  release_lock
  
  if [[ $exit_code -ne 0 ]]; then
    log_error "Script exited with code: $exit_code"
    [[ -f "$ERROR_LOG" ]] && log_info "Error log: $ERROR_LOG"
  fi
}

trap cleanup_on_exit EXIT
trap 'log_error "Interrupted by user"; exit 130' INT
trap 'log_error "Terminated"; exit 143' TERM

# ============================================================================
# OS DETECTION
# ============================================================================

detect_os() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS="${ID}"
    OS_VERSION="${VERSION_ID:-unknown}"
  elif [[ "$(uname)" == "Darwin" ]]; then
    OS="macos"
    OS_VERSION="$(sw_vers -productVersion)"
  else
    OS="unknown"
    OS_VERSION="unknown"
  fi
  
  case "$OS" in
    rhel|centos|rocky|almalinux)
      PACKAGE_MANAGER="dnf"
      [[ -f /usr/bin/yum ]] && PACKAGE_MANAGER="yum"
      ;;
    fedora)
      PACKAGE_MANAGER="dnf"
      ;;
    ubuntu|debian)
      PACKAGE_MANAGER="apt"
      ;;
    macos)
      PACKAGE_MANAGER="brew"
      ;;
    *)
      PACKAGE_MANAGER="unknown"
      ;;
  esac
  
  log_info "Detected OS: ${OS} (version: ${OS_VERSION})"
  log_info "Package Manager: ${PACKAGE_MANAGER}"
}

# ============================================================================
# PROJECT INITIALIZATION
# ============================================================================

create_project_structure() {
  log_step "Creating project structure..."
  
  local dirs=(
    "data/models"
    "data/training"
    "data/outputs"
    "data/logs"
    "scripts"
    "config"
    ".backups"
  )
  
  for dir in "${dirs[@]}"; do
    mkdir -p "${PROJECT_ROOT}/${dir}"
    touch "${PROJECT_ROOT}/${dir}/.gitkeep"
  done
  
  log_success "Project directories created"
}

create_requirements_txt() {
  local req_file="${PROJECT_ROOT}/requirements.txt"
  
  if [[ -f "$req_file" ]]; then
    log_info "requirements.txt already exists"
    return 0
  fi
  
  log_step "Creating requirements.txt..."
  
  cat > "$req_file" << 'EOF'
# OllamaTrauma Python Dependencies
requests>=2.31.0
beautifulsoup4>=4.12.0
huggingface-hub>=0.19.0
pyyaml>=6.0
tqdm>=4.66.0
lxml>=4.9.0
argparse>=1.4.0
urllib3>=2.0.0
EOF
  
  log_success "requirements.txt created"
}

create_gitignore() {
  local gitignore="${PROJECT_ROOT}/.gitignore"
  
  if [[ -f "$gitignore" ]]; then
    log_info ".gitignore already exists"
    return 0
  fi
  
  log_step "Creating .gitignore..."
  
  cat > "$gitignore" << 'EOF'
# OllamaTrauma
*.log
.ollamatrauma.lock
.backups/
data/models/*
!data/models/.gitkeep
data/training/*
!data/training/.gitkeep
data/outputs/*
!data/outputs/.gitkeep
data/logs/*
!data/logs/.gitkeep

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/

# OS
.DS_Store
Thumbs.db
*~
EOF
  
  log_success ".gitignore created"
}

create_utility_scripts() {
  log_step "Creating utility scripts..."
  
  # HF Search Script
  cat > "${PROJECT_ROOT}/scripts/hf_search.py" << 'EOFPY'
#!/usr/bin/env python3
"""Search Hugging Face models"""
import sys
import requests
import argparse

def search_models(query, limit=15):
    url = "https://huggingface.co/api/models"
    params = {"search": query, "limit": limit}
    
    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        models = response.json()
        
        print(f"\nFound {len(models)} models:\n")
        for i, model in enumerate(models, 1):
            print(f"{i}. {model['id']}")
            print(f"   Downloads: {model.get('downloads', 'N/A')}")
            print(f"   Tags: {', '.join(model.get('tags', [])[:3])}\n")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("query", help="Search query")
    parser.add_argument("--limit", type=int, default=15)
    args = parser.parse_args()
    search_models(args.query, args.limit)
EOFPY
  
  chmod +x "${PROJECT_ROOT}/scripts/hf_search.py"
  log_success "Created hf_search.py"
  
  # URL Crawler Script
  cat > "${PROJECT_ROOT}/scripts/url_crawler.py" << 'EOFPY'
#!/usr/bin/env python3
"""Crawl URLs for training data"""
import sys
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
import argparse

def crawl_url(url, depth=3, visited=None):
    if visited is None:
        visited = set()
    
    if depth == 0 or url in visited:
        return
    
    visited.add(url)
    print(f"Crawling: {url}")
    
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Extract text
        text = soup.get_text(separator='\n', strip=True)
        filename = f"training_data_{len(visited)}.txt"
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(text)
        print(f"  Saved to: {filename}")
        
        # Find links
        for link in soup.find_all('a', href=True):
            next_url = urljoin(url, link['href'])
            if urlparse(next_url).netloc == urlparse(url).netloc:
                crawl_url(next_url, depth-1, visited)
    except Exception as e:
        print(f"  Error: {e}", file=sys.stderr)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("url", help="URL to crawl")
    parser.add_argument("--depth", type=int, default=3)
    args = parser.parse_args()
    crawl_url(args.url, args.depth)
EOFPY
  
  chmod +x "${PROJECT_ROOT}/scripts/url_crawler.py"
  log_success "Created url_crawler.py"
  
  # Monitor Download Script
  cat > "${PROJECT_ROOT}/scripts/monitor_download.sh" << 'EOFSH'
#!/bin/bash
# Monitor batch download progress

clear
echo "==================================================================="
echo "  OllamaTrauma Batch Download Monitor"
echo "==================================================================="
echo ""
echo "Press Ctrl+C to stop monitoring (download will continue)"
echo ""

while true; do
    echo "==================================================================="
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "───────────────────────────────────────────────────────────────────"
    
    # Show downloaded models
    echo ""
    echo "Downloaded Models:"
    if command -v ollama &>/dev/null; then
        ollama list 2>/dev/null || echo "  (Ollama not running yet)"
    else
        echo "  (Ollama not installed yet)"
    fi
    
    # Show disk space
    echo ""
    echo "Disk Space:"
    df -h / | grep -E "Filesystem|/dev/mapper" | head -2
    
    echo ""
    echo "==================================================================="
    echo "Refreshing in 10 seconds... (Ctrl+C to exit)"
    
    sleep 10
    clear
done
EOFSH
  
  chmod +x "${PROJECT_ROOT}/scripts/monitor_download.sh"
  log_success "Created monitor_download.sh"
  
  # Create convenience symlink in project root
  if [[ ! -L "${PROJECT_ROOT}/monitor_download.sh" ]]; then
    ln -sf "${PROJECT_ROOT}/scripts/monitor_download.sh" "${PROJECT_ROOT}/monitor_download.sh"
    log_success "Created symlink to monitor_download.sh in project root"
  fi
}

initialize_project() {
  show_banner
  log_step "Initializing OllamaTrauma project..."
  
  create_project_structure
  create_requirements_txt
  create_gitignore
  create_utility_scripts
  
  # Setup rootless Podman if available
  if command -v podman &>/dev/null; then
    echo
    log_step "Setting up rootless Podman..."
    setup_rootless_podman
  else
    echo
    log_info "Podman not installed. Install later via 'Container Runtime Setup'"
  fi
  
  log_success "Project initialization complete!"
  pause
}

# ============================================================================
# DEPENDENCY MANAGEMENT
# ============================================================================

check_command() {
  local cmd="$1"
  if command -v "$cmd" &>/dev/null; then
    log_success "$cmd installed"
    return 0
  else
    log_warn "$cmd NOT installed"
    return 1
  fi
}

install_system_dependencies() {
  log_step "Installing system dependencies..."
  
  local deps=()
  case "$PACKAGE_MANAGER" in
    dnf|yum)
      deps=(git curl jq python3 python3-pip wget tar gzip make gcc gcc-c++)
      sudo "$PACKAGE_MANAGER" install -y "${deps[@]}"
      ;;
    apt)
      deps=(git curl jq python3 python3-pip wget tar gzip make gcc g++)
      sudo apt update
      sudo apt install -y "${deps[@]}"
      ;;
    brew)
      deps=(git curl jq python3 wget)
      brew install "${deps[@]}"
      ;;
    *)
      log_error "Unsupported package manager: $PACKAGE_MANAGER"
      return 1
      ;;
  esac
  
  log_success "System dependencies installed"
}

install_python_packages() {
  log_step "Installing Python packages..."
  
  if [[ ! -f "${PROJECT_ROOT}/requirements.txt" ]]; then
    log_error "requirements.txt not found"
    return 1
  fi
  
  python3 -m pip install --user --upgrade pip
  python3 -m pip install --user -r "${PROJECT_ROOT}/requirements.txt"
  
  log_success "Python packages installed"
}

# Comprehensive dependency check - runs at startup
check_all_dependencies() {
  local missing=0
  local python_missing=0
  
  # Critical system packages required for script to run
  local critical_deps=(bash curl python3)
  local recommended_deps=(git jq wget tar gzip)
  
  log_debug "Checking critical system dependencies..."
  
  # Check critical dependencies
  for cmd in "${critical_deps[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      log_error "CRITICAL: $cmd is not installed (required)"
      ((missing++))
    fi
  done
  
  # Check recommended dependencies
  for cmd in "${recommended_deps[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      log_debug "Recommended: $cmd is not installed"
    fi
  done
  
  # Check container runtime (Podman preferred)
  if ! command -v podman &>/dev/null && ! command -v docker &>/dev/null; then
    log_warn "No container runtime found (Podman recommended)"
  fi
  
  # Check Python requirements if requirements.txt exists
  if [[ -f "${PROJECT_ROOT}/requirements.txt" ]]; then
    log_debug "Checking Python package requirements..."
    
    while IFS= read -r line || [[ -n "$line" ]]; do
      # Skip comments and empty lines
      [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
      
      # Extract package name (before == or >= or <=)
      local pkg_name
      pkg_name=$(echo "$line" | sed 's/[>=<].*//' | tr -d '[:space:]')
      
      if [[ -n "$pkg_name" ]]; then
        if ! python3 -c "import ${pkg_name}" 2>/dev/null; then
          log_debug "Python package not found: $pkg_name"
          ((python_missing++))
        fi
      fi
    done < "${PROJECT_ROOT}/requirements.txt"
    
    if [[ $python_missing -gt 0 ]]; then
      log_debug "$python_missing Python packages not installed"
    fi
  fi
  
  # If critical dependencies are missing, abort
  if [[ $missing -gt 0 ]]; then
    log_error "Cannot continue: $missing critical dependencies missing"
    log_info "Please install missing packages using your system package manager"
    log_info "Example (RHEL/Fedora): sudo dnf install bash curl python3"
    log_info "Example (Debian/Ubuntu): sudo apt install bash curl python3"
    return 1
  fi
  
  return 0
}

check_dependencies() {
  show_banner
  log_step "Checking dependencies..."
  echo

  local missing=0
  local deps=(curl git python3 jq)
  
  # Add container runtime to check
  if [[ -n "$CONTAINER_CMD" ]]; then
    deps+=("$CONTAINER_CMD")
  else
    deps+=(podman docker)  # Check Podman first (preferred)
  fi
  
  for cmd in "${deps[@]}"; do
    if check_command "$cmd"; then
      case "$cmd" in
        python3) python3 --version | sed 's/^/  /' ;;
        git) git --version | sed 's/^/  /' ;;
        docker|podman) $cmd --version | sed 's/^/  /' ;;
        ollama) ollama --version | sed 's/^/  /' ;;
      esac
    else
      ((missing++))
    fi
  done
  
  echo
  if [[ $missing -eq 0 ]]; then
    log_success "All critical dependencies installed"
  else
    log_warn "$missing dependencies missing"
    echo
    read -p "Install missing dependencies? [y/N]: " -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      install_system_dependencies
      install_python_packages
    fi
  fi
  
  pause
}

# ============================================================================
# AI RUNNER INSTALLATION FUNCTIONS
# ============================================================================

install_ollama() {
  show_banner
  log_step "Installing Ollama..."
  echo
  
  if command -v ollama &>/dev/null; then
    log_info "Ollama is already installed"
    ollama --version
    pause
    return 0
  fi
  
  # Check system resources before installation
  if ! show_resource_warning "Ollama installation"; then
    return 1
  fi
  
  case "$OS" in
    rhel|fedora|centos|rocky|almalinux)
      log_info "Installing Ollama on RHEL/Fedora..."
      curl -fsSL https://ollama.ai/install.sh | sh
      ;;
    macos)
      log_info "Installing Ollama on macOS..."
      brew install ollama
      ;;
    *)
      log_info "Installing Ollama (generic Linux)..."
      curl -fsSL https://ollama.ai/install.sh | sh
      ;;
  esac
  
  if command -v ollama &>/dev/null; then
    log_success "Ollama installed successfully"
    ollama --version
  else
    log_error "Ollama installation failed"
  fi
  
  pause
}

uninstall_ollama() {
  show_banner
  log_step "Uninstalling Ollama..."
  echo
  
  if ! command -v ollama &>/dev/null; then
    log_warn "Ollama is not installed"
    pause
    return 0
  fi
  
  read -p "Are you sure you want to uninstall Ollama? [y/N]: " -r reply
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    log_info "Uninstall cancelled"
    pause
    return 0
  fi
  
  # Stop ollama service if running
  sudo systemctl stop ollama 2>/dev/null || true
  sudo systemctl disable ollama 2>/dev/null || true
  
  # Remove ollama binary and service
  sudo rm -f /usr/local/bin/ollama
  sudo rm -f /etc/systemd/system/ollama.service
  sudo systemctl daemon-reload
  
  # Remove ollama data
  rm -rf ~/.ollama
  
  log_success "Ollama uninstalled"
  pause
}

install_localai() {
  show_banner
  log_step "Installing LocalAI..."
  echo
  
  if [[ -z "$CONTAINER_CMD" ]]; then
    log_error "No container runtime detected. Please install Docker or Podman first."
    pause
    return 1
  fi
  
  # Check system resources before installation
  if ! show_resource_warning "LocalAI installation"; then
    return 1
  fi
  
  log_info "Pulling LocalAI container image..."
  $CONTAINER_CMD pull quay.io/go-skynet/local-ai:latest-aio-cpu
  
  log_success "LocalAI container image downloaded"
  log_info "To run LocalAI, use: Start AI Runner from the menu"
  pause
}

uninstall_localai() {
  show_banner
  log_step "Uninstalling LocalAI..."
  echo
  
  if [[ -z "$CONTAINER_CMD" ]]; then
    log_warn "No container runtime detected"
    pause
    return 0
  fi
  
  # Stop and remove container
  $CONTAINER_CMD stop localai 2>/dev/null || true
  $CONTAINER_CMD rm localai 2>/dev/null || true
  
  # Remove image
  $CONTAINER_CMD rmi quay.io/go-skynet/local-ai:latest-aio-cpu 2>/dev/null || true
  
  # Remove data
  rm -rf "${PROJECT_ROOT}/localai-models"
  
  log_success "LocalAI uninstalled"
  pause
}

install_llamacpp() {
  show_banner
  log_step "Installing llama.cpp..."
  echo
  
  if [[ -d "$LLAMACPP_DIR" ]]; then
    log_info "llama.cpp directory already exists"
    read -p "Reinstall? [y/N]: " -r reply
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
      pause
      return 0
    fi
    rm -rf "$LLAMACPP_DIR"
  fi
  
  # Check system resources before installation
  if ! show_resource_warning "llama.cpp compilation"; then
    return 1
  fi
  
  log_info "Cloning llama.cpp repository..."
  git clone https://github.com/ggerganov/llama.cpp.git "$LLAMACPP_DIR"
  
  log_info "Building llama.cpp..."
  cd "$LLAMACPP_DIR"
  make clean
  make -j$(nproc 2>/dev/null || echo 4)
  
  if [[ -f "${LLAMACPP_DIR}/main" ]]; then
    log_success "llama.cpp built successfully"
  else
    log_error "llama.cpp build failed"
  fi
  
  cd "$PROJECT_ROOT"
  pause
}

uninstall_llamacpp() {
  show_banner
  log_step "Uninstalling llama.cpp..."
  echo
  
  if [[ ! -d "$LLAMACPP_DIR" ]]; then
    log_warn "llama.cpp is not installed"
    pause
    return 0
  fi
  
  read -p "Are you sure you want to remove llama.cpp? [y/N]: " -r reply
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    log_info "Uninstall cancelled"
    pause
    return 0
  fi
  
  rm -rf "$LLAMACPP_DIR"
  log_success "llama.cpp removed"
  pause
}

install_textgen_webui() {
  show_banner
  log_step "Installing text-generation-webui..."
  echo
  
  if [[ -d "$TEXTGEN_DIR" ]]; then
    log_info "text-generation-webui directory already exists"
    read -p "Reinstall? [y/N]: " -r reply
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
      pause
      return 0
    fi
    rm -rf "$TEXTGEN_DIR"
  fi
  
  log_info "Cloning text-generation-webui repository..."
  git clone https://github.com/oobabooga/text-generation-webui.git "$TEXTGEN_DIR"
  
  log_info "Installing dependencies..."
  cd "$TEXTGEN_DIR"
  
  if [[ -f "start_linux.sh" ]]; then
    chmod +x start_linux.sh
    log_success "text-generation-webui installed"
    log_info "To start, run: ./start_linux.sh from ${TEXTGEN_DIR}"
  else
    log_error "Installation may be incomplete"
  fi
  
  cd "$PROJECT_ROOT"
  pause
}

uninstall_textgen_webui() {
  show_banner
  log_step "Uninstalling text-generation-webui..."
  echo
  
  if [[ ! -d "$TEXTGEN_DIR" ]]; then
    log_warn "text-generation-webui is not installed"
    pause
    return 0
  fi
  
  read -p "Are you sure you want to remove text-generation-webui? [y/N]: " -r reply
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    log_info "Uninstall cancelled"
    pause
    return 0
  fi
  
  rm -rf "$TEXTGEN_DIR"
  log_success "text-generation-webui removed"
  pause
}

start_runner() {
  show_banner
  echo "Start AI Runner"
  echo "==========================================================="
  echo
  echo "Which AI runner do you want to start?"
  echo
  echo "  1) Ollama"
  echo "  2) LocalAI (container)"
  echo "  3) llama.cpp (manual)"
  echo "  4) text-generation-webui"
  echo "  0) Cancel"
  echo
  read -p "Select runner [0-4]: " -r choice
  
  case "$choice" in
    1)
      if command -v ollama &>/dev/null; then
        log_info "Starting Ollama service..."
        sudo systemctl start ollama
        sudo systemctl enable ollama
        log_success "Ollama service started"
        log_info "Access at: http://localhost:11434"
      else
        log_error "Ollama is not installed"
      fi
      ;;
    2)
      if [[ -z "$CONTAINER_CMD" ]]; then
        log_error "No container runtime available"
        pause
        return 1
      fi
      log_info "Starting LocalAI container..."
      mkdir -p "${PROJECT_ROOT}/localai-models"
      $CONTAINER_CMD run -d \
        --name localai \
        -p 8080:8080 \
        -v "${PROJECT_ROOT}/localai-models:/build/models:Z" \
        quay.io/go-skynet/local-ai:latest-aio-cpu
      log_success "LocalAI started"
      log_info "Access at: http://localhost:8080"
      ;;
    3)
      if [[ ! -f "${LLAMACPP_DIR}/main" ]]; then
        log_error "llama.cpp is not installed or not built"
      else
        log_info "llama.cpp location: ${LLAMACPP_DIR}"
        log_info "To run manually: cd ${LLAMACPP_DIR} && ./main -m <model_path>"
      fi
      ;;
    4)
      if [[ ! -d "$TEXTGEN_DIR" ]]; then
        log_error "text-generation-webui is not installed"
      else
        log_info "Starting text-generation-webui..."
        cd "$TEXTGEN_DIR"
        if [[ -f "start_linux.sh" ]]; then
          ./start_linux.sh &
          log_success "text-generation-webui started"
          log_info "Check the terminal output for the web interface URL"
        else
          log_error "start_linux.sh not found"
        fi
        cd "$PROJECT_ROOT"
      fi
      ;;
    0)
      log_info "Cancelled"
      ;;
    *)
      log_error "Invalid option"
      ;;
  esac
  
  pause
}

stop_runner() {
  show_banner
  echo "Stop AI Runner"
  echo "==========================================================="
  echo
  echo "Which AI runner do you want to stop?"
  echo
  echo "  1) Ollama"
  echo "  2) LocalAI (container)"
  echo "  3) text-generation-webui"
  echo "  0) Cancel"
  echo
  read -p "Select runner [0-3]: " -r choice
  
  case "$choice" in
    1)
      log_info "Stopping Ollama service..."
      sudo systemctl stop ollama
      log_success "Ollama service stopped"
      ;;
    2)
      if [[ -n "$CONTAINER_CMD" ]]; then
        log_info "Stopping LocalAI container..."
        $CONTAINER_CMD stop localai 2>/dev/null || log_warn "Container not running"
        log_success "LocalAI stopped"
      else
        log_error "No container runtime available"
      fi
      ;;
    3)
      log_info "Stopping text-generation-webui..."
      pkill -f "text-generation-webui" || log_warn "Process not found"
      log_success "text-generation-webui stopped"
      ;;
    0)
      log_info "Cancelled"
      ;;
    *)
      log_error "Invalid option"
      ;;
  esac
  
  pause
}

# ============================================================================
# SYSTEM MONITORING AND HEALTH FUNCTIONS
# ============================================================================

health_check_dashboard() {
  while true; do
    show_banner
    echo "Health Check Dashboard"
    echo "==========================================================="
    echo
    
    # System Resources
    echo "${CYAN}[SYSTEM RESOURCES]${NC}"
    echo "─────────────────────────────────────────────────────────"
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo "  CPU Usage: ${cpu_usage}%"
    
    local mem_info
    mem_info=$(free -h | awk 'NR==2{printf "  Memory: %s / %s (%.0f%%)", $3, $2, $3/$2 * 100}')
    echo "$mem_info"
    
    local disk_info
    disk_info=$(df -h "${PROJECT_ROOT}" | awk 'NR==2{printf "  Disk: %s / %s (%s)", $3, $2, $5}')
    echo "$disk_info"
    
    local load_avg
    load_avg=$(uptime | awk -F'load average:' '{print $2}')
    echo "  Load Average:$load_avg"
    echo
    
    # AI Runners Status
    echo "${CYAN}[AI RUNNERS]${NC}"
    echo "─────────────────────────────────────────────────────────"
    
    # Ollama
    if command -v ollama &>/dev/null; then
      if systemctl is-active --quiet ollama 2>/dev/null; then
        echo "  ${GREEN}OK${NC} Ollama: Running (port 11434)"
        if netstat -tuln 2>/dev/null | grep -q ":11434 "; then
          echo "    → http://localhost:11434"
        fi
      else
        echo "  ${YELLOW}${NC} Ollama: Installed, not running"
      fi
    else
      echo "  ${RED}${NC} Ollama: Not installed"
    fi
    
    # LocalAI
    if [[ -n "$CONTAINER_CMD" ]]; then
      if $CONTAINER_CMD ps --filter name=localai --format '{{.Status}}' 2>/dev/null | grep -q "Up"; then
        echo "  ${GREEN}OK${NC} LocalAI: Running (port 8080)"
        echo "    → http://localhost:8080"
      else
        if $CONTAINER_CMD images | grep -q "local-ai"; then
          echo "  ${YELLOW}${NC} LocalAI: Installed, not running"
        else
          echo "  ${RED}${NC} LocalAI: Not installed"
        fi
      fi
    fi
    
    # llama.cpp
    if [[ -f "${LLAMACPP_DIR}/main" ]]; then
      echo "  ${GREEN}OK${NC} llama.cpp: Installed"
      echo "    → ${LLAMACPP_DIR}"
    else
      echo "  ${RED}${NC} llama.cpp: Not installed"
    fi
    
    # text-generation-webui
    if [[ -d "$TEXTGEN_DIR" ]]; then
      if pgrep -f "text-generation-webui" &>/dev/null; then
        echo "  ${GREEN}OK${NC} text-gen-webui: Running"
      else
        echo "  ${YELLOW}${NC} text-gen-webui: Installed, not running"
      fi
    else
      echo "  ${RED}${NC} text-gen-webui: Not installed"
    fi
    echo
    
    # Models
    echo "${CYAN}[MODELS]${NC}"
    echo "─────────────────────────────────────────────────────────"
    if command -v ollama &>/dev/null; then
      local model_count
      model_count=$(ollama list 2>/dev/null | tail -n +2 | wc -l)
      echo "  Ollama Models: $model_count"
    fi
    
    if [[ -d "${PROJECT_ROOT}/data/models" ]]; then
      local local_models
      local_models=$(find "${PROJECT_ROOT}/data/models" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
      echo "  Local Models: $local_models"
    fi
    echo
    
    # Active Ports
    echo "${CYAN}[ACTIVE PORTS]${NC}"
    echo "─────────────────────────────────────────────────────────"
    if command -v netstat &>/dev/null; then
      netstat -tuln 2>/dev/null | grep -E ":(8080|11434|7860|5000)" | awk '{print "  " $4}' || echo "  No AI services detected"
    elif command -v ss &>/dev/null; then
      ss -tuln 2>/dev/null | grep -E ":(8080|11434|7860|5000)" | awk '{print "  " $5}' || echo "  No AI services detected"
    else
      echo "  (netstat/ss not available)"
    fi
    echo
    
    echo "==========================================================="
    echo "  [R] Refresh   [Q] Back to Menu"
    echo
    read -p "Select: " -r -n1 choice
    echo
    
    case "${choice,,}" in
      q) return 0 ;;
      r) continue ;;
      *) continue ;;
    esac
  done
}

show_resource_warning() {
  local operation="$1"
  
  echo "${YELLOW}[RESOURCE CHECK]${NC}"
  echo "─────────────────────────────────────────────────────────"
  
  # Check available memory
  local free_mem_gb
  free_mem_gb=$(free -g | awk '/^Mem:/{print $7}')
  echo "  Available Memory: ${free_mem_gb}GB"
  
  # Check disk space
  local free_disk_gb
  free_disk_gb=$(df -BG "${PROJECT_ROOT}" | awk 'NR==2{print $4}' | sed 's/G//')
  echo "  Available Disk: ${free_disk_gb}GB"
  
  # Check CPU load
  local load_avg
  load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')
  echo "  CPU Load: $load_avg"
  echo
  
  # Warnings
  local warnings=0
  if [[ $free_mem_gb -lt 2 ]]; then
    log_warn "Low memory available (${free_mem_gb}GB)"
    ((warnings++))
  fi
  
  if [[ $free_disk_gb -lt 10 ]]; then
    log_warn "Low disk space available (${free_disk_gb}GB)"
    ((warnings++))
  fi
  
  if [[ $warnings -gt 0 ]]; then
    echo
    read -p "Continue with $operation anyway? [y/N]: " -r reply
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
      log_info "Operation cancelled"
      return 1
    fi
  fi
  
  return 0
}

check_installed_runners() {
  show_banner
  echo "Installed AI Runners"
  echo "==========================================================="
  echo
  
  # Check Ollama
  if command -v ollama &>/dev/null; then
    log_success "Ollama: Installed"
    echo "  Version: $(ollama --version 2>/dev/null || echo 'unknown')"
    echo "  Status: $(systemctl is-active ollama 2>/dev/null || echo 'inactive')"
  else
    log_warn "Ollama: Not installed"
  fi
  echo
  
  # Check LocalAI
  if [[ -n "$CONTAINER_CMD" ]]; then
    if $CONTAINER_CMD images | grep -q "local-ai"; then
      log_success "LocalAI: Container image available"
      echo "  Status: $($CONTAINER_CMD ps -a --filter name=localai --format '{{.Status}}' 2>/dev/null || echo 'not running')"
    else
      log_warn "LocalAI: Not installed"
    fi
  else
    log_warn "LocalAI: Cannot check (no container runtime)"
  fi
  echo
  
  # Check llama.cpp
  if [[ -d "$LLAMACPP_DIR" ]] && [[ -f "${LLAMACPP_DIR}/main" ]]; then
    log_success "llama.cpp: Installed"
    echo "  Location: ${LLAMACPP_DIR}"
  else
    log_warn "llama.cpp: Not installed"
  fi
  echo
  
  # Check text-generation-webui
  if [[ -d "$TEXTGEN_DIR" ]]; then
    log_success "text-generation-webui: Installed"
    echo "  Location: ${TEXTGEN_DIR}"
  else
    log_warn "text-generation-webui: Not installed"
  fi
  echo
  
  pause
}

# ============================================================================
# MODEL MANAGEMENT FUNCTIONS
# ============================================================================

interactive_model_selector() {
  show_banner
  log_step "Interactive Model Selector"
  echo
  
  echo "Popular Models - Select to Download:"
  echo "==========================================================="
  echo
  echo "Large Language Models:"
  echo "  1) Llama 2 7B (4GB RAM)"
  echo "  2) Llama 2 13B (8GB RAM)"
  echo "  3) Mistral 7B (4GB RAM)"
  echo "  4) Mixtral 8x7B (24GB RAM)"
  echo "  5) CodeLlama 7B (4GB RAM)"
  echo
  echo "Specialized Models:"
  echo "  6) TinyLlama 1.1B (1GB RAM)"
  echo "  7) Phi-2 2.7B (2GB RAM)"
  echo "  8) Neural Chat 7B (4GB RAM)"
  echo "  9) Orca Mini 3B (2GB RAM)"
  echo "  10) Vicuna 7B (4GB RAM)"
  echo
  echo "Vision Models:"
  echo "  11) LLaVA 7B (5GB RAM)"
  echo "  12) BakLLaVA 7B (5GB RAM)"
  echo
  echo "  0) Cancel"
  echo
  read -p "Select model [0-12]: " -r choice
  
  local model_name=""
  case "$choice" in
    1) model_name="llama2:7b" ;;
    2) model_name="llama2:13b" ;;
    3) model_name="mistral:7b" ;;
    4) model_name="mixtral:8x7b" ;;
    5) model_name="codellama:7b" ;;
    6) model_name="tinyllama:1.1b" ;;
    7) model_name="phi:2.7b" ;;
    8) model_name="neural-chat:7b" ;;
    9) model_name="orca-mini:3b" ;;
    10) model_name="vicuna:7b" ;;
    11) model_name="llava:7b" ;;
    12) model_name="bakllava:7b" ;;
    0) log_info "Cancelled" && pause && return 0 ;;
    *) log_error "Invalid option" && pause && return 1 ;;
  esac
  
  if ! command -v ollama &>/dev/null; then
    log_error "Ollama is not installed. Install it first from AI Runners menu."
    pause
    return 1
  fi
  
  log_info "Downloading $model_name with Ollama..."
  echo
  ollama pull "$model_name"
  
  if [[ $? -eq 0 ]]; then
    log_success "Model downloaded: $model_name"
    echo
    read -p "Test the model now? [y/N]: " -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      ollama run "$model_name"
    fi
  else
    log_error "Model download failed"
  fi
  
  pause
}

download_model_huggingface() {
  show_banner
  log_step "Download Model from Hugging Face"
  echo
  
  if [[ ! -f "${PROJECT_ROOT}/scripts/hf_search.py" ]]; then
    log_error "hf_search.py not found. Please run 'Initialize Project' first."
    pause
    return 1
  fi
  
  read -p "Enter search query (e.g., 'llama', 'mistral'): " -r query
  if [[ -z "$query" ]]; then
    log_error "No query provided"
    pause
    return 1
  fi
  
  log_info "Searching Hugging Face..."
  python3 "${PROJECT_ROOT}/scripts/hf_search.py" "$query"
  
  echo
  read -p "Enter model ID to download (e.g., 'TheBloke/Llama-2-7B-GGUF'): " -r model_id
  if [[ -z "$model_id" ]]; then
    log_error "No model ID provided"
    pause
    return 1
  fi
  
  log_info "Downloading model: $model_id"
  mkdir -p "${PROJECT_ROOT}/data/models"
  
  # Use huggingface-cli to download
  if command -v huggingface-cli &>/dev/null; then
    huggingface-cli download "$model_id" --local-dir "${PROJECT_ROOT}/data/models/${model_id##*/}"
    log_success "Model downloaded to: ${PROJECT_ROOT}/data/models/${model_id##*/}"
  else
    log_error "huggingface-cli not found. Install with: pip install huggingface-hub"
  fi
  
  pause
}

convert_model_ollama() {
  show_banner
  log_step "Convert Model to Ollama Format"
  echo
  log_warn "This feature requires manual model conversion"
  log_info "Visit: https://github.com/ollama/ollama/blob/main/docs/import.md"
  pause
}

list_available_models() {
  show_banner
  log_step "Available Models"
  echo
  
  local models_dir="${PROJECT_ROOT}/data/models"
  
  if [[ ! -d "$models_dir" ]] || [[ -z "$(ls -A "$models_dir")" ]]; then
    log_warn "No models found in: $models_dir"
  else
    log_info "Models in: $models_dir"
    echo
    ls -lh "$models_dir"
  fi
  
  echo
  if command -v ollama &>/dev/null; then
    log_info "Ollama models:"
    echo
    ollama list || log_warn "Could not list Ollama models"
  fi
  
  pause
}

setup_batch_download_helper() {
  show_banner
  log_step "Batch Download Quick Setup Helper"
  echo
  
  # Get system info
  log_info "Detecting your system..."
  echo
  local total_ram=$(free -g | awk '/^Mem:/{print $2}')
  local free_disk=$(df -BG . | awk 'NR==2{print $4}' | sed 's/G//')
  echo "  Total RAM: ${total_ram}GB"
  echo "  Free Disk: ${free_disk}GB"
  echo
  
  echo "==========================================================="
  echo "  Available Batch Profiles"
  echo "==========================================================="
  echo
  echo "  1) Low Resource      (4GB RAM, ~8GB disk)   - 3 tiny models"
  echo "  2) Development       (8GB RAM, ~10GB disk)  - 4 models (RECOMMENDED)"
  echo "  3) Coding            (8GB RAM, ~15GB disk)  - 4 code-focused models"
  echo "  4) Production        (16GB RAM, ~30GB disk) - 5 quality models"
  echo "  5) High Performance  (32GB+ RAM, ~60GB disk) - 5 large models"
  echo "  6) Custom (edit manually)"
  echo "  0) Cancel"
  echo
  
  # Recommend based on system
  local recommended=2
  echo "Recommendation for your system (${total_ram}GB RAM, ${free_disk}GB free):"
  if [[ $total_ram -lt 8 ]]; then
    echo "  → Profile 1 (Low Resource) is best for you"
    recommended=1
  elif [[ $total_ram -lt 16 ]]; then
    echo "  → Profile 2 (Development) or 3 (Coding) recommended"
    recommended=2
  elif [[ $total_ram -lt 32 ]]; then
    echo "  → Profile 4 (Production) recommended"
    recommended=4
  else
    echo "  → Profile 5 (High Performance) - you have plenty of resources!"
    recommended=5
  fi
  echo
  
  read -p "Select profile [0-6, Enter for recommended]: " choice
  
  # Use recommended if user just presses Enter
  if [[ -z "$choice" ]]; then
    choice=$recommended
  fi
  
  local profile=""
  local name=""
  
  case "$choice" in
    1)
      profile="batch_low_resource.txt"
      name="Low Resource"
      ;;
    2)
      profile="batch_dev_profile.txt"
      name="Development"
      ;;
    3)
      profile="batch_coding_profile.txt"
      name="Coding"
      ;;
    4)
      profile="batch_production_profile.txt"
      name="Production"
      ;;
    5)
      profile="batch_high_performance.txt"
      name="High Performance"
      ;;
    6)
      echo
      log_info "Opening models_batch.txt for editing..."
      echo "Uncomment (remove #) the models you want to download"
      echo
      pause
      ${EDITOR:-nano} "${PROJECT_ROOT}/config/models_batch.txt"
      log_success "Configuration ready!"
      echo
      log_info "Next step: Select option 3 (Batch Download Models) from this menu"
      pause
      return 0
      ;;
    0)
      log_info "Cancelled"
      pause
      return 0
      ;;
    *)
      log_error "Invalid choice"
      pause
      return 1
      ;;
  esac
  
  echo
  log_info "Setting up $name profile..."
  echo
  
  # Copy the profile
  local profile_path="${PROJECT_ROOT}/config/$profile"
  if [[ -f "$profile_path" ]]; then
    cp "$profile_path" "${PROJECT_ROOT}/config/models_batch.txt"
    log_success "Copied $profile to models_batch.txt"
    echo
    echo "Models that will be downloaded:"
    echo "─────────────────────────────────────────────────────────"
    grep -v "^#" "${PROJECT_ROOT}/config/models_batch.txt" | grep -v "^$" | sed 's/^/  → /'
    echo "─────────────────────────────────────────────────────────"
    echo
    
    # Count models
    local model_count=$(grep -v "^#" "${PROJECT_ROOT}/config/models_batch.txt" | grep -v "^$" | wc -l)
    echo "Total models: $model_count"
    echo
    
    # Estimate
    case "$name" in
      "Low Resource")
        echo "Estimated download size: ~8GB"
        echo "Estimated time: 30-60 minutes"
        ;;
      "Development")
        echo "Estimated download size: ~10GB"
        echo "Estimated time: 1-2 hours"
        ;;
      "Coding")
        echo "Estimated download size: ~15GB"
        echo "Estimated time: 2-3 hours"
        ;;
      "Production")
        echo "Estimated download size: ~30GB"
        echo "Estimated time: 3-5 hours"
        ;;
      "High Performance")
        echo "Estimated download size: ~60GB"
        echo "Estimated time: 6-10 hours"
        ;;
    esac
    
    echo
    echo "==========================================================="
    log_success "Configuration Complete!"
    echo "==========================================================="
    echo
    echo "Next steps:"
    echo "  1. Select option 3 (Batch Download Models) from this menu"
    echo "  2. Confirm and wait for downloads to complete"
    echo
    echo "Tip: You can monitor progress with:"
    echo "  watch -n 5 'ollama list'"
    echo
  else
    log_error "Profile file not found: $profile_path"
    log_info "Please ensure all profile files exist in config/ directory"
  fi
  
  pause
}

batch_download_models() {
  show_banner
  log_step "Batch Model Download"
  echo
  
  local batch_file="${PROJECT_ROOT}/config/models_batch.txt"
  
  if [[ ! -f "$batch_file" ]]; then
    log_info "Creating sample batch file: $batch_file"
    mkdir -p "${PROJECT_ROOT}/config"
    cat > "$batch_file" << 'EOF'
# OllamaTrauma Batch Model Download Configuration
# Format: model_name (one per line)
# Lines starting with # are comments

llama2:7b
mistral:7b
codellama:7b
EOF
    log_success "Sample file created. Edit it and run this option again."
    log_info "File location: $batch_file"
    pause
    return 0
  fi
  
  log_info "Reading models from: $batch_file"
  echo
  
  local models=()
  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    models+=("$line")
  done < "$batch_file"
  
  if [[ ${#models[@]} -eq 0 ]]; then
    log_error "No models found in batch file"
    pause
    return 1
  fi
  
  log_info "Found ${#models[@]} models to download:"
  printf '  - %s\n' "${models[@]}"
  echo
  
  read -p "Download all models? [y/N]: " -r reply
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    log_info "Cancelled"
    pause
    return 0
  fi
  
  if ! command -v ollama &>/dev/null; then
    log_error "Ollama is not installed"
    pause
    return 1
  fi
  
  local success=0
  local failed=0
  
  for model in "${models[@]}"; do
    log_info "Downloading: $model"
    if ollama pull "$model"; then
      ((success++))
      log_success "Downloaded: $model"
    else
      ((failed++))
      log_error "Failed: $model"
    fi
    echo
  done
  
  echo "==========================================================="
  log_info "Batch download complete: $success succeeded, $failed failed"
  echo
  
  # Offer to start monitoring
  if [[ $success -gt 0 ]]; then
    read -p "View downloaded models? [y/N]: " -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      echo
      ollama list
      echo
    fi
  fi
  
  pause
}

monitor_batch_download() {
  show_banner
  log_step "Batch Download Monitor"
  echo
  
  local monitor_script="${PROJECT_ROOT}/scripts/monitor_download.sh"
  
  if [[ ! -f "$monitor_script" ]]; then
    log_error "Monitor script not found: $monitor_script"
    log_info "Run 'Initialize Project' to create utility scripts"
    pause
    return 1
  fi
  
  log_info "Starting download monitor..."
  log_info "This will refresh every 10 seconds"
  log_info "Press Ctrl+C to exit (downloads will continue)"
  echo
  read -p "Press Enter to start monitor..." -r
  
  # Run the monitor script
  bash "$monitor_script"
  
  # When user exits monitor, return to menu
  echo
  log_info "Monitor stopped"
  pause
}

benchmark_model() {
  show_banner
  log_step "Model Performance Benchmark"
  echo
  
  if ! command -v ollama &>/dev/null; then
    log_error "Ollama is not installed"
    pause
    return 1
  fi
  
  log_info "Available models:"
  ollama list
  echo
  
  read -p "Enter model name to benchmark: " -r model_name
  if [[ -z "$model_name" ]]; then
    log_error "No model name provided"
    pause
    return 1
  fi
  
  log_info "Benchmarking $model_name..."
  echo
  
  local test_prompts=(
    "Write a short poem about AI"
    "Explain quantum computing in one sentence"
    "What is 25 * 37?"
  )
  
  local total_time=0
  local test_count=0
  
  for prompt in "${test_prompts[@]}"; do
    ((test_count++))
    log_info "Test $test_count: $prompt"
    
    local start_time
    start_time=$(date +%s.%N)
    
    local response
    response=$(echo "$prompt" | ollama run "$model_name" --verbose 2>&1)
    
    local end_time
    end_time=$(date +%s.%N)
    
    local duration
    duration=$(echo "$end_time - $start_time" | bc)
    total_time=$(echo "$total_time + $duration" | bc)
    
    echo "Response: ${response:0:100}..."
    log_info "Time: ${duration}s"
    echo
  done
  
  local avg_time
  avg_time=$(echo "scale=2; $total_time / $test_count" | bc)
  
  echo "==========================================================="
  log_success "Benchmark Results for $model_name:"
  echo "  Total tests: $test_count"
  echo "  Total time: ${total_time}s"
  echo "  Average time: ${avg_time}s"
  echo "==========================================================="
  
  pause
}

compare_models() {
  show_banner
  log_step "Model Comparison Tool"
  echo
  
  if ! command -v ollama &>/dev/null; then
    log_error "Ollama is not installed"
    pause
    return 1
  fi
  
  log_info "Available models:"
  ollama list
  echo
  
  read -p "Enter first model name: " -r model1
  read -p "Enter second model name: " -r model2
  
  if [[ -z "$model1" || -z "$model2" ]]; then
    log_error "Both model names required"
    pause
    return 1
  fi
  
  read -p "Enter test prompt: " -r prompt
  if [[ -z "$prompt" ]]; then
    prompt="Explain artificial intelligence in one paragraph"
  fi
  
  log_info "Comparing models with prompt: $prompt"
  echo
  
  # Model 1
  echo "==========================================================="
  log_info "Model 1: $model1"
  echo "─────────────────────────────────────────────────────────"
  local start1
  start1=$(date +%s.%N)
  echo "$prompt" | ollama run "$model1"
  local end1
  end1=$(date +%s.%N)
  local time1
  time1=$(echo "$end1 - $start1" | bc)
  echo
  
  # Model 2
  echo "==========================================================="
  log_info "Model 2: $model2"
  echo "─────────────────────────────────────────────────────────"
  local start2
  start2=$(date +%s.%N)
  echo "$prompt" | ollama run "$model2"
  local end2
  end2=$(date +%s.%N)
  local time2
  time2=$(echo "$end2 - $start2" | bc)
  echo
  
  # Summary
  echo "==========================================================="
  log_success "Comparison Summary:"
  echo "  $model1: ${time1}s"
  echo "  $model2: ${time2}s"
  
  if (( $(echo "$time1 < $time2" | bc -l) )); then
    echo "  Winner: $model1 (faster)"
  else
    echo "  Winner: $model2 (faster)"
  fi
  echo "==========================================================="
  
  pause
}

recommend_models() {
  show_banner
  log_step "Model Recommendations"
  echo
  
  log_info "Analyzing system resources..."
  echo
  
  # Get system info
  local total_ram_gb
  total_ram_gb=$(free -g | awk '/^Mem:/{print $2}')
  
  local cpu_cores
  cpu_cores=$(nproc 2>/dev/null || echo 1)
  
  local available_disk_gb
  available_disk_gb=$(df -BG "${PROJECT_ROOT}" | awk 'NR==2{print $4}' | sed 's/G//')
  
  echo "System Specifications:"
  echo "  RAM: ${total_ram_gb}GB"
  echo "  CPU Cores: ${cpu_cores}"
  echo "  Available Disk: ${available_disk_gb}GB"
  echo
  echo "==========================================================="
  echo "Recommended Models:"
  echo "==========================================================="
  echo
  
  # Recommendations based on RAM
  if [[ $total_ram_gb -lt 4 ]]; then
    log_warn "Low RAM detected (${total_ram_gb}GB)"
    echo "Recommended:"
    echo "  OK TinyLlama 1.1B (1GB RAM)"
    echo "  OK Phi-2 2.7B (2GB RAM)"
    echo "  OK Orca Mini 3B (2GB RAM)"
  elif [[ $total_ram_gb -lt 8 ]]; then
    log_info "Moderate RAM (${total_ram_gb}GB)"
    echo "Recommended:"
    echo "  OK Llama 2 7B (4GB RAM)"
    echo "  OK Mistral 7B (4GB RAM)"
    echo "  OK CodeLlama 7B (4GB RAM)"
    echo "  OK Neural Chat 7B (4GB RAM)"
    echo "  OK Vicuna 7B (4GB RAM)"
  elif [[ $total_ram_gb -lt 16 ]]; then
    log_success "Good RAM (${total_ram_gb}GB)"
    echo "Recommended:"
    echo "  OK Llama 2 13B (8GB RAM)"
    echo "  OK All 7B models"
    echo "  OK LLaVA 7B (vision, 5GB RAM)"
  else
    log_success "Excellent RAM (${total_ram_gb}GB)"
    echo "Recommended:"
    echo "  OK Mixtral 8x7B (24GB RAM) - Best quality"
    echo "  OK Llama 2 13B (8GB RAM)"
    echo "  OK All smaller models"
    echo "  OK Multiple models simultaneously"
  fi
  
  echo
  echo "==========================================================="
  
  pause
}

remove_model_files() {
  show_banner
  log_step "Remove Model Files"
  echo
  
  local models_dir="${PROJECT_ROOT}/data/models"
  
  if [[ ! -d "$models_dir" ]] || [[ -z "$(ls -A "$models_dir")" ]]; then
    log_warn "No models found"
    pause
    return 0
  fi
  
  log_info "Available models:"
  ls -1 "$models_dir"
  echo
  
  read -p "Enter model directory name to remove: " -r model_name
  if [[ -z "$model_name" ]]; then
    log_error "No model name provided"
    pause
    return 1
  fi
  
  if [[ -d "${models_dir}/${model_name}" ]]; then
    read -p "Remove ${model_name}? [y/N]: " -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      rm -rf "${models_dir}/${model_name}"
      log_success "Model removed: $model_name"
    else
      log_info "Cancelled"
    fi
  else
    log_error "Model not found: $model_name"
  fi
  
  pause
}

# ============================================================================
# TRAINING DATA FUNCTIONS
# ============================================================================

crawl_training_data() {
  show_banner
  log_step "Training Data Crawler"
  echo
  
  if [[ ! -f "${PROJECT_ROOT}/scripts/url_crawler.py" ]]; then
    log_error "url_crawler.py not found. Please run 'Initialize Project' first."
    pause
    return 1
  fi
  
  read -p "Enter URL to crawl: " -r url
  if [[ -z "$url" ]]; then
    log_error "No URL provided"
    pause
    return 1
  fi
  
  read -p "Enter crawl depth (default: 3): " -r depth
  depth="${depth:-3}"
  
  log_info "Crawling $url with depth $depth..."
  cd "${PROJECT_ROOT}/data/training"
  python3 "${PROJECT_ROOT}/scripts/url_crawler.py" "$url" --depth "$depth"
  cd "$PROJECT_ROOT"
  
  log_success "Crawling complete. Files saved to: ${PROJECT_ROOT}/data/training/"
  pause
}

crawl_single_url() {
  crawl_training_data
}

crawl_multiple_urls() {
  show_banner
  log_step "Crawl Multiple URLs"
  echo
  log_warn "Feature not yet implemented"
  log_info "For now, crawl URLs one at a time from the main crawler"
  pause
}

set_crawl_depth() {
  show_banner
  log_step "Set Crawl Depth"
  echo
  log_info "Crawl depth is set per-crawl when using the crawler"
  pause
}

view_crawled_data_files() {
  show_banner
  log_step "Crawled Data Files"
  echo
  
  local training_dir="${PROJECT_ROOT}/data/training"
  
  if [[ ! -d "$training_dir" ]] || [[ -z "$(ls -A "$training_dir")" ]]; then
    log_warn "No training data found"
  else
    log_info "Training data files:"
    echo
    ls -lh "$training_dir"
  fi
  
  pause
}

remove_crawled_data_files() {
  show_banner
  log_step "Remove Crawled Data"
  echo
  
  local training_dir="${PROJECT_ROOT}/data/training"
  
  if [[ ! -d "$training_dir" ]] || [[ -z "$(ls -A "$training_dir")" ]]; then
    log_warn "No training data found"
    pause
    return 0
  fi
  
  read -p "Remove all training data files? [y/N]: " -r reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    rm -f "${training_dir}"/*
    log_success "Training data removed"
  else
    log_info "Cancelled"
  fi
  
  pause
}

# ============================================================================
# MAINTENANCE FUNCTIONS
# ============================================================================

view_system_logs() {
  show_banner
  log_step "System Logs"
  echo
  
  if [[ -d "$LOG_DIR" ]] && [[ -n "$(ls -A "$LOG_DIR" 2>/dev/null)" ]]; then
    log_info "Recent log files:"
    ls -lht "$LOG_DIR" | head -10
    echo
    read -p "View latest log? [y/N]: " -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      local latest_log
      latest_log=$(ls -t "$LOG_DIR"/ollamatrauma_*.log 2>/dev/null | head -1)
      if [[ -n "$latest_log" ]]; then
        less "$latest_log"
      else
        log_warn "No log files found"
      fi
    fi
  else
    log_warn "No logs found"
  fi
  
  pause
}

view_ai_runner_logs() {
  show_banner
  log_step "AI Runner Logs"
  echo
  
  echo "Select runner to view logs:"
  echo "  1) Ollama (systemd)"
  echo "  2) LocalAI (container)"
  echo "  0) Cancel"
  echo
  read -p "Select [0-2]: " -r choice
  
  case "$choice" in
    1)
      log_info "Ollama service logs:"
      journalctl -u ollama -n 50 --no-pager || log_error "Could not read logs"
      ;;
    2)
      if [[ -n "$CONTAINER_CMD" ]]; then
        log_info "LocalAI container logs:"
        $CONTAINER_CMD logs localai --tail 50 || log_error "Could not read logs"
      else
        log_error "No container runtime available"
      fi
      ;;
    0)
      log_info "Cancelled"
      ;;
    *)
      log_error "Invalid option"
      ;;
  esac
  
  pause
}

backup_project_data() {
  show_banner
  log_step "Backup Project Data"
  echo
  
  local backup_name="ollamatrauma_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
  local backup_path="${BACKUP_DIR}/${backup_name}"
  
  mkdir -p "$BACKUP_DIR"
  
  log_info "Creating backup..."
  tar -czf "$backup_path" \
    --exclude="$BACKUP_DIR" \
    --exclude=".git" \
    --exclude="llama.cpp" \
    --exclude="text-generation-webui" \
    -C "$PROJECT_ROOT" \
    data/ config/ scripts/ 2>/dev/null || true
  
  if [[ -f "$backup_path" ]]; then
    log_success "Backup created: $backup_path"
    ls -lh "$backup_path"
  else
    log_error "Backup failed"
  fi
  
  pause
}

restore_project_data() {
  show_banner
  log_step "Restore Project Data"
  echo
  
  if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
    log_warn "No backups found"
    pause
    return 0
  fi
  
  log_info "Available backups:"
  ls -lht "$BACKUP_DIR"
  echo
  
  read -p "Enter backup filename to restore: " -r backup_file
  if [[ -z "$backup_file" ]]; then
    log_error "No filename provided"
    pause
    return 1
  fi
  
  local backup_path="${BACKUP_DIR}/${backup_file}"
  if [[ ! -f "$backup_path" ]]; then
    log_error "Backup not found: $backup_file"
    pause
    return 1
  fi
  
  read -p "Restore from $backup_file? This will overwrite current data. [y/N]: " -r reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    log_info "Restoring backup..."
    tar -xzf "$backup_path" -C "$PROJECT_ROOT"
    log_success "Backup restored"
  else
    log_info "Cancelled"
  fi
  
  pause
}

cleanup_unused_files() {
  show_banner
  log_step "Cleanup Unused Files"
  echo
  
  log_info "This will remove:"
  echo "  - Old log files (>30 days)"
  echo "  - Temporary files"
  echo
  
  read -p "Continue? [y/N]: " -r reply
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    log_info "Cancelled"
    pause
    return 0
  fi
  
  # Remove old logs
  if [[ -d "$LOG_DIR" ]]; then
    log_info "Removing old log files..."
    find "$LOG_DIR" -name "*.log" -mtime +30 -delete 2>/dev/null || true
  fi
  
  # Remove old backups
  if [[ -d "$BACKUP_DIR" ]]; then
    log_info "Removing old backups (>60 days)..."
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +60 -delete 2>/dev/null || true
  fi
  
  log_success "Cleanup complete"
  pause
}

# ============================================================================
# SETUP & CONFIGURATION SUBMENU
# ============================================================================

setup_menu() {
  while true; do
    show_banner
    echo "Setup & Configuration"
    echo "==========================================================="
    echo
    echo "  1) Initialize Project (first-time setup + Podman)"
    echo "  2) Check Dependencies"
    echo "  3) Install Missing Dependencies"
    echo "  4) Configure Rootless Podman"
    echo "  0) Back to Main Menu"
    echo
    read -p "Select option [0-4]: " -r choice

    case "$choice" in
      1) run_menu_action initialize_project ;;
      2) run_menu_action check_dependencies ;;
      3) 
        run_menu_action_with_pause install_system_dependencies
        run_menu_action install_python_packages && pause
        ;;
      4) run_menu_action setup_rootless_podman ;;
      0) return 0 ;;
      *) log_error "Invalid option" && sleep 1 ;;
    esac
  done
}

# ============================================================================
# AI RUNNERS MANAGEMENT SUBMENU
# ============================================================================

ai_runners_menu() {
  while true; do
    show_banner
    echo "AI Runners Management"
    echo "==========================================================="
    echo
    echo "  Installation:"
    echo "    1) Install Ollama"
    echo "    2) Install LocalAI"
    echo "    3) Install llama.cpp"
    echo "    4) Install text-generation-webui"
    echo
    echo "  Operation:"
    echo "    5) Start AI Runner"
    echo "    6) Stop AI Runner"
    echo "    7) Quick Run (Auto-detect & Start)"
    echo
    echo "  Management:"
    echo "    8) Check Installed Runners"
    echo "    9) Uninstall AI Component"
    echo
    echo "  0) Back to Main Menu"
    echo
    read -p "Select option [0-9]: " -r choice

    case "$choice" in
      1) run_menu_action install_ollama ;;
      2) run_menu_action install_localai ;;
      3) run_menu_action install_llamacpp ;;
      4) run_menu_action install_textgen_webui ;;
      5) run_menu_action start_runner ;;
      6) run_menu_action stop_runner ;;
      7) run_menu_action quick_run ;;
      8) run_menu_action check_installed_runners ;;
      9) run_menu_action uninstall_submenu ;;
      0) return 0 ;;
      *) log_error "Invalid option" && sleep 1 ;;
    esac
  done
}

# ============================================================================
# MODEL MANAGEMENT SUBMENU
# ============================================================================

models_menu() {
  while true; do
    show_banner
    echo "Model Management"
    echo "==========================================================="
    echo
    echo "  Download & Setup:"
    echo "    1) Interactive Model Selector (Popular Models)"
    echo "    2) Download Model from Hugging Face"
    echo "    3) Batch Download Setup Helper"
    echo "    4) Batch Download Models"
    echo "    5) Monitor Download Progress"
    echo
    echo "  Model Operations:"
    echo "    6) List Available Models"
    echo "    7) Convert Model to Ollama Format"
    echo "    8) Remove Model Files"
    echo
    echo "  Analysis & Optimization:"
    echo "    9) Model Performance Benchmark"
    echo "    10) Model Comparison Tool"
    echo "    11) Get Model Recommendations"
    echo
    echo "  0) Back to Main Menu"
    echo
    read -p "Select option [0-11]: " -r choice

    case "$choice" in
      1) run_menu_action interactive_model_selector ;;
      2) run_menu_action download_model_huggingface ;;
      3) run_menu_action setup_batch_download_helper ;;
      4) run_menu_action batch_download_models ;;
      5) run_menu_action monitor_batch_download ;;
      6) run_menu_action list_available_models ;;
      7) run_menu_action convert_model_ollama ;;
      8) run_menu_action remove_model_files ;;
      9) run_menu_action benchmark_model ;;
      10) run_menu_action compare_models ;;
      11) run_menu_action recommend_models ;;
      0) return 0 ;;
      *) log_error "Invalid option" && sleep 1 ;;
    esac
  done
}

# ============================================================================
# TRAINING DATA CRAWLER SUBMENU
# ============================================================================

crawler_menu() {
  while true; do
    show_banner
    echo "Training Data Crawler"
    echo "==========================================================="
    echo
    echo "  1) Crawl Single URL"
    echo "  2) Crawl Multiple URLs from File"
    echo "  3) Set Crawl Depth"
    echo "  4) View Crawled Data Files"
    echo "  5) Remove Crawled Data Files"
    echo "  0) Back to Main Menu"
    echo
    read -p "Select option [0-5]: " -r choice

    case "$choice" in
      1) run_menu_action crawl_single_url ;;
      2) run_menu_action crawl_multiple_urls ;;
      3) run_menu_action set_crawl_depth ;;
      4) run_menu_action view_crawled_data_files ;;
      5) run_menu_action remove_crawled_data_files ;;
      0) return 0 ;;
      *) log_error "Invalid option" && sleep 1 ;;
    esac
  done
}

# ============================================================================
# MAINTENANCE & LOGS SUBMENU
# ============================================================================

maintenance_menu() {
  while true; do
    show_banner
    echo "Maintenance & Logs"
    echo "==========================================================="
    echo
    echo "  1) View System Logs"
    echo "  2) View AI Runner Logs"
    echo "  3) Backup Project Data"
    echo "  4) Restore Project Data"
    echo "  5) Cleanup Unused Files"
    echo "  6) Export Settings"
    echo "  7) Import Settings"
    echo "  0) Back to Main Menu"
    echo
    read -p "Select option [0-7]: " -r choice

    case "$choice" in
      1) run_menu_action view_system_logs ;;
      2) run_menu_action view_ai_runner_logs ;;
      3) run_menu_action backup_project_data ;;
      4) run_menu_action restore_project_data ;;
      5) run_menu_action cleanup_unused_files ;;
      6) run_menu_action export_settings ;;
      7) run_menu_action import_settings ;;
      0) return 0 ;;
      *) log_error "Invalid option" && sleep 1 ;;
    esac
  done
}

# ============================================================================
# UNINSTALL SUBMENU
# ============================================================================

config_profiles_menu() {
  while true; do
    show_banner
    echo "Configuration Profiles"
    echo "==========================================================="
    echo
    echo "  1) Save Current Profile"
    echo "  2) Load Profile"
    echo "  3) List All Profiles"
    echo "  4) Delete Profile"
    echo "  0) Back to Main Menu"
    echo
    read -p "Select option [0-4]: " -r choice

    case "$choice" in
      1) run_menu_action save_config_profile ;;
      2) run_menu_action load_config_profile ;;
      3) run_menu_action list_config_profiles ;;
      4) run_menu_action delete_config_profile ;;
      0) return 0 ;;
      *) log_error "Invalid option" && sleep 1 ;;
    esac
  done
}

uninstall_submenu() {
  while true; do
    show_banner
    echo "Uninstall Components"
    echo "==========================================================="
    echo
    echo "  1) Uninstall Ollama"
    echo "  2) Uninstall LocalAI"
    echo "  3) Uninstall llama.cpp"
    echo "  4) Uninstall text-generation-webui"
    echo "  0) Back to AI Runners Management"
    echo
    read -p "Select option [0-4]: " -r choice

    case "$choice" in
      1) run_menu_action uninstall_ollama ;;
      2) run_menu_action uninstall_localai ;;
      3) run_menu_action uninstall_llamacpp ;;
      4) run_menu_action uninstall_textgen_webui ;;
      0) return 0 ;;
      *) log_error "Invalid option" && sleep 1 ;;
    esac
  done
}

# ============================================================================
# QUICK RUN
# ============================================================================

quick_run() {
  show_banner
  log_step "Quick Run (Auto-detect)..."
  echo
  
  # Detect and run installed AI runner
  if command -v ollama &>/dev/null; then
    log_info "Ollama detected"
    echo
    read -p "Run default model with Ollama? [y/N]: " -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      log_step "Running model with Ollama..."
      ollama run default || log_error "Ollama run failed"
      return
    fi
  fi
  
  if command -v localai &>/dev/null; then
    log_info "LocalAI detected"
    echo
    read -p "Run default model with LocalAI? [y/N]: " -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      log_step "Running model with LocalAI..."
      localai run default || log_error "LocalAI run failed"
      return
    fi
  fi
  
  if command -v docker &>/dev/null; then
    log_info "Docker detected"
    echo
    read -p "Run default container with Docker? [y/N]: " -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      log_step "Running container with Docker..."
      docker run --rm -it default || log_error "Docker run failed"
      return
    fi
  fi
  
  if command -v podman &>/dev/null; then
    log_info "Podman detected"
    echo
    read -p "Run default container with Podman? [y/N]: " -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      log_step "Running container with Podman..."
      podman run --rm -it default || log_error "Podman run failed"
      return
    fi
  fi
  
  log_warn "No compatible AI runner or container found"
  echo "Please install Ollama, LocalAI, Docker, or Podman"
  echo "Then, configure the runner in settings"
  pause
}

# ============================================================================
# CONTAINER RUNTIME SETUP
# ============================================================================

setup_container_runtime() {
  show_banner
  echo "Container Runtime Setup"
  echo "==========================================================="
  echo
  if [[ -n "$CONTAINER_CMD" ]]; then
    log_info "Current runtime: $CONTAINER_CMD"
    echo
  else
    log_warn "No container runtime detected"
    echo
  fi
  echo "Available options:"
  echo "  1) Install/Setup Podman"
  echo "  2) Fix Podman User Namespaces"
  echo "  3) Install/Setup Docker"
  echo "  4) Test Container Runtime"
  echo "  5) Reset Podman Configuration"
  echo "  0) Back"
  echo
  read -p "Select option [0-5]: " -r choice
  case "$choice" in
    1)
      # Install/Setup Podman
      if ! command -v podman &>/dev/null; then
        log_info "Installing Podman..."
        case "$PACKAGE_MANAGER" in
          dnf|yum)
            sudo "$PACKAGE_MANAGER" install -y podman
            ;;
          apt)
            sudo apt update && sudo apt install -y podman
            ;;
          brew)
            brew install podman
            ;;
          *)
            log_error "Unsupported package manager"
            pause
            return 1
            ;;
        esac
      fi
      log_success "Podman installed"
      run_menu_action setup_rootless_podman
      ;;
    2)
      # Fix Podman User Namespaces
      log_step "Fixing Podman User Namespace Configuration..."
      echo
      if ! command -v podman &>/dev/null; then
        log_error "Podman is not installed"
        pause
        return 1
      fi
      # Check subuid/subgid
      if ! grep -q "^${USER}:" /etc/subuid 2>/dev/null; then
        log_info "Adding subuid mapping..."
        sudo usermod --add-subuids 100000-165535 "$USER"
      fi
      if ! grep -q "^${USER}:" /etc/subgid 2>/dev/null; then
        log_info "Adding subgid mapping..."
        sudo usermod --add-subgids 100000-165535 "$USER"
      fi
      # Fix permissions
      sudo chmod u+s /usr/bin/newuidmap /usr/bin/newgidmap 2>/dev/null || true
      # Enable lingering
      sudo loginctl enable-linger "$USER" 2>/dev/null || true
      # Restart podman socket
      systemctl --user stop podman.socket 2>/dev/null || true
      systemctl --user disable podman.socket 2>/dev/null || true
      systemctl --user enable --now podman.socket 2>/dev/null || true
      log_success "Podman user namespace configuration fixed."
      echo
      log_info "You may need to logout and login again for changes to take effect."
      pause
      ;;
    3)
      # Install/Setup Docker
      if ! command -v docker &>/dev/null; then
        log_info "Installing Docker..."
        case "$PACKAGE_MANAGER" in
          dnf|yum)
            sudo "$PACKAGE_MANAGER" install -y docker
            ;;
          apt)
            curl -fsSL https://get.docker.com | sh
            ;;
          brew)
            log_warn "On macOS, install Docker Desktop manually"
            log_info "Download from: https://www.docker.com/products/docker-desktop"
            pause
            return 0
            ;;
          *)
            log_error "Unsupported package manager"
            pause
            return 1
            ;;
        esac
      fi
      sudo systemctl enable --now docker
      sudo usermod -aG docker "$USER"
      log_success "Docker installed and user added to docker group."
      log_info "You may need to logout and login again for group changes to take effect."
      pause
      ;;
    4)
      # Test Container Runtime
      if [[ -z "$CONTAINER_CMD" ]]; then
        log_error "No container runtime detected"
        pause
        return 1
      fi
      log_info "Testing $CONTAINER_CMD..."
      $CONTAINER_CMD --version || log_error "$CONTAINER_CMD --version failed"
      $CONTAINER_CMD info || log_error "$CONTAINER_CMD info failed"
      $CONTAINER_CMD run --rm hello-world || log_error "$CONTAINER_CMD run --rm hello-world failed"
      pause
      ;;
    5)
      # Reset Podman Configuration
      log_step "Resetting Podman Configuration..."
      systemctl --user stop podman.socket 2>/dev/null || true
      systemctl --user stop podman.service 2>/dev/null || true
      systemctl --user disable podman.socket 2>/dev/null || true
      sudo loginctl enable-linger "$USER" 2>/dev/null || true
      export XDG_RUNTIME_DIR="/run/user/$(id -u)"
      systemctl --user enable --now podman.socket 2>/dev/null || true
      log_success "Podman socket reset and restarted"
      pause
      ;;
    0) return 0 ;;
    *) log_error "Invalid option" && sleep 1 ;;
  esac
}

# ============================================================================
# MENU ACTIONS HELPER FUNCTIONS (REFACTORED)
# ============================================================================

# Only one definition needed!
run_menu_action() {
  "$@" || log_error "Action '$*' failed"
}

# For menu actions that should always pause after running
run_menu_action_with_pause() {
  run_menu_action "$@"
  pause
}

# Helper to ensure Podman rootless setup is correct and socket is running
ensure_podman_rootless_ready() {
  # Enable user lingering
  if ! loginctl show-user "$USER" 2>/dev/null | grep -q "Linger=yes"; then
    log_info "Enabling user lingering..."
    sudo loginctl enable-linger "$USER" 2>/dev/null || log_warn "Could not enable lingering"
  fi
  # Enable and start podman socket
  if ! systemctl --user is-active --quiet podman.socket 2>/dev/null; then
    log_info "Enabling Podman socket..."
    systemctl --user enable --now podman.socket 2>/dev/null || log_warn "Could not enable Podman socket"
    sleep 2
  fi
}

# Example usage in your Podman setup functions:
ensure_podman_rootless_ready
# ==========================================================================
# MENU ACTIONS HELPER FUNCTION
# ==========================================================================

run_menu_action() {
  "$@" || log_error "Action '$*' failed"
}

# MAIN MENU
# ============================================================================

main_menu() {
  while true; do
    show_banner
    echo "Main Menu"
    echo "==========================================================="
    echo
    echo "  1) Setup & Configuration"
    echo "  2) AI Runners Management"
    echo "  3) Model Management"
    echo "  4) Training Data Crawler"
    echo "  5) Maintenance & Logs"
    echo "  6) Health Check Dashboard"
    echo "  7) Chat Interface"
    echo "  8) Configuration Profiles"
    echo "  9) Quick Run (Auto-detect)"
    echo "  0) Exit"
    echo
    read -p "Select option [0-9]: " -r choice

    case "$choice" in
      1) run_menu_action setup_menu ;;
      2) run_menu_action ai_runners_menu ;;
      3) run_menu_action models_menu ;;
      4) run_menu_action crawl_training_data ;;
      5) run_menu_action maintenance_menu ;;
      6) run_menu_action health_check_dashboard ;;
      7) run_menu_action chat_interface ;;
      8) run_menu_action config_profiles_menu ;;
      9) run_menu_action quick_run ;;
      0)
        clear_screen
        log_success "Thank you for using OllamaTrauma v2!"
        return 0
        ;;
      *)
        log_error "Invalid option"
        sleep 1
        ;;
    esac
  done
}

# ============================================================================
# SCRIPT START
# ============================================================================

# Parse command line arguments
case "${1:-}" in
  --debug)
    export DEBUG=1
    debug_mode
    exit 0
    ;;
  --help|-h)
    echo "================================================================="
    echo "  OllamaTrauma v2.1.0 - AI Runner Manager"
    echo "================================================================="
    echo
    echo "Usage: $0 [OPTION]"
    echo
    echo "Options:"
    echo "  --debug       Run comprehensive debug mode to test all functions"
    echo "  --help, -h    Show this help message"
    echo
    echo "Run without options for interactive menu."
    echo
    exit 0
    ;;
esac

# Ensure log directory exists
mkdir -p "$LOG_DIR" 2>/dev/null || {
  echo "[WARN] Could not create log directory: $LOG_DIR"
  echo "[WARN] Logs will not be saved"
}

log_info "Starting OllamaTrauma v2.1.0"

# Check critical dependencies first (before anything else)
if ! check_all_dependencies; then
  log_error "Critical dependencies missing. Please install required packages."
  exit 1
fi

# Detect OS and package manager
detect_os

# Acquire lock (non-fatal if it fails)
acquire_lock

# Detect container runtime (Podman preferred)
detect_container_runtime

# Show main menu
main_menu

# Release lock
release_lock
