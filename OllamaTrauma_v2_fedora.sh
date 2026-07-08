#!/usr/bin/env bash
set -euo pipefail
# Fedora-specific wrapper for OllamaTrauma_v2
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$PROJECT_ROOT/OllamaTrauma_v2.sh"

echo "OllamaTrauma (Fedora wrapper)"
if [[ ! -f "$SCRIPT" ]]; then
  echo "Main script not found: $SCRIPT"
  exit 2
fi

if ! command -v bash >/dev/null 2>&1; then
  echo "bash not found. Install via: sudo dnf install -y bash"
  exit 2
fi

exec bash "$SCRIPT" "$@"
