#!/usr/bin/env python3
"""
Scan the repository, back up any file that contains emoji, and remove emoji characters in-place.
Creates backups under ./emoji_backups/<relative-path>.

Safety: skips binary files and common large/binary extensions.
"""

import os
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(os.getcwd())
BACKUP_DIR = ROOT / "emoji_backups"
SKIP_DIRS = {".git", "emoji_backups", "__pycache__", "node_modules"}
BINARY_EXTS = {
    ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".zip", ".tar", ".gz", ".so",
    ".dll", ".exe", ".class", ".pyc", ".bin", ".pb", ".pt", ".gguf",
}

# Emoji ranges (covers common emoji blocks and variation selector)
emoji_pattern = re.compile(
    "["
    "\U0001F300-\U0001F5FF"  # symbols & pictographs
    "\U0001F600-\U0001F64F"  # emoticons
    "\U0001F680-\U0001F6FF"  # transport & map
    "\U0001F700-\U0001F77F"  # alchemical
    "\U0001F900-\U0001F9FF"  # supplemental symbols and pictographs
    "\U0001FA70-\U0001FAFF"  # symbols and pictographs extended-A
    "\U00002600-\U000026FF"  # misc symbols
    "\U00002700-\U000027BF"  # dingbats
    "\U0001F1E6-\U0001F1FF"  # regional indicator symbols (flags)
    "]",
    flags=re.UNICODE,
)
variation_selector = "\uFE0F"

changed_files = []
files_scanned = 0
emoji_instances_removed = 0


def is_text_file(path: Path) -> bool:
    try:
        with open(path, "rb") as f:
            chunk = f.read(8192)
            if b"\0" in chunk:
                return False
        return True
    except Exception:
        return False


for dirpath, dirnames, filenames in os.walk(ROOT):
    # skip backup dir and other skip dirs
    rel = os.path.relpath(dirpath, ROOT)
    if rel == ".":
        rel = ""
    parts = set(rel.split(os.sep)) if rel else set()
    if parts & SKIP_DIRS:
        # prune traversal
        dirnames[:] = []
        continue

    for fname in filenames:
        fpath = Path(dirpath) / fname
        # skip backup dir path if hit
        if BACKUP_DIR in fpath.parents:
            continue
        if fpath.suffix.lower() in BINARY_EXTS:
            continue
        if not is_text_file(fpath):
            continue

        files_scanned += 1
        try:
            text = fpath.read_text(encoding="utf-8")
        except Exception:
            # try with replacement to avoid crashes
            try:
                text = fpath.read_text(encoding="utf-8", errors="replace")
            except Exception:
                continue

        # count occurrences
        found = emoji_pattern.findall(text)
        num_found = len(found)
        num_vs = text.count(variation_selector)
        if num_found == 0 and num_vs == 0:
            continue

        # backup original
        backup_path = BACKUP_DIR / fpath.relative_to(ROOT)
        backup_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(fpath, backup_path)

        # remove emojis and variation selectors
        new_text = emoji_pattern.sub("", text)
        if variation_selector in new_text:
            new_text = new_text.replace(variation_selector, "")

        try:
            fpath.write_text(new_text, encoding="utf-8")
            changed_files.append(str(fpath.relative_to(ROOT)))
            emoji_instances_removed += num_found + num_vs
        except Exception as e:
            print(f"Failed to write {fpath}: {e}")

# summary
print("Emoji removal run complete.")
print(f"Files scanned: {files_scanned}")
print(f"Files changed: {len(changed_files)}")
print(f"Emoji instances removed: {emoji_instances_removed}")
if changed_files:
    print("Backups saved under: emoji_backups/")
    for p in changed_files:
        print(f" - {p}")
else:
    print("No emoji found in scanned text files.")

# exit code non-zero if modifications made so CI can detect
if changed_files:
    sys.exit(0)
else:
    sys.exit(0)
