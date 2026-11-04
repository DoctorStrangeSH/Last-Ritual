#!/usr/bin/env python3
"""Hand-authored pixel art for the night's Dark Merchant (48x48).

The file IS the editable source: explicit pixel operations on the shared
battlefield palette (plus the trophy ramps), one ink outline.
Output: assets/night/dark_merchant_48.png. `--verify` compares without writing.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_trophy_icons import Icon, to_image  # noqa: E402  (shared palette + outline)

SIZE = 48
OUTPUT = Path("assets/night/dark_merchant_48.png")


def trapezoid(c: Icon, y0: int, y1: int, left0: float, right0: float, left1: float, right1: float, name: str) -> None:
    """Fill rows y0..y1, edges interpolated from (left0,right0) to (left1,right1)."""
    for y in range(y0, y1 + 1):
        t = 0.0 if y1 == y0 else (y - y0) / (y1 - y0)
        c.row(y, int(round(left0 + (left1 - left0) * t)), int(round(right0 + (right1 - right0) * t)), name)


def merchant() -> Icon:
    c = Icon(SIZE, SIZE)
    # --- staff and soul lantern (right hand) ---
    c.box(37, 9, 38, 45, "i1")
    c.box(37, 9, 37, 45, "i2")
    c.box(34, 4, 41, 5, "g2"); c.row(4, 35, 40, "g3")
    c.box(35, 6, 40, 13, "t0")
    c.box(36, 7, 39, 12, "t1")
    c.box(37, 8, 38, 11, "t2")
    c.put(37, 9, "t3"); c.put(38, 8, "t3")
    c.box(34, 6, 34, 13, "g2"); c.box(41, 6, 41, 13, "g1")
    c.box(34, 14, 41, 15, "g2"); c.row(15, 35, 40, "g1")
    c.box(37, 2, 38, 3, "g2")
    # --- robe body (wide hem) ---
    trapezoid(c, 20, 45, 15, 30, 8, 35, "v1")
    trapezoid(c, 21, 44, 17, 26, 11, 28, "v2")
    trapezoid(c, 24, 44, 13, 15, 9, 12, "v0")      # shadow fold left
    c.box(21, 26, 22, 44, "v0")                     # centre fold
    c.row(45, 8, 35, "g1"); c.row(44, 9, 34, "g2")   # gilded hem
    for x in range(10, 34, 4):
        c.put(x, 44, "g3")
    # --- hood ---
    trapezoid(c, 6, 20, 21, 23, 13, 31, "v1")
    trapezoid(c, 8, 19, 21, 23, 15, 29, "v2")
    c.put(22, 5, "v2"); c.put(22, 4, "v1")
    # face void and eyes
    trapezoid(c, 12, 19, 20, 24, 17, 27, "ink")
    c.put(19, 15, "t2"); c.put(20, 15, "t3")
    c.put(24, 15, "t2"); c.put(25, 15, "t3")
    c.put(22, 18, "v0")
    # gold hood trim
    for y in range(9, 20):
        t = (y - 9) / 11
        c.put(int(round(21 - 6 * t)), y, "g2")
        c.put(int(round(23 + 6 * t)), y, "g2")
    c.put(22, 7, "g3")
    # --- arm reaching to the staff ---
    trapezoid(c, 22, 25, 28, 30, 30, 37, "v1")
    c.row(23, 30, 36, "v2")
    c.box(35, 21, 38, 24, "b2"); c.put(36, 21, "b3")   # bony hand
    # --- belt with skull charm ---
    c.row(29, 12, 31, "r1"); c.row(30, 12, 31, "r2")
    c.box(20, 28, 23, 31, "g2")
    c.oval(21.5, 33.5, 2.5, 2.2, "b2")
    c.put(20, 33, "ink"); c.put(23, 33, "ink"); c.put(21, 35, "b0"); c.put(22, 35, "b0")
    # --- sack of souls (left) ---
    c.oval(9, 38, 5, 5, "r2")
    c.oval(8.5, 37, 4, 3.5, "r3")
    c.box(8, 31, 10, 33, "r1")
    c.put(7, 36, "r4")
    c.put(10, 34, "v3"); c.put(11, 35, "v4")      # soul glow leaking out
    c.outline()
    return c


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify", action="store_true", help="compare with the committed PNG, never write")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    image = to_image(merchant())
    if args.verify:
        if not args.output.is_file():
            raise SystemExit(f"missing: {args.output}")
        with Image.open(args.output) as committed:
            if committed.convert("RGBA").tobytes() != image.tobytes():
                raise SystemExit(f"pixel mismatch: {args.output}")
        print("PASS: dark merchant matches the pixel source")
        return
    args.output.parent.mkdir(parents=True, exist_ok=True)
    image.save(args.output)
    print(f"generated: {args.output}")


if __name__ == "__main__":
    main()
