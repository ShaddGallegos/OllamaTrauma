#!/usr/bin/env bash
# Container runtime detection and setup helpers for OllamaTrauma.

# Podman is preferred for rootless operation.
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

# Determine container GPU flags based on detected runtime.
detect_container_gpu_flags() {
  CONTAINER_GPU_FLAGS_ARRAY=()
  CONTAINER_GPU_ENVS=()
  if [[ -z "${CONTAINER_CMD}" ]]; then
    return 0
  fi

  case "${CONTAINER_CMD}" in
    docker)
      # Docker supports --gpus
      CONTAINER_GPU_FLAGS_ARRAY=(--gpus all)
      ;;
    podman)
      # Podman: prefer passing device nodes and NVIDIA env vars (best-effort)
      CONTAINER_GPU_FLAGS_ARRAY=(--device /dev/nvidiactl --device /dev/nvidia-uvm --device /dev/nvidia0 --security-opt seccomp=unconfined)
      CONTAINER_GPU_ENVS+=("-e" "NVIDIA_VISIBLE_DEVICES=all")
      ;;
    *)
      CONTAINER_GPU_FLAGS_ARRAY=()
      ;;
  esac
}

setup_rootless_podman() {
  local current_user="$USER"
  local user_id
  user_id=$(id -u)

  show_banner
  info "Rootless Podman Setup Wizard"
  step "-----------------------------------------------------------"
  printf '\n'
  log_info "Setting up Podman for user: $current_user (UID: $user_id)"
  printf '\n'

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
  printf '\n'
  log_step "Testing Podman with 'podman info' and 'podman run --rm hello-world'..."
  cecho CYAN "─────────────────────────────────────────────────────────"
  safe_podman_info || log_error "podman info failed"
  cecho CYAN "─────────────────────────────────────────────────────────"
  podman run --rm hello-world || log_error "podman run --rm hello-world failed"
  cecho CYAN "─────────────────────────────────────────────────────────"
  pause
}
