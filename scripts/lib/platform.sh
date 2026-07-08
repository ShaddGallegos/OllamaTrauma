#!/usr/bin/env bash
# Platform detection helpers for OllamaTrauma.

# Detect available GPUs (sets GPU_AVAILABLE=1/0 and GPU_VENDOR).
detect_gpus() {
  GPU_AVAILABLE=0
  GPU_VENDOR=""
  CUDA_AVAILABLE=0

  if command -v nvidia-smi >/dev/null 2>&1; then
    GPU_AVAILABLE=1
    GPU_VENDOR="nvidia"
    log_info "NVIDIA GPU detected (nvidia-smi available)"
  fi

  if [[ ${GPU_AVAILABLE} -ne 1 ]] && command -v rocminfo >/dev/null 2>&1; then
    GPU_AVAILABLE=1
    GPU_VENDOR="amd"
    log_info "AMD GPU detected (rocminfo available)"
  fi

  if [[ ${GPU_AVAILABLE} -ne 1 ]] && command -v clinfo >/dev/null 2>&1; then
    GPU_AVAILABLE=1
    GPU_VENDOR="opencl"
    log_info "OpenCL-capable device detected (clinfo available)"
  fi

  if command -v nvcc >/dev/null 2>&1; then
    CUDA_AVAILABLE=1
    log_info "CUDA toolkit detected (nvcc available)"
  fi

  if [[ ${GPU_AVAILABLE} -ne 1 ]]; then
    log_info "No GPU detected"
  else
    log_info "GPU_AVAILABLE=${GPU_AVAILABLE}, GPU_VENDOR=${GPU_VENDOR}, CUDA_AVAILABLE=${CUDA_AVAILABLE}"
  fi
}

# Detect operating system and package manager.
detect_os() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
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

  case "${OS}" in
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
