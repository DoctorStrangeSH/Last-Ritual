#!/usr/bin/env python3
"""Hand-authored pixel art for the four night events (48x48 each).

The file IS the editable source: explicit pixel operations on the shared
palette, one ink outline per illustration.
Output: assets/night/event_icons_4x48.png, frames in scripts/night_events.gd
ORDER (altar, grave, fountain, mirror). `--verify` compares without writing.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_trophy_icons import Icon, to_image  # noqa: E402  (shared palette + outline)
from generate_night_merchant import trapezoid  # noqa: E402

SIZE = 48
ORDER = ["altar", "grave", "fountain", "mirror"]
OUTPUT = Path("assets/night/event_icons_4x48.png")


def candle(c: Icon, x: int, y: int, height: int) -> None:
    c.box(x, y, x + 1, y + height, "b2")
    c.put(x, y, "b3")
    c.put(x, y - 1, "e3"); c.put(x + 1, y - 1, "e2"); c.put(x, y - 2, "e2")


def altar() -> Icon:
    c = Icon(SIZE, SIZE)
    # stepped stone altar
    c.box(6, 38, 41, 44, "s2"); c.row(38, 6, 41, "s4")
    c.box(10, 28, 37, 37, "s3"); c.row(28, 10, 37, "s5")
    c.box(10, 30, 12, 37, "s2")
    # gilded runes on the front
    for x in (15, 21, 27, 33):
        c.box(x, 31, x + 1, 34, "g2"); c.put(x, 31, "g3")
    # violet soul flame
    c.oval(23.5, 19, 7, 9, "v1")
    c.oval(23.5, 20, 5, 7, "v2")
    c.oval(23.5, 22, 3, 4, "v3")
    c.box(23, 21, 24, 24, "v4")
    c.box(23, 8, 24, 11, "v2"); c.put(22, 7, "v1"); c.put(25, 6, "v2")
    c.oval(23.5, 27, 6, 1.5, "g2")
    candle(c, 7, 31, 6)
    candle(c, 39, 31, 6)
    c.outline()
    return c


def grave() -> Icon:
    c = Icon(SIZE, SIZE)
    # tombstone
    c.box(14, 8, 29, 30, "s3")
    c.oval(21.5, 9, 7.5, 5, "s3")
    c.box(15, 9, 28, 29, "s4")
    c.oval(21.5, 9, 6.5, 4, "s4")
    # carved skull instead of a cross
    c.oval(21.5, 15, 4, 3.5, "s2")
    c.box(19, 18, 24, 20, "s2")
    c.box(19, 14, 20, 15, "ink"); c.box(23, 14, 24, 15, "ink")
    c.put(21, 17, "ink"); c.put(22, 17, "ink")
    c.put(20, 20, "s4"); c.put(22, 20, "s4")
    c.row(24, 17, 26, "s2")
    c.put(16, 26, "m2"); c.put(17, 27, "m1"); c.put(27, 24, "m2")
    # open grave pit
    c.box(6, 31, 41, 44, "r1")
    c.box(9, 33, 38, 43, "ink")
    c.row(31, 6, 41, "r3"); c.row(44, 6, 41, "r0")
    c.oval(23.5, 39, 6, 2.5, "b2")
    c.put(20, 38, "b3"); c.put(27, 40, "b1")
    c.oval(24, 36, 2, 1.6, "b2"); c.put(23, 36, "ink"); c.put(25, 36, "ink")
    # soul wisps rising
    c.put(14, 34, "v3"); c.put(13, 32, "v4"); c.put(33, 35, "v3"); c.put(34, 33, "v4")
    # shovel
    c.box(36, 10, 37, 30, "r2")
    c.box(34, 6, 39, 11, "i2"); c.row(6, 35, 38, "i1")
    c.outline()
    return c


def fountain() -> Icon:
    c = Icon(SIZE, SIZE)
    # basin
    trapezoid(c, 28, 40, 5, 42, 9, 38, "s3")
    c.row(28, 5, 42, "s5"); c.row(29, 6, 41, "s4")
    c.box(18, 40, 29, 44, "s2"); c.row(44, 14, 33, "s3")
    # pool of blood
    c.box(9, 30, 38, 33, "c1")
    c.row(30, 10, 37, "c2")
    c.put(14, 31, "c3"); c.put(30, 31, "c3")
    # central pillar and spout
    c.box(21, 12, 26, 29, "s3"); c.box(22, 13, 25, 28, "s4")
    c.oval(23.5, 11, 6, 3, "s4"); c.row(9, 19, 28, "g2")
    c.oval(23.5, 7, 2.5, 2.5, "c2"); c.put(23, 6, "c3")
    # blood streams
    for y in range(11, 30):
        t = (y - 11) / 18
        lx = int(round(19 - 6 * t * t * 1.0 - 2 * t))
        rx = int(round(28 + 6 * t * t * 1.0 + 2 * t))
        c.put(lx, y, "c2"); c.put(rx, y, "c2")
    c.put(18, 12, "c3"); c.put(29, 12, "c3")
    # skull carving
    c.oval(23.5, 20, 2.5, 2.2, "b2"); c.put(22, 20, "ink"); c.put(25, 20, "ink")
    c.outline()
    return c


def mirror() -> Icon:
    c = Icon(SIZE, SIZE)
    # gilded oval frame
    c.oval(23.5, 22, 15, 19, "g1")
    c.oval(23.5, 22, 14, 18, "g2")
    c.oval(23.5, 21, 13, 17, "g3")
    # dark glass
    c.oval(23.5, 22, 11, 15, "v0")
    c.oval(21.5, 18, 6, 8, "v1")
    c.oval(21, 16, 2.5, 3.5, "v2")
    # shadow eyes in the glass
    c.box(18, 22, 20, 23, "c2"); c.box(27, 22, 29, 23, "c2")
    c.put(19, 22, "c3"); c.put(28, 22, "c3")
    # crack
    for x, y in ((30, 10), (29, 12), (30, 14), (28, 16), (29, 18), (27, 20)):
        c.put(x, y, "v4")
    # crown ornament and stand
    c.box(21, 2, 26, 3, "g2"); c.put(23, 1, "g4"); c.put(24, 1, "g3")  # kept off the edge for the outline
    c.box(22, 41, 25, 45, "g1"); c.box(16, 45, 31, 46, "g2")
    c.put(10, 22, "g4"); c.put(37, 22, "g4")
    c.outline()
    return c


DRAWERS = {"altar": altar, "grave": grave, "fountain": fountain, "mirror": mirror}


def atlas() -> Image.Image:
    sheet = Image.new("RGBA", (SIZE * len(ORDER), SIZE), (0, 0, 0, 0))
    for index, name in enumerate(ORDER):
        sheet.paste(to_image(DRAWERS[name]()), (index * SIZE, 0))
    return sheet


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify", action="store_true", help="compare with the committed PNG, never write")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    image = atlas()
    if args.verify:
        if not args.output.is_file():
            raise SystemExit(f"missing: {args.output}")
        with Image.open(args.output) as committed:
            if committed.convert("RGBA").tobytes() != image.tobytes():
                raise SystemExit(f"pixel mismatch: {args.output}")
        print("PASS: night event art matches the pixel source")
        return
    args.output.parent.mkdir(parents=True, exist_ok=True)
    image.save(args.output)
    print(f"generated: {args.output}")


if __name__ == "__main__":
    main()
