# OllamaTrauma_AI_Runner_and_LLM — Checklist

Purpose: Local AI runner and bootstrap project supporting Ollama, llama.cpp, and text-generation-webui workflows.

Prerequisites
- Python 3 and pip
- `podman` or `docker` for containerized components (optional)

Quick start
```bash
cd OllamaTrauma_AI_Runner_and_LLM
# Create requirements.txt if missing (project helper)
# Requirements already generated; install them
pip3 install -r requirements.txt
# Run the interactive manager (bash wrapper)
bash OllamaTrauma_v2.sh
```

Verify
- Run `bash OllamaTrauma_v2.sh --health` to check runtime health
- Ensure `mcp/` folders exist after initial setup

Notes
- The Makefile supports `make deps` and `make deps-runtime` targets.
- Large vendored trees (e.g. `llama.cpp`) exist; be mindful of disk usage.
