"""Download the pinned Godot version for the GUI and verify its checksum.

Usage:  python tools/get_godot.py               # the editor, to run the GUI
        python tools/get_godot.py --templates   # + Windows export templates, to build the .exe
Result: tools/godot/Godot_v<ver>_win64.exe (gitignored). Windows only for now.
Templates go to tools/godot/templates/ (only the 2 Windows files; gui/export_presets.cfg points there).
"""
from __future__ import annotations

import hashlib
import sys
import urllib.request
import zipfile
from pathlib import Path

VERSION = "4.7.2-stable"
ZIP_NAME = f"Godot_v{VERSION}_win64.exe.zip"
BASE = f"https://github.com/godotengine/godot/releases/download/{VERSION}/"
DEST = Path(__file__).resolve().parent / "godot"


TPZ_NAME = f"Godot_v{VERSION}_export_templates.tpz"
TEMPLATE_FILES = ["windows_release_x86_64.exe", "windows_debug_x86_64.exe", "version.txt"]


def expected_sha512(file_name: str = ZIP_NAME) -> str:
    with urllib.request.urlopen(BASE + "SHA512-SUMS.txt") as r:
        for line in r.read().decode().splitlines():
            digest, _, name = line.partition("  ")
            if name.strip() == file_name:
                return digest
    raise RuntimeError(f"{file_name} not listed in SHA512-SUMS.txt")


def sha512_of(path: Path) -> str:
    h = hashlib.sha512()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def install_templates(tpz: Path | None = None) -> None:
    """Put the Windows export templates where Godot looks for them."""
    target = DEST / "templates"
    if (target / TEMPLATE_FILES[0]).exists():
        print(f"Templates already installed: {target}")
        return
    if tpz is None:
        DEST.mkdir(parents=True, exist_ok=True)
        tpz = DEST / TPZ_NAME
        print(f"Downloading {TPZ_NAME} (~1 GB, only 2 files are kept)...")
        urllib.request.urlretrieve(BASE + TPZ_NAME, tpz)
    if sha512_of(tpz) != expected_sha512(TPZ_NAME):
        sys.exit("Templates checksum mismatch - delete the file and try again.")
    target.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(tpz) as z:
        for name in TEMPLATE_FILES:
            (target / name).write_bytes(z.read(f"templates/{name}"))
    if tpz.parent == DEST:
        tpz.unlink()
    print(f"OK: templates in {target}")


def main() -> None:
    if sys.platform != "win32":
        sys.exit(f"Download Godot {VERSION} for your OS from https://godotengine.org/download/archive/")
    if "--templates" in sys.argv:
        i = sys.argv.index("--templates")
        local = sys.argv[i + 1] if i + 1 < len(sys.argv) else None
        install_templates(Path(local) if local else None)
    exe = DEST / ZIP_NAME.removesuffix(".zip")
    if exe.exists():
        print(f"Already installed: {exe}")
        return
    DEST.mkdir(parents=True, exist_ok=True)
    zip_path = DEST / ZIP_NAME
    print(f"Downloading {ZIP_NAME} (~86 MB)...")
    urllib.request.urlretrieve(BASE + ZIP_NAME, zip_path)
    if sha512_of(zip_path) != expected_sha512():
        zip_path.unlink()
        sys.exit("Checksum mismatch - download deleted, try again.")
    with zipfile.ZipFile(zip_path) as z:
        z.extractall(DEST)
    zip_path.unlink()
    print(f"OK: {exe}")
    print(f'Run the game:  "{exe}" --path gui')


if __name__ == "__main__":
    main()
