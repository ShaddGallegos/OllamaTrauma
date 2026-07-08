#!/usr/bin/env bash
# Shared runtime utility helpers for OllamaTrauma.

# Debug helpers that write to both debug log and main logs.
debug_log() {
  local msg="$*"
  if [[ -n "${msg}" ]]; then
    if type log_info >/dev/null 2>&1; then
      log_info "$msg"
    else
      echo "$msg" >> "${LOG_FILE:-/dev/null}"
    fi
    if [[ -n "${DEBUG_LOG:-}" ]]; then
      printf '%s\n' "$msg" >> "${DEBUG_LOG}" 2>/dev/null || true
    fi
  fi
}

debug_report() {
  local msg="$*"
  if [[ -n "${msg}" ]]; then
    debug_log "$msg"
    if [[ -n "${DEBUG_REPORT:-}" ]]; then
      printf '%s\n' "$msg" >> "${DEBUG_REPORT}" 2>/dev/null || true
    fi
  fi
}

# CI-safe wrappers for noisy external commands.
# When OT_CI_MODE is enabled, return minimal/stable output to keep pexpect tests deterministic.
safe_ollama_list() {
  if [[ "${OT_CI_MODE:-0}" == "1" ]]; then
    printf '%s\n' "NAME  STATUS"
    return 0
  fi
  if ! command -v ollama >/dev/null 2>&1; then
    return 1
  fi
  ollama list "$@"
}

safe_podman_info() {
  if [[ "${OT_CI_MODE:-0}" == "1" ]]; then
    printf '%s\n' "{\"host\":\"ci-stub\",\"status\":\"ok\"}"
    return 0
  fi
  if ! command -v podman >/dev/null 2>&1; then
    return 1
  fi
  podman info "$@"
}
