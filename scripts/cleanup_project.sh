#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${ROOT_DIR}/.backups/cleanup_${TS}"

echo "Project root: ${ROOT_DIR}"
mkdir -p "${BACKUP_DIR}"

move_if_exists() {
  local path="$1"
  if [[ -e "${ROOT_DIR}/${path}" ]]; then
    echo "Moving ${path} -> ${BACKUP_DIR}/${path}"
    mkdir -p "${BACKUP_DIR}/$(dirname "${path}")"
    mv "${ROOT_DIR}/${path}" "${BACKUP_DIR}/${path}"
  fi
}

# Non-essential (Ansible and scaffolding) items to move out of project
move_if_exists "ansible.cfg"
move_if_exists "collections"
move_if_exists "templates"
move_if_exists "tests"   # old tests folder; superseded by test/
move_if_exists "generate_ansible_cfg.py"

echo "Cleanup staged to ${BACKUP_DIR}"
echo "Nothing was deleted; review backup and remove if desired."
echo "Done."
