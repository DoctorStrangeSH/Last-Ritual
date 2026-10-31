#!/usr/bin/env python3
"""Install full source-backed Soul Altar kit from a reviewed ZIP with hash checks.

python tools/install_necro_full_pack.py SoulAltar_Full_Art_Pack.zip
The ZIP is supplied externally; no missing binary assets are silently invented.
"""
from __future__ import annotations
import argparse
import hashlib
import io
import json
import zipfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "assets/spire/towers/necro"
PREFIX = "last_ritual_necro_pack/"
EXPECTED = {
    "level_1_hd.png", "level_2_hd.png", "level_3_hd.png",
    "specialization_reaper_hd.png", "specialization_legion_hd.png",
    "level_1_192.png", "level_2_192.png", "level_3_192.png",
    "specialization_reaper_192.png", "specialization_legion_192.png",
    "level_1_idle_8f.png", "level_2_idle_8f.png", "level_3_idle_8f.png",
    "soul_projectile_8f.png", "soul_impact_8f.png", "icon_128.png",
}

def install(archive: Path) -> None:
    with zipfile.ZipFile(archive) as z:
        if z.testzip() is not None:
            raise ValueError("ZIP checksum error")
        manifest = json.loads(z.read(PREFIX + "MANIFEST.json"))
        files = manifest["files"]
        if set(files) != EXPECTED:
            raise ValueError("Incomplete or unexpected art package")
        checked = {}
        for name in sorted(EXPECTED):
            data = z.read(PREFIX + "game/" + name)
            description = files[name]
            if hashlib.sha256(data).hexdigest() != description["sha256"]:
                raise ValueError("SHA mismatch: " + name)
            png = Image.open(io.BytesIO(data))
            png.load()
            if png.format != "PNG" or png.mode != "RGBA" or png.size != (description["width"], description["height"]):
                raise ValueError("Invalid PNG format/size: " + name)
            if png.getbbox() is None or png.getpixel((0, 0))[3] != 0:
                raise ValueError("No image content or transparent margin: " + name)
            checked[name] = data
        # Validate everything before writing *any* production file.
        for name, data in checked.items():
            destination = TARGET / "production" / name
            if destination.exists() and destination.read_bytes() != data:
                raise ValueError("Refusing to overwrite modified PNG: " + str(destination))
        for name, data in checked.items():
            destination = TARGET / "production" / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            if not destination.exists():
                destination.write_bytes(data)
    print(f"Installed {len(checked)} transparent source-backed PNG assets.")
    print("This imports art; it does NOT claim the Godot runtime was switched or hand-QA passed.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
    install(parser.parse_args().archive)
