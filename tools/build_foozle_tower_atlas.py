#!/usr/bin/env python3
"""Rebuild the four-row Foozle tower atlas from original owner-supplied archives.

Requires Pillow: python -m pip install Pillow
Run: python tools/build_foozle_tower_atlas.py <directory containing original ZIPs>
This is a developer-side tool, not a runtime game dependency.
"""
from pathlib import Path
import io
import sys
import zipfile
from PIL import Image

SOURCE = (
    ("Foozle_2DS0017_Spire_TowerPack_1*.zip", "Tower 01.png"),
    ("Foozle_2DS0018_Spire_TowerPack_2*.zip", "Tower 03.png"),
    ("Foozle_2DS0019_Spire_TowerPack_3*.zip", "Tower 05.png"),
    ("Foozle_2DS0020_Spire_TowerPack_4*.zip", "Tower 07.png"),
)
ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets/spire/towers_atlas.png"


def build(folder: Path) -> None:
    atlas = Image.new("RGBA", (256, 256))
    for row, (pattern, filename) in enumerate(SOURCE):
        matches = sorted(folder.glob(pattern))
        if len(matches) != 1:
            raise ValueError(f"Expected one ZIP matching {pattern}, got {len(matches)}")
        with zipfile.ZipFile(matches[0]) as package:
            candidates = [name for name in package.namelist() if name.endswith("/" + filename) and "/PNGs/" in name]
            if len(candidates) != 1:
                raise ValueError(f"Missing/ambiguous image {filename} in {matches[0]}")
            with Image.open(io.BytesIO(package.read(candidates[0]))) as source:
                source.load()
                if source.size != (192, 128):
                    raise ValueError(f"Unexpected size for {filename}: {source.size}")
                for column in range(4):
                    x = column % 3
                    y = column // 3
                    tile = source.crop((x * 64, y * 64, (x + 1) * 64, (y + 1) * 64))
                    atlas.paste(tile, (column * 64, row * 64))
    DEST.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(DEST, format="PNG", optimize=True)
    with Image.open(DEST) as check:
        check.verify()
    print(f"Wrote verified RGBA PNG: {DEST} ({DEST.stat().st_size} bytes)")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: build_foozle_tower_atlas.py <folder-with-TowerPack-ZIPs>")
    build(Path(sys.argv[1]))
