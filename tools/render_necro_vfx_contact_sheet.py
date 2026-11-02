#!/usr/bin/env python3
"""Render all 48 candidate Soul Altar attack-VFX frames for visual review."""
from __future__ import annotations

import argparse
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets/spire/towers/necro/candidate/vfx"
DEST = ROOT / "build/soul_altar_attack_vfx_sheet.png"
BRANCHES = (("base", "Обычный Алтарь"), ("reaper", "Жнец"), ("legion", "Легион"))
KINDS = (("projectile", "PROJECTILE"), ("impact", "IMPACT"))
CELL = 128
GAP = 8
LEFT = 20
HEADER = 78
ROW_LABEL = 28
ROW_GAP = 12


def sheet_dimensions() -> tuple[int, int]:
    width = LEFT * 2 + 16 * (CELL + GAP)
    height = HEADER + len(BRANCHES) * (ROW_LABEL + CELL + ROW_GAP)
    return width, height


def render(output: Path = DEST) -> None:
    width, height = sheet_dimensions()
    sheet = Image.new("RGB", (width, height), "#141020")
    draw = ImageDraw.Draw(sheet)
    draw.text((LEFT, 8), "LAST RITUAL / SOUL ALTAR — ATTACK VFX CANDIDATES / 48 FRAMES / NOT APPROVED", fill="#efdbb3")
    draw.text((LEFT, 42), "PROJECTILE  ·  8 frames @ 24 FPS", fill="#d9a5ff")
    impact_x = LEFT + 8 * (CELL + GAP)
    draw.text((impact_x, 42), "IMPACT  ·  8 frames @ 24 FPS", fill="#8de8f5")

    for row, (branch, title) in enumerate(BRANCHES):
        row_top = HEADER + row * (ROW_LABEL + CELL + ROW_GAP)
        draw.text((LEFT, row_top + 5), title, fill="#f4c987")
        for kind_index, (kind, _) in enumerate(KINDS):
            atlas_path = ART / f"{branch}_{kind}_8f.png"
            with Image.open(atlas_path) as source:
                atlas = source.convert("RGBA")
            if atlas.width % 8 != 0:
                raise ValueError(f"{atlas_path} must contain eight equal frames")
            frame_width = atlas.width // 8
            if atlas.height != frame_width:
                raise ValueError(f"{atlas_path} frames must be square")
            for frame in range(8):
                source_box = (frame * frame_width, 0, (frame + 1) * frame_width, frame_width)
                sprite = atlas.crop(source_box)
                sprite = sprite.resize((frame_width * 2, frame_width * 2), Image.Resampling.NEAREST)
                cell_x = LEFT + kind_index * 8 * (CELL + GAP) + frame * (CELL + GAP)
                cell_y = row_top + ROW_LABEL
                canvas = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
                canvas.alpha_composite(sprite, ((CELL - sprite.width) // 2, (CELL - sprite.height) // 2))
                sheet.paste(canvas.convert("RGB"), (cell_x, cell_y), canvas.getchannel("A"))
                draw.rectangle((cell_x, cell_y, cell_x + CELL - 1, cell_y + CELL - 1), outline="#574369", width=2)
                draw.text((cell_x + 6, cell_y + 6), str(frame + 1), fill="#fff5cc")

    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)
    print(f"Created {output} ({width}x{height}; 48 frames)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEST)
    args = parser.parse_args()
    render(args.output)
