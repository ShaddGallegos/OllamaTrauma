#!/usr/bin/env bash
# UI and display utility helpers for OllamaTrauma.

clear_screen() {
  clear 2>/dev/null || printf '\033[2J\033[H'
}

pause() {
  printf '\n'
  # Use centralized read_choice so CI harness behavior is consistent.
  read_choice "Press Enter to continue..." _pause_dummy
}

show_banner() {
  clear_screen
  cat << "EOF"
-----------------------------------------------------------
   ___  _ _                 _____                          
  / _ \| | | __ _ _ __ ___ |_   _| __ __ _ _   _ _ __ ___   __ _
 | | | | | |/ _` | '_ ` _ \  | || '__/ _` | | | | '_ ` _ \ / _` |
 | |_| | | | (_| | | | | | | | || | | (_| | |_| | | | | | | (_| |
  \___/|_|_|\__,_|_| |_| |_| |_||_|  \__,_|\__,_|_| |_| |_|\__,_|
                                                           
           Cross-Platform AI Runner Manager & Bootstrap
-----------------------------------------------------------
EOF
  log_info "  Version: ${SCRIPT_VERSION}"
  log_info "  Project: ${PROJECT_ROOT}"
  if [[ -n "${CONTAINER_CMD:-}" ]]; then
    log_info "  Container: ${CONTAINER_CMD}"
  fi
  log_info "-----------------------------------------------------------"
  printf '\n'
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
