#!/usr/bin/env python3
"""
Merge standalone .sh scripts into OllamaTrauma_v2.sh by extracting function
definitions and appending those not already present.

Creates backup: OllamaTrauma_v2.sh.merged_backup_TIMESTAMP
Removes merged .sh files after appending.

This is a best-effort tool; inspect changes before committing/pushing.
"""
import re
import sys
from pathlib import Path
from datetime import datetime

ROOT = Path.cwd()
MAIN = ROOT / 'OllamaTrauma_v2.sh'
SCRIPTS = list(ROOT.glob('*.sh')) + list((ROOT / 'scripts').rglob('*.sh'))
# exclude main
SCRIPTS = [p for p in SCRIPTS if p.resolve() != MAIN.resolve()]

func_re = re.compile(r'(^[a-zA-Z_][a-zA-Z0-9_\-]*\s*\(\)\s*\{)', re.M)
full_func_re = re.compile(r'(^[a-zA-Z_][a-zA-Z0-9_\-]*\s*\(\)\s*\{)', re.M)

if not MAIN.exists():
    print('Main script not found:', MAIN)
    sys.exit(1)

main_text = MAIN.read_text(encoding='utf-8')
# find existing function names
existing = set(re.findall(r'^([a-zA-Z_][a-zA-Z0-9_\-]*)\s*\(\)\s*\{', main_text, re.M))
print(f'Found {len(existing)} functions in main script')

#!/usr/bin/env python3
"""
This script was a one-time helper to merge shell scripts into the main
`OllamaTrauma_v2.sh`. The merge has been performed and the helper is
retained as a no-op placeholder to avoid accidental reuse.

If you truly want to remove this file, delete it manually.
"""

import sys

print("merge_sh_into_main.py: placeholder — merge already completed.")
sys.exit(0)
        # extract full function body by simple brace counting from m.end()
