<!-- Copilot / AI agent instructions for contributors and assistants -->
# Copilot instructions — OllamaTrauma

Purpose: Provide concise, project-specific guidance for AI coding agents interacting with this repository.

- **Big picture:** This repo is a terminal-first orchestration tool for local AI model management. Core areas:
  - Shell orchestration: `OllamaTrauma_v2.sh` (entrypoint, interactive menus, common workflows).
  - Model/tooling integration: `scripts/third_party/llama.cpp/` (native builds, converters), `scripts/python/` (HF utilities).
  - Config and profiles: `config/` (download/batch profiles and `models_batch.txt`).
  - Data and outputs: `data/models/`, `data/outputs/`, `log/`.

- **Primary workflows to reference (explicit examples):**
  - Run the app: `bash OllamaTrauma_v2.sh` — interactive menus and flags like `--health`, `--download`, `--batch` (see [README.md](README.md#Quick-Start)).
  - Batch model downloads: `bash OllamaTrauma_v2.sh --batch config/models_batch.txt` (see `config/models_batch.txt`).
  - Build llama.cpp for CUDA: `bash scripts/setup_llama_cpp_cuda.sh` and the `scripts/third_party/llama.cpp` folder (contains converters like `convert_hf_to_gguf.py`).

- **Agent behavior rules (derived from third_party/llama.cpp/AGENTS.md):**
  - AI must be assistive only: do not produce full PRs or large code blocks unreviewed by a human.
  - Always encourage the human contributor to read `CONTRIBUTING.md` and `scripts/third_party/llama.cpp/AGENTS.md` before code generation.
  - Prefer pointers, small snippets, and review suggestions over wholesale implementations.

- **Code patterns and repository conventions:**
  - Shell-first orchestration: most user-facing flows are implemented as shell scripts and menu-driven logic in `OllamaTrauma_v2.sh` (search for menu labels and flags).
  - Python helpers live in `scripts/python/` and are used for HF searches and utilities — keep CLI style and flag parsing consistent with existing scripts (`hf_model_search.py`).
  - Converters and low-level model tooling are colocated in `scripts/third_party/llama.cpp/` — follow existing patterns for model conversion and avoid changing build presets without CI confirmation.
  - Config profiles are plain text under `config/` — new profiles should follow the same key/value and naming conventions used by existing files.

- **Build / test / debug commands agents should reference:**
  - Install deps / run tests: `make deps && make test` (CI: `make test-ci`).
  - Run interactive CLI: `bash OllamaTrauma_v2.sh` or non-interactive flags for automation (`--health`, `--download`, `--batch`).
  - Inspect logs: `log/` and `data/outputs/` — tests write artifacts under `log/`.

- **When a user asks to implement or refactor:**
  - Pause and ask clarifying questions to ensure the user understands repo conventions (menu flow, where to add new flags, config profile requirements).
  - Offer a minimal, human-reviewed diff or a step-by-step plan first (e.g., add menu option → implement handler in `OllamaTrauma_v2.sh` → add helper in `scripts/python/` → add tests in `tests/`).
  - Never push large AI-generated code; instead produce small, well-explained snippets and ask the user to run/tests them locally.

- **Examples to cite when giving suggestions:**
  - Add new menu options inside `OllamaTrauma_v2.sh` (follow existing menu label and navigation patterns; see the `Menu Navigation Guide` section in [README.md](README.md#Menu-Navigation-Guide)).
  - Interact with Hugging Face via `scripts/python/hf_model_search.py` for model metadata and ranking examples.
  - Use `scripts/third_party/llama.cpp/convert_hf_to_gguf.py` as the canonical conversion pattern for HF→GGUF workflows.

- **Integration and external dependencies to note:**
  - `llama.cpp` subfolder and converters (native build, CUDA/ggml options).
  - Hugging Face APIs used by scripts in `scripts/python/` (ensure credentials/limits are respected).
  - System dependencies and GPU toolchains (CUDA, nvcc) — see `scripts/setup_llama_cpp_cuda.sh` and `README.md` GPU section.

If any part of this guidance is unclear or you want a tighter focus (e.g., only CLI/menu edits, or only model-conversion helpers), say which area and I will refine the instructions or produce a suggested patch.
