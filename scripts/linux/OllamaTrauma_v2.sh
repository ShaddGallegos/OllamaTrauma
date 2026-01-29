#!/usr/bin/env bash
# Minimal Linux wrapper: delegate to repo root `OllamaTrauma_v2.sh`

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$ROOT_DIR/OllamaTrauma_v2.sh" "$@"
