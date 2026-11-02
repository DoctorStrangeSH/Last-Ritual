#!/usr/bin/env python3
"""Render a review-only 3x8 contact sheet of composited Soul Altar candidate layers.

The file is NOT a game asset or proof of visual approval. Run from repo root:
    python tools/render_necro_modular_preview.py
"""
from __future__ import annotations
import argparse
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets/spire/towers/necro/candidate"
DEST = ROOT / "build/soul_altar_modular_contact_sheet.png"
BRANCHES = (("base", "Обычный алтарь"), ("reaper", "Жнец"), ("legion", "Легион"))
DIRECTIONS = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")
FRAME = (128, 128)
PIVOT = (64, 90)
GROUND_ANCHOR = (64, 118)
COMPOSITE = (128, FRAME[1] + GROUND_ANCHOR[1] - PIVOT[1])
SCALE = 2
GAP = 12
HEADER = 42
LABEL = 26


def render(output: Path = DEST, level: int = 3) -> None:
    if level not in (1, 2, 3):
        raise ValueError("Level must be 1, 2 or 3")
    base_path = ART / f"base/level_{level}.png"
    with Image.open(base_path) as src:
        base = src.convert("RGBA")
    if base.size != FRAME:
        raise ValueError(f"Invalid base dimensions: {base.size}")
    strips = {}
    for branch, _ in BRANCHES:
        path = ART / f"weapon/{branch}/weapon_8way.png"
        with Image.open(path) as src:
            strip = src.convert("RGBA")
        if strip.size != (FRAME[0] * 8, FRAME[1]):
            raise ValueError(f"Invalid weapon strip dimensions: {path}: {strip.size}")
        strips[branch] = strip

    tile = FRAME[0] * SCALE
    width = GAP + 8 * (tile + GAP)
    tile_height = COMPOSITE[1] * SCALE
    height = HEADER + 3 * (LABEL + tile_height + GAP)
    sheet = Image.new("RGB", (width, height), "#141020")
    draw = ImageDraw.Draw(sheet)
    draw.text((GAP, 9), f"SOUL ALTAR - MODULAR CANDIDATE / L{level} / NOT APPROVED", fill="#efdbb3")
    for row, (branch, title) in enumerate(BRANCHES):
        top = HEADER + row * (LABEL + tile + GAP)
        draw.text((GAP, top + 4), f"{title} / {branch} / 8 ways", fill="#e8d1fc")
        strip = strips[branch]
        for col, direction in enumerate(DIRECTIONS):
            x = GAP + col * (tile + GAP)
            y = top + LABEL
            source = (col * FRAME[0], 0, (col + 1) * FRAME[0], FRAME[1])
            weapon = strip.crop(source)
            composite = Image.new("RGBA", COMPOSITE, (0, 0, 0, 0))
            composite.alpha_composite(base, (0, 0))
            composite.alpha_composite(weapon, (GROUND_ANCHOR[0] - PIVOT[0], GROUND_ANCHOR[1] - PIVOT[1]))
            preview = composite.resize((tile, tile_height), Image.Resampling.NEAREST)
            sheet.paste(preview.convert("RGB"), (x, y), preview.getchannel("A"))
            draw.rectangle((x, y, x + tile - 1, y + tile_height - 1), outline="#574369", width=2)
            draw.text((x + 8, y + 8), direction, fill="#fff5cc")
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)
    print(f"Created {output} ({width}x{height})")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEST)
    parser.add_argument("--level", type=int, choices=(1, 2, 3), default=3)
    args = parser.parse_args()
    render(args.output, args.level)
