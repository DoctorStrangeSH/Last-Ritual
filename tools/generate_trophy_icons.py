#!/usr/bin/env python3
"""Hand-authored pixel-art icons for the eight night trophies (24x24 each).

This file IS the editable source: every icon is drawn with explicit pixel
operations on the battlefield palette, then outlined with one ink pixel.
Output: assets/trophies/trophy_icons_8x24.png (8 frames, left to right, in
scripts/run_trophies.gd ORDER). `--verify` compares without writing.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_battlefield_pixel_art import P, Canvas  # noqa: E402  (shared palette)

SIZE = 24
OUTPUT = Path("assets/trophies/trophy_icons_8x24.png")
ORDER = ["warlord_skull", "grave_lantern", "looter_satchel", "warden_stone",
         "phoenix_ash", "soul_lantern", "cursed_idol", "blood_millstone"]
# Extra ramps for the two curses and the phoenix fire.
X = {
    "e0": (92, 30, 18, 255), "e1": (168, 62, 26, 255), "e2": (232, 120, 44, 255), "e3": (255, 196, 92, 255),
    "c0": (58, 10, 18, 255), "c1": (112, 20, 32, 255), "c2": (176, 38, 48, 255), "c3": (232, 86, 86, 255),
    "j0": (22, 52, 34, 255), "j1": (40, 96, 58, 255), "j2": (88, 160, 88, 255), "j3": (164, 220, 128, 255),
    "t0": (18, 48, 64, 255), "t1": (34, 112, 139, 255), "t2": (81, 194, 215, 255), "t3": (184, 245, 255, 255),
}


def col(name):
    return X[name] if name in X else P[name]


class Icon(Canvas):
    def put(self, x, y, name):
        self.set(x, y, col(name))

    def box(self, x0, y0, x1, y1, name):
        self.rect(x0, y0, x1, y1, col(name))

    def oval(self, cx, cy, rx, ry, name):
        self.ellipse(cx, cy, rx, ry, col(name))

    def row(self, y, x0, x1, name):
        for x in range(x0, x1 + 1):
            self.put(x, y, name)

    def outline(self):
        ink = P["ink"]
        solid = {(x, y) for y in range(self.h) for x in range(self.w) if self.px[y][x][3] > 0}
        for y in range(self.h):
            for x in range(self.w):
                if (x, y) in solid:
                    continue
                if any((x + dx, y + dy) in solid for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    self.px[y][x] = ink


def warlord_skull():
    c = Icon(SIZE, SIZE)
    # crown
    c.box(6, 4, 17, 7, "g2")
    for x in (6, 11, 17):
        c.box(x, 1, x, 4, "g2")
        c.put(x, 1, "g4")
    c.box(11, 1, 12, 4, "g2")
    c.row(4, 6, 17, "g3")
    c.put(9, 6, "v3"); c.put(14, 6, "v3"); c.put(12, 5, "c2")
    # skull
    c.oval(11.5, 13, 7, 6, "b2")
    c.oval(11.5, 12, 6, 4, "b3")
    c.box(8, 17, 15, 20, "b2")
    c.box(7, 11, 9, 13, "ink"); c.box(14, 11, 16, 13, "ink")
    c.put(8, 12, "c3"); c.put(15, 12, "c3")
    c.box(11, 15, 12, 16, "b0")
    for x in (9, 11, 13, 15):
        c.box(x, 19, x, 20, "b0")
    c.row(17, 8, 15, "b1")
    c.outline()
    return c


def grave_lantern():
    c = Icon(SIZE, SIZE)
    # hanging hook (kept off the canvas edge so the ink outline fits)
    c.box(11, 1, 12, 3, "i2")
    c.put(10, 2, "i2"); c.put(13, 2, "i2")
    c.box(7, 4, 16, 5, "i1"); c.row(4, 7, 16, "i2")
    c.box(7, 19, 16, 21, "i1"); c.row(19, 7, 16, "i2")
    c.box(8, 6, 15, 18, "v1")
    c.box(9, 7, 14, 17, "v2")
    c.oval(11.5, 12, 2.5, 4, "v3")
    c.box(11, 10, 12, 13, "v4")
    for x in (7, 16):
        c.box(x, 6, x, 18, "i1")
    c.box(11, 6, 12, 18, "i0")
    c.put(11, 11, "v4"); c.put(12, 12, "v4")
    c.outline()
    return c


def looter_satchel():
    c = Icon(SIZE, SIZE)
    c.oval(11.5, 14, 8, 7, "r2")
    c.oval(11, 13, 7, 5.5, "r3")
    c.box(8, 6, 15, 8, "r2")
    c.row(8, 7, 16, "r1")
    c.box(10, 9, 13, 11, "g2"); c.put(11, 10, "g4")
    c.oval(9, 15, 2, 1.5, "r4")
    # spilled coins
    for cx, cy in ((4, 19), (18, 20), (7, 21), (16, 4)):
        c.oval(cx, cy, 2, 1.5, "g2")
        c.put(cx, cy, "g4")
    c.put(5, 18, "g3")
    c.outline()
    return c


def warden_stone():
    c = Icon(SIZE, SIZE)
    # rune shield / standing stone
    c.box(5, 4, 18, 14, "s3")
    c.oval(11.5, 15, 6.5, 6, "s3")
    c.box(6, 5, 17, 13, "s4")
    c.oval(11.5, 14, 5.5, 5, "s4")
    c.row(4, 6, 17, "s5")
    c.box(5, 4, 5, 13, "s5")
    # gold rim and rune
    c.row(3, 6, 17, "g2"); c.put(5, 3, "g3"); c.put(18, 3, "g3")
    # Algiz-like ward rune: a stem with two arms rising from its middle.
    c.box(11, 9, 12, 18, "t2")
    for k in range(5):
        c.box(10 - k, 12 - k, 10 - k, 13 - k, "t2")
        c.box(13 + k, 12 - k, 13 + k, 13 - k, "t2")
    c.put(6, 8, "t3"); c.put(17, 8, "t3"); c.put(11, 9, "t3"); c.put(12, 18, "t1")
    c.outline()
    return c


def phoenix_ash():
    c = Icon(SIZE, SIZE)
    # ash pile
    c.oval(11.5, 19, 8, 3, "s2")
    c.oval(11.5, 18, 6, 2, "s4")
    c.put(8, 18, "s5"); c.put(14, 19, "s5")
    # rising flame feather
    c.oval(11.5, 11, 4, 7, "e1")
    c.oval(11.5, 12, 3, 5, "e2")
    c.oval(11.5, 13, 1.5, 3, "e3")
    c.box(11, 2, 12, 5, "e1")
    c.put(12, 1, "e2")
    for k, (x, y) in enumerate(((7, 8), (16, 7), (6, 12), (17, 12))):
        c.put(x, y, "e2" if k % 2 else "e1")
        c.put(x + (1 if x < 12 else -1), y + 1, "e1")
    c.put(5, 4, "e3"); c.put(18, 3, "e3")
    c.outline()
    return c


def soul_lantern():
    c = Icon(SIZE, SIZE)
    # floating ghostly skull wisp in a gold cage
    c.oval(11.5, 11, 6, 6, "t1")
    c.oval(11.5, 10, 4.5, 4.5, "t2")
    c.box(9, 9, 10, 11, "ink"); c.box(13, 9, 14, 11, "ink")
    c.put(9, 9, "t3"); c.put(13, 9, "t3")
    c.put(11, 12, "t0"); c.put(12, 12, "t0")
    for x in (10, 12, 14):
        c.put(x, 14, "t3")
    c.row(15, 10, 13, "t1")
    c.put(10, 7, "t3"); c.put(11, 7, "t3")
    for x in (5, 18):
        c.box(x, 5, x, 17, "g2")
    c.row(4, 6, 17, "g2"); c.row(18, 6, 17, "g2")
    c.put(5, 4, "g3"); c.put(18, 4, "g3"); c.put(5, 18, "g1"); c.put(18, 18, "g1")
    c.box(11, 19, 12, 22, "t1")
    c.put(11, 22, "t2"); c.put(8, 20, "t2"); c.put(15, 21, "t2")
    c.box(11, 1, 12, 3, "g2")
    c.outline()
    return c


def cursed_idol():
    c = Icon(SIZE, SIZE)
    c.box(7, 19, 16, 22, "g1"); c.row(19, 7, 16, "g2")
    c.oval(11.5, 11, 6, 8, "j1")
    c.oval(11, 10, 5, 6.5, "j2")
    c.box(9, 3, 14, 5, "j1")
    c.put(10, 2, "j2"); c.put(13, 2, "j2")
    c.box(8, 9, 10, 10, "ink"); c.box(13, 9, 15, 10, "ink")
    c.put(9, 9, "c3"); c.put(14, 9, "c3")
    c.row(14, 9, 14, "ink")
    for x in (9, 11, 13):
        c.put(x, 15, "b2")
    c.put(10, 6, "j3"); c.put(9, 7, "j3")
    # gold collar
    c.row(17, 7, 16, "g3"); c.row(18, 8, 15, "g2")
    c.outline()
    return c


def blood_millstone():
    c = Icon(SIZE, SIZE)
    c.oval(11.5, 11.5, 9.5, 9.5, "s2")
    c.oval(11.5, 11.5, 8.5, 8.5, "s3")
    c.oval(10.5, 10.5, 7, 7, "s4")
    c.oval(11.5, 11.5, 2.5, 2.5, "ink")
    # grooves
    for (x0, y0, x1, y1) in ((11, 3, 11, 8), (3, 11, 8, 11), (15, 12, 20, 12), (12, 15, 12, 20)):
        c.box(x0, y0, x1, y1, "s2")
    # blood
    c.oval(15, 6, 3, 2.5, "c1")
    c.oval(15, 6, 2, 1.5, "c2")
    c.box(17, 8, 17, 12, "c1")
    c.box(6, 15, 7, 18, "c1")
    c.put(17, 13, "c2"); c.put(6, 19, "c2"); c.put(14, 5, "c3")
    c.outline()
    return c


DRAWERS = {
    "warlord_skull": warlord_skull, "grave_lantern": grave_lantern, "looter_satchel": looter_satchel,
    "warden_stone": warden_stone, "phoenix_ash": phoenix_ash, "soul_lantern": soul_lantern,
    "cursed_idol": cursed_idol, "blood_millstone": blood_millstone,
}


def to_image(canvas: Canvas) -> Image.Image:
    im = Image.new("RGBA", (canvas.w, canvas.h))
    im.putdata([px for row in canvas.px for px in row])
    return im


def atlas() -> Image.Image:
    sheet = Image.new("RGBA", (SIZE * len(ORDER), SIZE), (0, 0, 0, 0))
    for index, trophy in enumerate(ORDER):
        sheet.paste(to_image(DRAWERS[trophy]()), (index * SIZE, 0))
    return sheet


def main():
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
        print("PASS: trophy icons match the pixel source")
        return
    args.output.parent.mkdir(parents=True, exist_ok=True)
    image.save(args.output)
    print(f"generated: {args.output}")


if __name__ == "__main__":
    main()
