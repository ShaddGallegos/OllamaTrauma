import subprocess
import sys
import shutil
from pathlib import Path
import pytest


def pytest_configure(config):
    # simple marker to allow running interactive tests explicitly
    config.addinivalue_line("markers", "interactive: marks tests that require interactive/prereqs")


def test_runner_harness_ci_ok():
    # Skip if pexpect not available; the harness requires it
    try:
        import pexpect  # noqa: F401
    except Exception:
        pytest.skip("pexpect not installed; skipping interactive runner harness")

    script = Path(__file__).resolve().parent / "test_runner.py"
    assert script.exists(), f"Harness script not found: {script}"

    # Run the harness in CI-safe mode which exits 0 on warnings
    proc = subprocess.run([sys.executable, str(script), "--ci-ok"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120)
    out = proc.stdout.decode(errors="ignore")
    err = proc.stderr.decode(errors="ignore")
    assert proc.returncode == 0, f"Runner harness failed (rc={proc.returncode})\nSTDOUT:\n{out}\nSTDERR:\n{err}"
