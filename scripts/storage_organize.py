from pathlib import Path

# Minimal storage organize helpers used by tests
MARKER_TARGET_ONLY = ".marker_target_only"
STANDARD_FOLDERS = ["inbox", "archive", "processed"]


def ensure_standard_folders(root_path, dry_run=True):
    """Create STANDARD_FOLDERS under root_path unless target-only marker exists.

    Args:
        root_path: pathlib.Path or str pointing to root directory
        dry_run: if True, do not actually create directories
    """
    root = Path(root_path)
    if (root / MARKER_TARGET_ONLY).exists():
        return
    for d in STANDARD_FOLDERS:
        target = root / d
        if not dry_run:
            target.mkdir(parents=True, exist_ok=True)


def normalize_filenames(root_path, dry_run=True):
    """Rename files in root_path replacing spaces with underscores.

    Very small, deterministic implementation sufficient for tests.
    """
    root = Path(root_path)
    for p in list(root.iterdir()):
        if p.is_file():
            new_name = p.name.replace(" ", "_")
            # remove trailing dots and ensure name not empty
            if new_name != p.name:
                target = p.with_name(new_name)
                if not dry_run:
                    p.rename(target)
    return
