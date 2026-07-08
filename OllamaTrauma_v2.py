#!/usr/bin/env python3
"""Python wrapper for OllamaTrauma_v2.
Delegates to the main shell script while providing a native entrypoint.
"""
import os
import sys
import shutil
import subprocess

ROOT = os.path.dirname(os.path.abspath(__file__))
MAIN = os.path.join(ROOT, "OllamaTrauma_v2.sh")

def main():
    if not os.path.isfile(MAIN):
        print("Error: main script not found:", MAIN, file=sys.stderr)
        return 2
    bash = shutil.which("bash")
    if not bash:
        print("Error: 'bash' not found in PATH. Please install bash.", file=sys.stderr)
        return 2
    args = [bash, MAIN] + sys.argv[1:]
    try:
        res = subprocess.run(args)
        return res.returncode
    except KeyboardInterrupt:
        return 130

if __name__ == "__main__":
    sys.exit(main())
