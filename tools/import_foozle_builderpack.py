#!/usr/bin/env python3
"""Extract the owner-supplied Foozle Spire BuilderPack source PNGs.

Usage:
  python tools/import_foozle_builderpack.py /path/to/Foozle_2DS0021_Spire_BuilderPack.zip
Only the three source sheets used for construction/collapse effects are copied.
The script validates ZIP CRCs and PNG signatures; Godot import/visual QA is a
separate required step. Requires Python 3.10+, no third-party packages.
"""
from pathlib import Path
import sys
import zipfile

FILES = {
    "Building Animations/PNGs/Tower Construction.png": "assets/spire/builder/Tower_Construction.png",
    "Building Animations/PNGs/Tower - Collapse.png": "assets/spire/builder/Tower_Collapse.png",
    "Wisp/Spritesheet/Wisp - Animations.png": "assets/spire/builder/Wisp_Animations.png",
}
README_SUFFIX = "Readme.txt"


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    archive = Path(sys.argv[1])
    if not archive.is_file():
        raise SystemExit(f"Archive not found: {archive}")
    root = Path(__file__).resolve().parents[1]
    with zipfile.ZipFile(archive) as zf:
        bad = zf.testzip()
        if bad:
            raise SystemExit(f"ZIP CRC error in {bad}")
        names = zf.namelist()
        for suffix, destination in FILES.items():
            matches = [name for name in names if name.endswith(suffix)]
            if len(matches) != 1:
                raise SystemExit(f"Expected one source ending {suffix!r}, found {len(matches)}")
            data = zf.read(matches[0])
            if not data.startswith(b"\x89PNG\r\n\x1a\n"):
                raise SystemExit(f"Not a PNG: {matches[0]}")
            target = root / destination
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            print(f"Extracted {matches[0]} -> {destination} ({len(data)} bytes)")
        readmes = [name for name in names if name.endswith(README_SUFFIX)]
        if len(readmes) != 1:
            raise SystemExit(f"Expected one package Readme.txt, found {len(readmes)}")
        license_dir = root / "assets/spire/licenses"
        license_dir.mkdir(parents=True, exist_ok=True)
        (license_dir / "Foozle_BuilderPack_Readme.txt").write_bytes(zf.read(readmes[0]))
        print("Copied BuilderPack Readme.txt to assets/spire/licenses/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
