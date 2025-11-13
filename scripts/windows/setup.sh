#!/usr/bin/env bash
# Windows (WSL/Git Bash) Setup Script

set -euo pipefail

log_info() { echo -e "\033[0;32m[INFO]\033[0m $*"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $*" >&2; }

log_info "Setting up OllamaTrauma for Windows..."

# Check if running in WSL
if grep -qi microsoft /proc/version 2>/dev/null; then
  log_info "Detected WSL - using Ubuntu/Debian packages"
  
  sudo apt-get update
  sudo apt-get install -y \
    git \
    curl \
    jq \
    python3 \
    python3-pip \
    wget \
    build-essential
  
  # Docker in WSL
  if ! command -v docker &> /dev/null; then
    log_info "Install Docker Desktop for Windows with WSL2 backend"
    log_info "https://docs.docker.com/desktop/windows/wsl/"
  fi
else
  log_info "Git Bash detected - please ensure you have:"
  log_info "  - Git for Windows"
  log_info "  - Python 3.8+"
  log_info "  - Docker Desktop for Windows"
fi

# Install Python packages
log_info "Installing Python packages..."
python3 -m pip install --user --upgrade pip
python3 -m pip install --user -r ../requirements.txt

# Ollama
log_info "Download Ollama for Windows from: https://ollama.com/download/windows"

log_info "✓ Windows setup complete"
