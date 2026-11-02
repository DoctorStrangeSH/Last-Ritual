#!/usr/bin/env python3
"""Render a review-only 3-level x 3-weapon x 8-direction Soul Altar sheet.

This is a contact sheet, not a game asset or proof of artistic approval.
Run from the repository root:
    python tools/render_necro_modular_preview.py --all-levels
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
LEVEL_HEADER = 28
LABEL = 26


def sheet_dimensions(level_count: int, scale: int = SCALE) -> tuple[int, int]:
    if level_count < 1 or level_count > 3:
        raise ValueError("The contact sheet supports one to three base levels")
    if scale not in (1, 2):
        raise ValueError("The review sheet supports native 1x or enlarged 2x scale")
    tile = FRAME[0] * scale
    tile_height = COMPOSITE[1] * scale
    row_height = LABEL + tile_height + GAP
    width = GAP + 8 * (tile + GAP)
    height = HEADER + level_count * (LEVEL_HEADER + len(BRANCHES) * row_height + GAP)
    return width, height


def render(output: Path = DEST, level: int = 3, all_levels: bool = False, scale: int = SCALE) -> None:
    if level not in (1, 2, 3):
        raise ValueError("Level must be 1, 2 or 3")
    levels = (1, 2, 3) if all_levels else (level,)
    if scale not in (1, 2):
        raise ValueError("The review sheet supports native 1x or enlarged 2x scale")
    tile = FRAME[0] * scale
    tile_height = COMPOSITE[1] * scale
    row_height = LABEL + tile_height + GAP
    width, height = sheet_dimensions(len(levels), scale)

    bases: dict[int, Image.Image] = {}
    for selected_level in levels:
        base_path = ART / f"base/level_{selected_level}.png"
        with Image.open(base_path) as source:
            base = source.convert("RGBA")
        if base.size != FRAME:
            raise ValueError(f"Invalid base dimensions: {base_path}: {base.size}")
        bases[selected_level] = base

    strips: dict[str, Image.Image] = {}
    for branch, _ in BRANCHES:
        path = ART / f"weapon/{branch}/weapon_8way.png"
        with Image.open(path) as source:
            strip = source.convert("RGBA")
        if strip.size != (FRAME[0] * 8, FRAME[1]):
            raise ValueError(f"Invalid weapon strip dimensions: {path}: {strip.size}")
        strips[branch] = strip

    sheet = Image.new("RGB", (width, height), "#141020")
    draw = ImageDraw.Draw(sheet)
    level_label = "ALL LEVELS" if all_levels else f"L{level}"
    draw.text(
        (GAP, 9),
        f"SOUL ALTAR - MODULAR CANDIDATE / {level_label} / {scale}X / 72 POSES / NOT APPROVED",
        fill="#efdbb3",
    )

    for level_index, selected_level in enumerate(levels):
        group_top = HEADER + level_index * (LEVEL_HEADER + len(BRANCHES) * row_height + GAP)
        draw.text(
            (GAP, group_top + 5),
            f"BASE LEVEL {selected_level}",
            fill="#f4c987",
        )
        for row, (branch, title) in enumerate(BRANCHES):
            top = group_top + LEVEL_HEADER + row * row_height
            draw.text((GAP, top + 4), f"{title} / {branch} / 8 directions", fill="#e8d1fc")
            strip = strips[branch]
            base = bases[selected_level]
            for col, direction in enumerate(DIRECTIONS):
                x = GAP + col * (tile + GAP)
                y = top + LABEL
                source_box = (
                    col * FRAME[0],
                    0,
                    (col + 1) * FRAME[0],
                    FRAME[1],
                )
                weapon = strip.crop(source_box)
                composite = Image.new("RGBA", COMPOSITE, (0, 0, 0, 0))
                composite.alpha_composite(base, (0, 0))
                composite.alpha_composite(
                    weapon,
                    (GROUND_ANCHOR[0] - PIVOT[0], GROUND_ANCHOR[1] - PIVOT[1]),
                )
                preview = composite.resize((tile, tile_height), Image.Resampling.NEAREST)
                sheet.paste(preview.convert("RGB"), (x, y), preview.getchannel("A"))
                draw.rectangle(
                    (x, y, x + tile - 1, y + tile_height - 1),
                    outline="#574369",
                    width=2,
                )
                draw.text((x + 8, y + 8), direction, fill="#fff5cc")

    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)
    print(f"Created {output} ({width}x{height}; {scale}x; {len(levels) * len(BRANCHES) * 8} poses)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEST)
    parser.add_argument("--level", type=int, choices=(1, 2, 3), default=3)
    parser.add_argument("--scale", type=int, choices=(1, 2), default=SCALE, help="Native 1x pixels or enlarged 2x review scale")
    parser.add_argument(
        "--all-levels",
        action="store_true",
        help="Render levels 1, 2 and 3 (72 base/weapon/direction combinations)",
    )
    args = parser.parse_args()
    render(args.output, args.level, args.all_levels, args.scale)
