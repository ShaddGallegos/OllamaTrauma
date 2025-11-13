#!/usr/bin/env bash
# Fedora Setup Script

set -euo pipefail

log_info() { echo -e "\033[0;32m[INFO]\033[0m $*"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $*" >&2; }

log_info "Setting up OllamaTrauma for Fedora..."

# Install required packages
log_info "Installing required packages..."
sudo dnf install -y \
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
  gcc-c++ \
  podman-docker

# Install Python packages
log_info "Installing Python packages..."
python3 -m pip install --user --upgrade pip
python3 -m pip install --user -r ../requirements.txt

# Install Ollama
if ! command -v ollama &> /dev/null; then
  log_info "Installing Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
fi

log_info "✓ Fedora setup complete"
