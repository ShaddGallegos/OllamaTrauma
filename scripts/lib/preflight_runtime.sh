#!/usr/bin/env bash
# Shared preflight and shutdown helpers for OllamaTrauma.

# Lightweight preflight checks to improve UX before running heavy flows.
preflight_checks() {
  local missing=()
  local req=(bash curl awk sed python3)
  for cmd in "${req[@]}"; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      missing+=("${cmd}")
    fi
  done

  suggest_install_commands() {
    local missing_pkgs=("$@")
    local os_id=""
    if [[ -r /etc/os-release ]]; then
      os_id=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
    fi

    local install_cmd=""
    local pkg_list=()
    for m in "${missing_pkgs[@]}"; do
      case "${m}" in
        curl) pkg_list+=(curl) ;;
        python3) pkg_list+=(python3) ;;
        awk) pkg_list+=(gawk) ;;
        sed) pkg_list+=(sed) ;;
        bash) pkg_list+=(bash) ;;
        *) pkg_list+=("${m}") ;;
      esac
    done

    case "${os_id}" in
      ubuntu|debian)
        install_cmd="sudo apt-get update && sudo apt-get install -y ${pkg_list[*]}"
        ;;
      fedora|centos|rhel)
        install_cmd="sudo dnf install -y ${pkg_list[*]}"
        ;;
      arch)
        install_cmd="sudo pacman -Syu --noconfirm ${pkg_list[*]}"
        ;;
      *)
        install_cmd="(use your OS package manager) install: ${pkg_list[*]}"
        ;;
    esac

    printf '%b\n' "${YELLOW}Suggested install command:${NC}"
    printf '%s\n\n' "${install_cmd}"

    PRECHECK_AUTO_INSTALL=${PRECHECK_AUTO_INSTALL:-0}
    if [[ "${PRECHECK_AUTO_INSTALL}" == "1" ]]; then
      read -r -p "Run suggested install now? [y/N]: " _ans
      if [[ "${_ans}" =~ ^[Yy]$ ]]; then
        eval "${install_cmd}"
      fi
    else
      printf '%b\n' "Run with PRECHECK_AUTO_INSTALL=1 to offer automated installation."
    fi
  }

  if [[ -z "${LOG_DIR:-}" ]]; then
    LOG_DIR="${PROJECT_ROOT}/data/logs"
  fi
  mkdir -p "${LOG_DIR}" 2>/dev/null || true

  if (( ${#missing[@]} )); then
    printf '\n'
    printf '%b\n' "${YELLOW}Warning: Missing required commands: ${missing[*]}${NC}"
    printf '%b\n' "${YELLOW}Some features may be limited. Install the missing packages and re-run.${NC}"
    printf '\n'
    suggest_install_commands "${missing[@]}"
  fi

  if ! command -v podman >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1; then
    printf '%b\n' "${YELLOW}Warning: No container runtime detected (podman/docker). Container flows may fail.${NC}"
  fi

  if command -v python3 >/dev/null 2>&1; then
    if ! python3 -c "import sys" >/dev/null 2>&1; then
      printf '%b\n' "${YELLOW}Warning: python3 seems unavailable or broken.${NC}"
    fi
  fi
}

# Exit trap to cleanup temporary files and lockfile.
on_exit() {
  local rc=${1:-$?}
  if [[ -n "${LOCK_FILE:-}" ]] && [[ -f "${LOCK_FILE}" ]]; then
    rm -f "${LOCK_FILE}" 2>/dev/null || true
  fi
  if [[ ${rc} -ne 0 ]]; then
    printf '%b\n' "${RED}Exiting with status ${rc}${NC}"
  fi
}

# Ensure we can shutdown any background child processes cleanly before exiting.
shutdown_and_exit() {
  local rc=${1:-0}
  if command -v pkill >/dev/null 2>&1; then
    pkill -P "$$" 2>/dev/null || true
  else
    for p in $(jobs -p 2>/dev/null); do
      kill "$p" 2>/dev/null || true
    done
  fi
  sleep 0.1
  exit "$rc"
}
