#!/usr/bin/env python3
"""Extract approved Soul Altar sprites from the committed indexed PNG atlas.

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
DEFAULT_ATLAS = Path("assets/spire/towers/necro/production/pixel_art/soul_altar_approved_atlas.png")
DEFAULT_OUTPUT = Path("assets/spire/towers/necro/production/pixel_art/frames")


def export_frames(atlas_path: Path, output_dir: Path, scale: int) -> None:
    atlas = Image.open(atlas_path).convert("RGBA")
    if atlas.size != ATLAS_SIZE:
        raise ValueError(f"Expected atlas {ATLAS_SIZE}, got {atlas.size}")
    if atlas.getchannel("A").getextrema() != (0, 255):
        raise ValueError("Atlas must preserve transparent and opaque pixels")
    output_dir.mkdir(parents=True, exist_ok=True)
    for index, name in enumerate(FRAME_NAMES):
        frame = atlas.crop((index * FRAME_SIZE[0], 0, (index + 1) * FRAME_SIZE[0], FRAME_SIZE[1]))
        if frame.getchannel("A").getextrema()[0] != 0:
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
