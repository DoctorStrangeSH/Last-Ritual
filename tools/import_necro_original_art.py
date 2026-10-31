#!/usr/bin/env python3
"""Safely import unchanged v0.5 Soul Altar original art and prepare Godot PNG assets.

Usage: python tools/import_necro_original_art.py SoulAltar_Original_Art_Sprites.zip
Requires Pillow. This command never touches existing source originals.
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
SOURCE_SHA = "fa73a1ff2e771c2bc5c7a4df7be04b71654f1d802fe2645e3451df0da641db40"
NAMES = ["level_1", "level_2", "level_3", "specialization_reaper", "specialization_legion"]
SOURCE = ROOT / "assets/spire/towers/necro/source/original"
OUTPUT = ROOT / "assets/spire/towers/necro/production"

def save_unchanged(target: Path, payload: bytes) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists() and target.read_bytes() != payload:
        raise ValueError(f"Refusing to overwrite different source: {target}")
    if not target.exists():
        target.write_bytes(payload)

def run(archive: Path, concept: Path | None) -> None:
    with zipfile.ZipFile(archive) as z:
        if z.testzip() is not None:
            raise ValueError("Damaged ZIP")
        supplied = json.loads(z.read("MANIFEST.json"))
        if supplied.get("source_sha256") != SOURCE_SHA:
            raise ValueError("Wrong source concept hash in sprite manifest")
        images = {}
        for name in NAMES:
            row = supplied["sprites"][name]
            filename = row["file"]
            if filename != name + ".png":
                raise ValueError(f"Unexpected asset filename: {filename}")
            data = z.read(filename)
            if hashlib.sha256(data).hexdigest() != row["sha256"]:
                raise ValueError(f"Original sprite hash mismatch: {filename}")
            png = Image.open(io.BytesIO(data))
            png.load()
            if png.format != "PNG" or png.mode != "RGBA" or list(png.size) != row["size"]:
                raise ValueError(f"Bad PNG dimensions or format: {filename}")
            images[name] = (data, png)
    if concept is not None:
        raw = concept.read_bytes()
        if hashlib.sha256(raw).hexdigest() != SOURCE_SHA:
            raise ValueError("Original concept v0.5 SHA-256 mismatch")
        save_unchanged(SOURCE / "soul_altar_tower_concept_v05.png", raw)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, (original, image) in images.items():
        save_unchanged(SOURCE / (name + ".png"), original)
        # Full original silhouette at native resolution; do not approximate in SVG.
        target = OUTPUT / (name + "_hd.png")
        target.write_bytes(original)
        # Align on bottom centre, preserving aspect ratio and transparent margins.
        resized = image.copy()
        resized.thumbnail((185, 185), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (192, 192))
        canvas.alpha_composite(resized, ((192-resized.width)//2, 192-resized.height))
        canvas.save(OUTPUT / (name + "_192.png"), optimize=True)
    print(f"Imported {len(NAMES)} original sprites and 10 gameplay exports")
    print("Artistic review and animated VFX still required before replacing runtime.")
    
if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("archive", type=Path)
    ap.add_argument("--concept", type=Path, help="Optional untouched original v0.5 PNG")
    args = ap.parse_args()
    run(args.archive, args.concept)
