#!/usr/bin/env bash
# Helper: clone and prepare llama.cpp with CUDA/ggml-cuda support
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
third_party="$here/third_party"
mkdir -p "$third_party"

echo "Checking for prerequisites..."
command -v git >/dev/null 2>&1 || { echo "git not found"; exit 1; }

if command -v nvcc >/dev/null 2>&1; then
  nvcc_path="$(command -v nvcc)"
  echo "Found nvcc at: $nvcc_path"
else
  echo "nvcc not found in PATH. If CUDA is installed, ensure /usr/local/cuda/bin is in PATH."
fi

if [ ! -d "$third_party/llama.cpp" ]; then
  echo "Cloning llama.cpp into $third_party/llama.cpp (this may take a minute)..."
  git clone --depth 1 https://github.com/ggerganov/llama.cpp.git "$third_party/llama.cpp"
else
  echo "llama.cpp already exists at $third_party/llama.cpp"
fi

cat <<'EOF'
Next steps (recommended):

1) Build with CUDA/CMake (recommended when nvcc is available):
   cd scripts/third_party/llama.cpp
   mkdir -p build && cd build
   cmake .. -DLLAMA_CUBLAS=ON
   cmake --build . -j$(nproc)

2) Or use the Makefile (older builds):
   cd scripts/third_party/llama.cpp
   make clean && make -j$(nproc) GGML_CUDA=1

3) After building, use the `examples/server` or `examples/quantize` tools from llama.cpp, or integrate the built binary into this project.

Notes:
- Building requires a CUDA toolkit, compatible drivers, and a recent GCC/clang toolchain.
- If you prefer Python-based inference, consider installing vLLM or torch + accelerate instead.
EOF

echo "Created/updated $third_party/llama.cpp and printed build instructions."

exit 0
