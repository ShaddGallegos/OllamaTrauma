#!/usr/bin/env bash
set -euo pipefail
# Ubuntu-specific wrapper for OllamaTrauma_v2
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$PROJECT_ROOT/OllamaTrauma_v2.sh"

echo "OllamaTrauma (Ubuntu wrapper)"
if [[ ! -f "$SCRIPT" ]]; then
  echo "Main script not found: $SCRIPT"
  exit 2
fi

if ! command -v bash >/dev/null 2>&1; then
  echo "bash not found. Install via: sudo apt update && sudo apt install -y bash"
  exit 2
fi

exec bash "$SCRIPT" "$@"
