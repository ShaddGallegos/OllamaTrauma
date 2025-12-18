#!/usr/bin/env bash
# RHEL/CentOS Setup Script

set -euo pipefail

log_info() { echo -e "\033[0;32m[INFO]\033[0m $*"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $*" >&2; }

log_info "Setting up OllamaTrauma for RHEL/CentOS..."

# Check RHEL version
if [[ -f /etc/redhat-release ]]; then
  RHEL_VERSION=$(grep -oP '\d+' /etc/redhat-release | head -1)
  log_info "Detected RHEL/CentOS version: $RHEL_VERSION"
else
  log_error "Not a RHEL/CentOS system"
  exit 1
fi

# Install required packages
log_info "Installing required packages..."
sudo yum install -y epel-release || true
sudo yum install -y \
  git \
  curl \
  jq \
  python3 \
  python3-pip \
  wget \
  tar \
  gzip \
  make \
  gcc \
  gcc-c++

# Install Docker if not present
if ! command -v docker &> /dev/null; then
  log_info "Installing Docker..."
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sudo sh /tmp/get-docker.sh
  sudo usermod -aG docker "$USER"
  sudo systemctl enable --now docker
  log_info "Docker installed. You may need to logout/login for group changes."
fi

# Install Python packages
log_info "Installing Python packages..."
python3 -m pip install --user --upgrade pip
python3 -m pip install --user -r ../requirements.txt

# Install Ollama
if ! command -v ollama &> /dev/null; then
  log_info "Installing Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
fi

log_info "✓ RHEL setup complete"
