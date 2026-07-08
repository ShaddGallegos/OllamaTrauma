#!/usr/bin/env bash
# Lock lifecycle helpers for OllamaTrauma.

acquire_lock() {
  if [[ -f "${LOCK_FILE}" ]]; then
    local lock_pid
    lock_pid=$(cat "${LOCK_FILE}" 2>/dev/null || echo "")

    if [[ -n "${lock_pid}" ]] && kill -0 "${lock_pid}" 2>/dev/null; then
      log_error "Another instance is running (PID: ${lock_pid})"
      return 1
    fi
  fi

  echo "${SCRIPT_PID}" > "${LOCK_FILE}" || {
    log_error "Failed to create lock file"
    return 1
  }

  log_debug "Lock acquired (PID: ${SCRIPT_PID})"
  return 0
}

release_lock() {
  if [[ -f "${LOCK_FILE}" ]]; then
    local lock_pid
    lock_pid=$(cat "${LOCK_FILE}" 2>/dev/null || echo "")

    if [[ "${lock_pid}" == "${SCRIPT_PID}" ]]; then
      rm -f "${LOCK_FILE}"
      log_debug "Lock released"
    fi
  fi
}

cleanup_on_exit() {
  local exit_code=$?
  release_lock

  if [[ ${exit_code} -ne 0 ]]; then
    log_error "Script exited with code: ${exit_code}"
    [[ -f "${ERROR_LOG}" ]] && log_info "Error log: ${ERROR_LOG}"
  fi
}
