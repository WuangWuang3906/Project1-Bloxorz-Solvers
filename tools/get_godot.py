"""Download the pinned Godot version for the GUI and verify its checksum.

Usage:  python tools/get_godot.py
Result: tools/godot/Godot_v<ver>_win64.exe (gitignored). Windows only for now.
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


def expected_sha512() -> str:
    with urllib.request.urlopen(BASE + "SHA512-SUMS.txt") as r:
        for line in r.read().decode().splitlines():
            digest, _, name = line.partition("  ")
            if name.strip() == ZIP_NAME:
                return digest
    raise RuntimeError(f"{ZIP_NAME} not listed in SHA512-SUMS.txt")


def main() -> None:
    if sys.platform != "win32":
        sys.exit(f"Download Godot {VERSION} for your OS from https://godotengine.org/download/archive/")
    exe = DEST / ZIP_NAME.removesuffix(".zip")
    if exe.exists():
        print(f"Already installed: {exe}")
        return
    DEST.mkdir(parents=True, exist_ok=True)
    zip_path = DEST / ZIP_NAME
    print(f"Downloading {ZIP_NAME} (~86 MB)...")
    urllib.request.urlretrieve(BASE + ZIP_NAME, zip_path)
    digest = hashlib.sha512(zip_path.read_bytes()).hexdigest()
    if digest != expected_sha512():
        zip_path.unlink()
        sys.exit("Checksum mismatch - download deleted, try again.")
    with zipfile.ZipFile(zip_path) as z:
        z.extractall(DEST)
    zip_path.unlink()
    print(f"OK: {exe}")
    print(f'Run the game:  "{exe}" --path gui')


if __name__ == "__main__":
    main()
