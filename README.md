# OllamaTrauma AI Runner and LLM

Unified runner and bootstrap project for local AI workflows with support for:
- Ollama
- llama.cpp
- text-generation-webui

## Synopsis

`OllamaTrauma` provides a shell-first operator interface to install prerequisites, manage runtime services, run health checks, and launch model workflows from a single entrypoint.

## Quick Start

```bash
# 1) Install Python dependencies
pip install -r requirements.txt

# 2) Run the interactive manager
bash OllamaTrauma_v2.sh
```

## Common Commands

```bash
# Interactive mode
bash OllamaTrauma_v2.sh run

# Health/diagnostics mode
bash OllamaTrauma_v2.sh --health

# Batch profile/model workflow
bash OllamaTrauma_v2.sh batch --batch config/models_batch.txt

# Python wrapper entrypoint
python3 OllamaTrauma_v2.py --help
```

## Operations

```bash
# Service helpers
./scripts/mcp_server.sh start
./scripts/mcp_server.sh status
./scripts/mcp_server.sh stop

# Monitoring helpers
./scripts/monitor.sh

# Runtime diagnostics
bash OllamaTrauma_v2.sh --health
```

Operational tips:
- Use `--health` before and after long batch runs to verify runtime state.
- Keep `mcp/*.pid` files out of version control; stale pid files can block restarts.
- Prefer project-local scripts under `scripts/` over external absolute paths.

## Testing

Project tests are scoped to `tests/` and `test/`.

```bash
# Discover tests
pytest --collect-only -q

# Run tests
pytest -q

# Menu harness (CI-safe)
make test-ci

# Full quality check (lint + tests)
make check
```

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `pytest` collects third-party tests or errors on `torch/wget` | External trees being discovered | Use project defaults in `pytest.ini` and run `pytest -q` from repo root |
| Shell lint is skipped | `shellcheck` missing | Install `shellcheck`, then run `make lint-shell` |
| Runner exits on missing commands | Host missing required tools (`bash`, `curl`, `python3`, runtime) | Install dependencies shown by preflight warnings and re-run |
| Services appear up but commands fail | Stale pid file in `mcp/` | Stop service, remove stale pid, restart with `./scripts/mcp_server.sh start` |
| Config generation fallback triggered | No local ansible cfg renderer/template found | Add `scripts/python/generate_ansible_cfg.py` and template or use generated fallback `ansible.cfg` |

## Project Layout

- `OllamaTrauma_v2.sh`: main Bash runner and menu system
- `OllamaTrauma_v2.py`: Python wrapper for shell runner
- `scripts/`: helper scripts and platform automation
- `config/`: batch profiles and runtime config data
- `tests/`, `test/`: project test suites
- `mcp/`: MCP runtime state and contexts

## Dependency Files

- `requirements-runtime.txt`: runtime dependencies
- `requirements-dev.txt`: development/test dependencies
- `requirements.txt`: compatibility umbrella (installs both)

## Notes

- This repository contains large third-party trees. `pytest.ini` is configured to avoid collecting external test suites by default.
- If you run with custom models/artifacts, keep generated outputs under ignored data/log paths.
