#!/usr/bin/env python3
"""Safely import the complete *unchanged* source-backed Soul Altar bundle.

Each byte in this distribution was produced from the user-approved v0.5 concept;
do not automatically redraw/replace it with geometric placeholder graphics.
"""
import hashlib
import io
import json
import sys
import zipfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BUNDLE_SHA256 = "3fb39c9b1d8ca69502a72ec371094a7c08f5c451bb0769cabfb04633218bce68"
CONCEPT_SHA256 = "fa73a1ff2e771c2bc5c7a4df7be04b71654f1d802fe2645e3451df0da641db40"
NECRO_ROOT = "assets/spire/towers/necro/"
SOURCE_NAMES = ["level_1", "level_2", "level_3", "specialization_legion", "specialization_reaper"]

def sha(data):
    return hashlib.sha256(data).hexdigest()

def import_bundle(path):
    raw = Path(path).read_bytes()
    if sha(raw) != BUNDLE_SHA256:
        raise ValueError("Bundle SHA256 mismatch: expected approved bundle")
    files = {}
    with zipfile.ZipFile(io.BytesIO(raw)) as archive:
        if archive.testzip() is not None:
            raise ValueError("Broken ZIP CRC")
        manifest_path = NECRO_ROOT + "production/MANIFEST.json"
        manifest = json.loads(archive.read(manifest_path))
        game = manifest["files"]
        if len(game) != 16:
            raise ValueError("Expected exactly 16 production PNGs")
        expected = {manifest_path, "ART_INSTALL_README.txt",
                    NECRO_ROOT + "source/concepts/soul_altar_tower_concept_v05.png"}
        expected |= {NECRO_ROOT + "source/original/" + name + ".png" for name in SOURCE_NAMES}
        expected |= {NECRO_ROOT + "production/" + name for name in game}
        names = set(archive.namelist())
        if names != expected:
            raise ValueError("Unexpected/missing ZIP members: " + repr(sorted(expected ^ names)))
        concept_path = NECRO_ROOT + "source/concepts/soul_altar_tower_concept_v05.png"
        if sha(archive.read(concept_path)) != CONCEPT_SHA256:
            raise ValueError("The untouched original v0.5 source was changed")
        for name in game:
            png_path = NECRO_ROOT + "production/" + name
            data = archive.read(png_path)
            m = game[name]
            if sha(data) != m["sha256"]:
                raise ValueError("Production sprite checksum mismatch: " + name)
            image = Image.open(io.BytesIO(data))
            image.load()
            if image.format != "PNG" or image.mode != "RGBA" or image.size != (m["width"], m["height"]):
                raise ValueError("Production sprite invalid size/format: " + name)
            if image.getbbox() is None or image.getpixel((0, 0))[3] > 0:
                raise ValueError("Production sprite must have transparent margins: " + name)
        for name in SOURCE_NAMES:
            source = archive.read(NECRO_ROOT + "source/original/" + name + ".png")
            hd = archive.read(NECRO_ROOT + "production/" + name + "_hd.png")
            if sha(source) != sha(hd):
                raise ValueError("Original and native-HD PNG differ: " + name)
        for name in sorted(expected):
            if not name.startswith(NECRO_ROOT):
                continue
            dest = (ROOT / name).resolve()
            if not dest.is_relative_to((ROOT / NECRO_ROOT).resolve()):
                raise ValueError("Unsafe output path")
            data = archive.read(name)
            if dest.exists() and dest.read_bytes() != data:
                raise ValueError("Refusing to overwrite changed file: " + name)
            files[dest] = data
    for dest, data in files.items():
        dest.parent.mkdir(parents=True, exist_ok=True)
        if not dest.exists():
            dest.write_bytes(data)
    print("Verified and installed %d untouched source + production entries." % len(files))

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python tools/import_necro_git_bundle.py <approved-art.zip>")
    import_bundle(sys.argv[1])
