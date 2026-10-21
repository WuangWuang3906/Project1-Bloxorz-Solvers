"""Build gui/export/Bloxorz.exe and a small zip of it for sharing.

Usage (repo root):  python tools/build_exe.py
Needs: python tools/get_godot.py --templates  (Godot editor + Windows templates);
set GODOT=<path to Godot console exe> to use a Godot installed elsewhere.

Steps: copy levels/*.json into gui/levels/ so they are packed into the .exe
(the game can then run from any folder), export with Godot, then write
gui/export/Bloxorz.zip (LZMA, ~26 MB; extract with Windows tar, 7-Zip or WinRAR).
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GODOT = Path(os.environ.get("GODOT", ROOT / "tools" / "godot" / "Godot_v4.7.2-stable_win64_console.exe"))
EXE = ROOT / "gui" / "export" / "Bloxorz.exe"


def main() -> None:
    if not GODOT.exists():
        sys.exit("Godot not found - run: python tools/get_godot.py --templates")
    bundle = ROOT / "gui" / "levels"
    shutil.rmtree(bundle, ignore_errors=True)
    bundle.mkdir()
    for f in sorted((ROOT / "levels").glob("level*.json")):
        shutil.copy(f, bundle / f.name)
    EXE.parent.mkdir(parents=True, exist_ok=True)
    # Godot can return 0 even when a step fails, so check the file afterwards.
    subprocess.run([str(GODOT), "--headless", "--path", str(ROOT / "gui"),
                    "--export-release", "Windows Desktop", "export/Bloxorz.exe"], check=False)
    shutil.rmtree(bundle, ignore_errors=True)   # only needed while exporting
    if not EXE.exists():
        sys.exit("Export failed - see the Godot output above.")
    zip_path = EXE.with_suffix(".zip")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_LZMA) as z:
        z.write(EXE, EXE.name)
    print(f"OK: {EXE} ({EXE.stat().st_size >> 20} MB), {zip_path} ({zip_path.stat().st_size >> 20} MB)")


if __name__ == "__main__":
    main()
