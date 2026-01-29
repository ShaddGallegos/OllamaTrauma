import importlib.util
from pathlib import Path
import shutil


def load_mod():
    spec = importlib.util.spec_from_file_location('sorg', '/run/media/sgallego/SD_Card/Storage_Organize_v2.py')
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_ensure_refuses_target_only(tmp_path):
    mod = load_mod()
    root = tmp_path / 'targ'
    root.mkdir()
    # create target-only marker
    (root / mod.MARKER_TARGET_ONLY).write_text('marked')
    # call ensure_standard_folders
    mod.ensure_standard_folders(root, dry_run=False)
    # standard folders should NOT be created
    for d in mod.STANDARD_FOLDERS:
        assert not (root / d).exists()


def test_normalize_renames_spaces(tmp_path):
    mod = load_mod()
    root = tmp_path / 'n'
    root.mkdir()
    f = root / 'file with spaces.txt'
    f.write_text('hi')
    mod.normalize_filenames(root, dry_run=False)
    # original should be gone and new sanitized name present
    assert not f.exists()
    found = list(root.iterdir())
    assert len(found) == 1
    assert 'file_with_spaces' in found[0].name
