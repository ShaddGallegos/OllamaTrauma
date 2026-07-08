#!/usr/bin/env bash
# Shared CLI helper functions for OllamaTrauma.

usage() {
  cat <<EOF
Usage: $0 [options] [subcommand] [args]

Options:
  -h, --help        Show this help message and exit
  -V, --version     Show version and exit
  -v, --verbose     Enable verbose/debug logging
  -y, --yes         Non-interactive yes (auto-yes)
      --health      Start in health/dashboard mode
      --no-color    Disable ANSI colors

Subcommands:
  run               Run the main interactive runner (default)
  download          Download / prepare models and assets
  health            Show health checks and diagnostics
  batch             Run a batch download or automation profile

Examples:
  $0 run --model llama2
  $0 download --batch config/models_batch.txt
  $0 --verbose health

EOF
}

print_header() {
  if [[ -t 1 ]]; then
    cecho CYAN "-----------------------------------------------------------"
    cecho GREEN " ${PROJECT_NAME} ${SCRIPT_VERSION} - AI Runner Manager"
    cecho CYAN " Repository: https://example.invalid (local copy)"
    cecho CYAN "-----------------------------------------------------------"
  fi
}

_cli_info() {
  if type info >/dev/null 2>&1; then
    info "$*"
  else
    printf '%s\n' "$*"
  fi
}

_cli_error() {
  if type log_error >/dev/null 2>&1; then
    log_error "$*"
  else
    printf '%s\n' "ERROR: $*" >&2
  fi
}

parse_args() {
  if command -v getopt >/dev/null 2>&1; then
    local TEMP
    TEMP=$(getopt -o hVvym: -l help,version,verbose,yes,auto-yes,health,no-color,model:,batch: -- "$@") || {
      usage
      return 2
    }
    eval set -- "$TEMP"
    while true; do
      case "$1" in
        -h|--help) usage; exit 0 ;;
        -V|--version) _cli_info "${PROJECT_NAME} ${SCRIPT_VERSION}"; exit 0 ;;
        -v|--verbose) VERBOSE=1; shift ;;
        -y|--yes|--auto-yes) AUTO_YES=1; shift ;;
        --health) HEALTH_MODE=1; shift ;;
        --no-color) NO_COLOR=1; shift ;;
        -m|--model) CLI_MODEL="$2"; shift 2 ;;
        --batch) CLI_BATCH="$2"; shift 2 ;;
        --) shift; break ;;
        *) shift; break ;;
      esac
    done
  else
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -h|--help) usage; exit 0 ;;
        -V|--version) _cli_info "${PROJECT_NAME} ${SCRIPT_VERSION}"; exit 0 ;;
        -v|--verbose) VERBOSE=1; shift ;;
        -y|--yes|--auto-yes) AUTO_YES=1; shift ;;
        --health) HEALTH_MODE=1; shift ;;
        --no-color) NO_COLOR=1; shift ;;
        -m|--model) CLI_MODEL="$2"; shift 2 ;;
        --batch) CLI_BATCH="$2"; shift 2 ;;
        --) shift; break ;;
        -*) _cli_error "Unknown option: $1"; usage; return 2 ;;
        *) break ;;
      esac
    done
  fi

  export AUTO_YES VERBOSE NO_COLOR HEALTH_MODE
}

read_choice() {
  local prompt="$1"
  local _var_name="$2"
  local _allow_global_exit=${3:-0}
  local _input=""
  read -p "$prompt" -r _input
  if [[ "${OT_CI_MODE:-0}" == "1" && "${_input}" == "0" && "${_allow_global_exit}" == "1" ]]; then
    if type log_debug >/dev/null 2>&1; then
      log_debug "CI mode: global-exit requested; returning '0' to caller (no exec)"
    fi
  fi
  if [[ -n "${_var_name}" ]]; then
    printf -v "${_var_name}" '%s' "${_input}"
  else
    choice="${_input}"
  fi
}
