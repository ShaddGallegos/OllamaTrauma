#!/usr/bin/env python3
"""
Simple MCP helper: publish/read/list JSON contexts under mcp/contexts.
Designed to be minimal and dependency-free (stdlib only).
"""
import json
import os
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
MCP_DIR = PROJECT_ROOT / "mcp"
CONTEXTS_DIR = MCP_DIR / "contexts"
REQUESTS_DIR = MCP_DIR / "requests"


def ensure_dirs():
    CONTEXTS_DIR.mkdir(parents=True, exist_ok=True)
    REQUESTS_DIR.mkdir(parents=True, exist_ok=True)


def publish_context(name: str, data: dict):
    ensure_dirs()
    path = CONTEXTS_DIR / f"{name}.json"
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    return str(path)


def read_context(name: str):
    path = CONTEXTS_DIR / f"{name}.json"
    if not path.exists():
        raise FileNotFoundError(f"Context not found: {name}")
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def list_contexts():
    ensure_dirs()
    return [p.stem for p in CONTEXTS_DIR.glob("*.json")]


if __name__ == "__main__":
    # Simple CLI: publish <name> <json-file> | read <name> | list
    if len(sys.argv) < 2:
        print("Usage: mcp_helper.py publish|read|list ...")
        sys.exit(2)

    cmd = sys.argv[1]
    try:
        if cmd == "publish":
            if len(sys.argv) != 4:
                print("Usage: mcp_helper.py publish <name> <json-file>")
                sys.exit(2)
            name = sys.argv[2]
            json_file = Path(sys.argv[3])
            data = json.loads(json_file.read_text(encoding="utf-8"))
            out = publish_context(name, data)
            print(out)
        elif cmd == "read":
            if len(sys.argv) != 3:
                print("Usage: mcp_helper.py read <name>")
                sys.exit(2)
            name = sys.argv[2]
            data = read_context(name)
            print(json.dumps(data, indent=2, ensure_ascii=False))
        elif cmd == "list":
            names = list_contexts()
            for n in names:
                print(n)
        else:
            print("Unknown command", cmd)
            sys.exit(2)
    except Exception as e:
        print("Error:", e, file=sys.stderr)
        sys.exit(1)
