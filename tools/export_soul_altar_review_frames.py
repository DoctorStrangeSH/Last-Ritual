#!/usr/bin/env python3
"""Extract reference-only, assembled Soul Altar review sprites (NOT modular weapons).

Requires Pillow: python -m pip install Pillow
Atlas layout: 320x88, five horizontal 64x88 cells, palette transparency.
The optional 2x export uses nearest-neighbour scaling for crisp pixel art.
"""
from __future__ import annotations

import argparse
from pathlib import Path
from PIL import Image

FRAME_NAMES = ("level_1", "level_2", "level_3", "reaper", "legion")
FRAME_SIZE = (64, 88)
ATLAS_SIZE = (FRAME_SIZE[0] * len(FRAME_NAMES), FRAME_SIZE[1])
DEFAULT_ATLAS = Path("assets/spire/towers/necro/review/approved_assembled_5f.png")
DEFAULT_OUTPUT = Path("build/soul-altar-assembled-review/frames")


def export_frames(atlas_path: Path, output_dir: Path, scale: int) -> None:
    atlas = Image.open(atlas_path).convert("RGBA")
    if atlas.size != ATLAS_SIZE:
        raise ValueError(f"Expected atlas {ATLAS_SIZE}, got {atlas.size}")
    alpha_min, alpha_max = atlas.getchannel("A").getextrema()
    if alpha_min > 1 or alpha_max < 240:
        raise ValueError(f"Unexpected atlas alpha range: {(alpha_min, alpha_max)}")
    # The indexed palette stores empty pixels as alpha 1/255; normalize to exact 0.
    alpha = atlas.getchannel("A")
    alpha = alpha.point(lambda value: 0 if value <= 1 else value)
    atlas.putalpha(alpha)
    output_dir.mkdir(parents=True, exist_ok=True)
    for index, name in enumerate(FRAME_NAMES):
        frame = atlas.crop((index * FRAME_SIZE[0], 0, (index + 1) * FRAME_SIZE[0], FRAME_SIZE[1]))
        if frame.getchannel("A").getextrema()[0] != 0 or frame.getchannel("A").getextrema()[1] < 240:
            raise ValueError(f"{name} frame lost transparency")
        frame.save(output_dir / f"{name}.png", optimize=True)
        if scale > 1:
            frame.resize((FRAME_SIZE[0] * scale, FRAME_SIZE[1] * scale), Image.Resampling.NEAREST).save(
                output_dir / f"{name}_{scale}x.png", optimize=True
            )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--atlas", type=Path, default=DEFAULT_ATLAS)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--scale", type=int, default=2)
    args = parser.parse_args()
    if args.scale < 1:
        parser.error("--scale must be >= 1")
    export_frames(args.atlas, args.output, args.scale)


if __name__ == "__main__":
    main()
