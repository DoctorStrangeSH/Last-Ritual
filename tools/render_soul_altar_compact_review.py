#!/usr/bin/env python3
"""Create a compact native-scale 3x3 Soul Altar review board.

Three base levels by three weapon branches, viewed facing north. This is a
candidate-art comparison, not approval or an asset used by the game.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

from render_necro_modular_preview import ART, BRANCHES, COMPOSITE, FRAME, GROUND_ANCHOR, PIVOT

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "build/soul_altar_9_compositions_1x.png"
GAP = 16
MARGIN = 20
HEADER = 54
LABEL_HEIGHT = 24
CARD_W = FRAME[0] + GAP
CARD_H = COMPOSITE[1] + LABEL_HEIGHT + GAP


def render(output: Path = DEFAULT_OUTPUT) -> None:
    board = Image.new("RGB", (MARGIN * 2 + 3 * CARD_W, HEADER + 3 * CARD_H + MARGIN), "#141020")
    draw = ImageDraw.Draw(board)
    draw.text((MARGIN, 12), "SOUL ALTAR / CANDIDATES / 1X / N / NOT APPROVED", fill="#efdbb3")
    draw.text((MARGIN, 32), "L1 - L2 - L3 x BASE - REAPER - LEGION", fill="#b99dcc")
    for row, (branch, _) in enumerate(BRANCHES):
        with Image.open(ART / f"weapon/{branch}/weapon_8way.png") as src:
            if src.size != (FRAME[0] * 8, FRAME[1]):
                raise ValueError(f"Invalid weapon atlas for {branch}: {src.size}")
            weapon = src.convert("RGBA").crop((0, 0, *FRAME))
        for column, level in enumerate((1, 2, 3)):
            with Image.open(ART / f"base/level_{level}.png") as src:
                if src.size != FRAME:
                    raise ValueError(f"Invalid base L{level}: {src.size}")
                base = src.convert("RGBA")
            preview = Image.new("RGBA", COMPOSITE, (0, 0, 0, 0))
            preview.alpha_composite(base, (0, 0))
            preview.alpha_composite(weapon, (GROUND_ANCHOR[0] - PIVOT[0], GROUND_ANCHOR[1] - PIVOT[1]))
            x = MARGIN + column * CARD_W
            y = HEADER + row * CARD_H
            draw.text((x + 4, y), f"{branch.upper()} / L{level}", fill="#f4c987")
            board.paste(preview.convert("RGB"), (x, y + LABEL_HEIGHT), preview.getchannel("A"))
            draw.rectangle((x, y + LABEL_HEIGHT, x + FRAME[0] - 1, y + LABEL_HEIGHT + COMPOSITE[1] - 1), outline="#574369")
    output.parent.mkdir(parents=True, exist_ok=True)
    board.save(output)
    print(f"Created {output} ({board.width}x{board.height})")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    render(args.output)
