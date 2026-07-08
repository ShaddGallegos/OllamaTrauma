#!/usr/bin/env bash
# Lightweight MCP server daemon: watches the MCP contexts directory and logs activity.
# Starts as a background process and writes a PID file under mcp/

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="${PROJECT_ROOT}/mcp/mcp_server.pid"
LOG_DIR="${PROJECT_ROOT}/log"
LOG_FILE="${LOG_DIR}/mcp_server.log"

ensure_dirs() {
  mkdir -p "${PROJECT_ROOT}/mcp/contexts"
  mkdir -p "${LOG_DIR}"
}

daemon_loop() {
  ensure_dirs
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) MCP server starting" >> "$LOG_FILE"
  # Simple poll loop. Use inotifywait if available for efficiency.
  if command -v inotifywait >/dev/null 2>&1; then
    # Watch for changes and log them
    while inotifywait -q -e create,modify,delete -r "${PROJECT_ROOT}/mcp/contexts" >/dev/null 2>&1; do
      echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) MCP change detected" >> "$LOG_FILE"
    done
  else
    while true; do
      # Log presence of runner-request if present
      if [[ -f "${PROJECT_ROOT}/mcp/contexts/runner-request.json" ]]; then
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) MCP: runner-request present" >> "$LOG_FILE"
      fi
      sleep 2
    done
  fi
}

is_running() {
  if [[ -f "$PID_FILE" ]]; then
    pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
    if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
      return 0
    fi
  fi
  return 1
}

cmd_start() {
  if is_running; then
    echo "MCP server already running (pid: $(cat "$PID_FILE") )"
    return 0
  fi
  ensure_dirs
  # Start the same script in background with a special flag so the daemon_loop function runs in that process
  nohup bash "${BASH_SOURCE[0]}" --run-daemon >>"$LOG_FILE" 2>&1 &
  echo $! >"$PID_FILE"
  echo "MCP server started (pid $(cat "$PID_FILE"))"
}

cmd_stop() {
  if ! is_running; then
    echo "MCP server not running"
    return 0
  fi
  pid=$(cat "$PID_FILE")
  kill "$pid" >/dev/null 2>&1 || true
  rm -f "$PID_FILE"
  echo "MCP server stopped"
}

cmd_status() {
  if is_running; then
    echo "running: pid $(cat "$PID_FILE")"
  else
    echo "stopped"
  fi
}

case "${1:-}" in
  start)
    cmd_start
    ;;
  --run-daemon)
    daemon_loop
    ;;
  stop)
    cmd_stop
    ;;
  status)
    cmd_status
    ;;
  *)
    echo "Usage: $0 {start|stop|status}"
    exit 2
    ;;
esac
