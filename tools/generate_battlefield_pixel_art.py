#!/usr/bin/env python3
"""Hand-authored pixel art for the TD battlefield (ground, road, pads, altar, props, gate, wall).

This file IS the editable source of the battlefield art: every sprite is drawn
with explicit pixel operations on a fixed palette (no filters, no scaling).
Output goes to assets/battlefield/candidate/. `--verify` regenerates in memory
and compares RGBA pixels with the committed PNGs without writing anything.
Requires Pillow.
"""
from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

from PIL import Image

ROOT = Path("assets/battlefield/candidate")

# One shared palette. Ramps run dark -> light. Matches the Soul Altar kit
# (deep outline, warm gold, soul violet) with cool slate ground.
P = {
    "clear": (0, 0, 0, 0),
    "ink": (16, 13, 26, 255),
    # cool slate flagstones
    "s0": (24, 24, 34, 255), "s1": (33, 33, 45, 255), "s2": (43, 43, 57, 255),
    "s3": (56, 56, 71, 255), "s4": (73, 72, 89, 255), "s5": (95, 93, 112, 255),
    # moss / lichen
    "m0": (24, 40, 36, 255), "m1": (35, 58, 47, 255), "m2": (52, 82, 60, 255),
    # worn road stone (warm)
    "r0": (30, 24, 23, 255), "r1": (47, 38, 33, 255), "r2": (66, 54, 45, 255),
    "r3": (88, 72, 58, 255), "r4": (113, 94, 75, 255), "r5": (142, 120, 96, 255),
    # gold / bronze
    "g0": (66, 42, 22, 255), "g1": (112, 76, 36, 255), "g2": (170, 124, 62, 255),
    "g3": (226, 180, 106, 255), "g4": (255, 236, 182, 255),
    # soul violet
    "v0": (38, 15, 58, 255), "v1": (82, 26, 108, 255), "v2": (140, 45, 178, 255),
    "v3": (205, 98, 245, 255), "v4": (255, 196, 252, 255),
    # bone
    "b0": (96, 84, 70, 255), "b1": (160, 145, 120, 255), "b2": (214, 202, 176, 255), "b3": (240, 233, 214, 255),
    # iron
    "i0": (28, 30, 38, 255), "i1": (50, 54, 66, 255), "i2": (82, 88, 104, 255),
}


class Canvas:
    def __init__(self, w: int, h: int, wrap: bool = False):
        self.w, self.h, self.wrap = w, h, wrap
        self.px = [[P["clear"]] * w for _ in range(h)]

    def set(self, x, y, color):
        x, y = int(round(x)), int(round(y))
        if self.wrap:
            x %= self.w
            y %= self.h
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = P[color] if isinstance(color, str) else color

    def get(self, x, y):
        x, y = int(x), int(y)
        if self.wrap:
            x %= self.w
            y %= self.h
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[y][x]
        return P["clear"]

    def rect(self, x0, y0, x1, y1, color):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                self.set(x, y, color)

    def ellipse(self, cx, cy, rx, ry, color):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((x - cx) / max(rx, 0.01)) ** 2 + ((y - cy) / max(ry, 0.01)) ** 2 <= 1.0:
                    self.set(x, y, color)

    def ring(self, cx, cy, rx, ry, thickness, color):
        for y in range(int(cy - ry) - 2, int(cy + ry) + 3):
            for x in range(int(cx - rx) - 2, int(cx + rx) + 3):
                d = math.hypot((x - cx) / max(rx, 0.01), (y - cy) / max(ry, 0.01))
                if 1.0 - thickness / max(rx, ry) <= d <= 1.0:
                    self.set(x, y, color)

    def line(self, x0, y0, x1, y1, color):
        steps = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for i in range(steps + 1):
            t = i / max(steps, 1)
            self.set(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, color)

    def outline(self, color="ink"):
        """1px outline around every opaque pixel (only into transparent pixels)."""
        src = [row[:] for row in self.px]
        for y in range(self.h):
            for x in range(self.w):
                if src[y][x][3] != 0:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < self.w and 0 <= ny < self.h and src[ny][nx][3] != 0 and src[ny][nx] != P[color]:
                        self.px[y][x] = P[color]
                        break

    def image(self) -> Image.Image:
        im = Image.new("RGBA", (self.w, self.h))
        im.putdata([c for row in self.px for c in row])
        return im


# ---------------------------------------------------------------- ground
def voronoi_cells(size: int, count: int, rng: random.Random, relax: int = 2):
    """Toroidal Voronoi: returns (owner grid, second-distance gap grid, points)."""
    pts = [(rng.uniform(0, size), rng.uniform(0, size)) for _ in range(count)]
    def assign(points):
        owner = [[0] * size for _ in range(size)]
        gap = [[0.0] * size for _ in range(size)]
        for y in range(size):
            for x in range(size):
                best, second, who = 1e9, 1e9, 0
                for i, (px, py) in enumerate(points):
                    dx = min(abs(x - px), size - abs(x - px))
                    dy = min(abs(y - py), size - abs(y - py))
                    d = math.hypot(dx, dy)
                    if d < best:
                        best, second, who = d, best, i
                    elif d < second:
                        second = d
                owner[y][x] = who
                gap[y][x] = second - best
        return owner, gap
    for _ in range(relax):  # Lloyd relaxation keeps slab sizes even
        owner, _ = assign(pts)
        sums = [[0.0, 0.0, 0.0, 0.0, 0] for _ in pts]
        for y in range(size):
            for x in range(size):
                a = sums[owner[y][x]]
                a[0] += math.cos(x / size * math.tau); a[1] += math.sin(x / size * math.tau)
                a[2] += math.cos(y / size * math.tau); a[3] += math.sin(y / size * math.tau); a[4] += 1
        pts = [((math.atan2(a[1], a[0]) / math.tau % 1) * size, (math.atan2(a[3], a[2]) / math.tau % 1) * size) if a[4] else pts[i]
               for i, a in enumerate(sums)]
    owner, gap = assign(pts)
    return owner, gap, pts


def shaded_cells(c: Canvas, owner, gap, tones, mortar, mortar_width, light_of, dark_of, rng):
    size = c.w
    for y in range(size):
        for x in range(size):
            if gap[y][x] < mortar_width:
                c.set(x, y, mortar)
                continue
            tone = tones[owner[y][x]]
            up, left = owner[(y - 1) % size][x], owner[y][(x - 1) % size]
            down, right = owner[(y + 1) % size][x], owner[y][(x + 1) % size]
            edge_up = gap[(y - 1) % size][x] < mortar_width
            edge_left = gap[y][(x - 1) % size] < mortar_width
            edge_down = gap[(y + 1) % size][x] < mortar_width
            edge_right = gap[y][(x + 1) % size] < mortar_width
            if edge_up:
                c.set(x, y, light_of[tone])      # light from above
            elif edge_down or (edge_right and (x + y) % 2 == 0):
                c.set(x, y, dark_of[tone])
            else:
                c.set(x, y, tone)


def ground_tile(size=256, seed=11) -> Canvas:
    """Tileable courtyard of irregular slate flagstones (relaxed Voronoi), cracks, moss, runes."""
    rng = random.Random(seed)
    c = Canvas(size, size, wrap=True)
    owner, gap, pts = voronoi_cells(size, 60, rng)
    tones = [rng.choice(["s1", "s1", "s2", "s2", "s2"]) for _ in pts]
    light = {"s1": "s2", "s2": "s3", "s3": "s4"}
    dark = {"s1": "s0", "s2": "s1", "s3": "s2"}
    shaded_cells(c, owner, gap, tones, "s0", 1.6, light, dark, rng)
    # surface grain
    for _ in range(size * size // 120):
        x, y = rng.randrange(size), rng.randrange(size)
        if c.get(x, y) != P["s0"]:
            t = tones[owner[y][x]]
            c.set(x, y, dark[t] if rng.random() < 0.7 else light[t])
    # cracks running across a few slabs
    for _ in range(9):
        x, y = rng.uniform(0, size), rng.uniform(0, size)
        a = rng.uniform(0, math.tau)
        for _ in range(rng.randint(8, 18)):
            c.set(x, y, "s0")
            a += rng.uniform(-0.6, 0.6)
            x += math.cos(a)
            y += math.sin(a)
    # moss creeping out of the mortar
    for _ in range(18):
        x, y = rng.randrange(size), rng.randrange(size)
        for _ in range(rng.randint(18, 40)):
            x += rng.choice((-1, 0, 1)); y += rng.choice((-1, 0, 1))
            if gap[int(y) % size][int(x) % size] < 3.2:
                c.set(x, y, rng.choice(["m0", "m1", "m1", "m2"]))
    # two slabs carry a faint engraved rune
    for i in rng.sample(range(len(pts)), 2):
        px, py = pts[i]
        for dx, dy in ((0, -3), (0, -2), (0, -1), (0, 0), (0, 1), (0, 2), (-2, -1), (2, -1), (-1, 2), (1, 2)):
            c.set(px + dx, py + dy, "s0")
        c.set(px, py - 3, "v1")
    return c


# ---------------------------------------------------------------- road
def road_tile(size=64, seed=23) -> Canvas:
    """Tileable worn cobblestones (warm stone) with dark earth between them."""
    rng = random.Random(seed)
    c = Canvas(size, size, wrap=True)
    owner, gap, pts = voronoi_cells(size, 22, rng)
    tones = [rng.choice(["r2", "r3", "r3", "r3", "r4"]) for _ in pts]
    light = {"r2": "r3", "r3": "r4", "r4": "r5"}
    dark = {"r2": "r1", "r3": "r2", "r4": "r3"}
    shaded_cells(c, owner, gap, tones, "r0", 1.5, light, dark, rng)
    for _ in range(24):
        x, y = rng.randrange(size), rng.randrange(size)
        if gap[y][x] >= 1.5:
            c.set(x, y, dark[tones[owner[y][x]]])
    return c


# ---------------------------------------------------------------- pads
def pad(occupied: bool) -> Canvas:
    """64x64 circular build pad: dark stone dais, gold ring, violet rune band."""
    c = Canvas(64, 64)
    cx, cy = 31.5, 33.5
    c.ellipse(cx + 1, cy + 3, 29, 22, "ink")          # drop shadow
    c.ellipse(cx, cy + 2, 29, 22, "s0")                 # dais side (3/4 view)
    c.ellipse(cx, cy, 29, 21, "s2")                     # top surface
    c.ring(cx, cy, 29, 21, 2.2, "g1")
    c.ring(cx, cy, 28, 20, 1.2, "g2" if not occupied else "g3")
    for i in range(16):                                  # gold rivets
        a = i / 16 * math.tau
        c.set(cx + math.cos(a) * 27.5, cy + math.sin(a) * 19.8, "g3" if i % 4 == 0 else "g2")
    c.ellipse(cx, cy, 22, 15.5, "s1")
    c.ring(cx, cy, 22, 15.5, 1.0, "s3")
    # rune band: small glyphs on the ring between gold and the inner disc
    for i in range(12):
        a = i / 12 * math.tau + 0.13
        rx, ry = cx + math.cos(a) * 25.2, cy + math.sin(a) * 18.0
        glyph = i % 3
        tone = "v3" if occupied else "v2"
        c.set(rx, ry, tone)
        if glyph == 0:
            c.set(rx, ry - 1, tone)
        elif glyph == 1:
            c.set(rx + 1, ry, tone)
        else:
            c.set(rx, ry + 1, "v1")
    if not occupied:
        # central sigil: an inverted triangle inside a circle, soul violet
        c.ring(cx, cy, 9, 6.5, 1.0, "v1")
        for t in range(9):
            c.set(cx - 6 + t * 1.5, cy - 3, "v2")
        c.line(cx - 6, cy - 3, cx, cy + 4, "v2")
        c.line(cx + 6, cy - 3, cx, cy + 4, "v2")
        c.set(cx, cy, "v4")
        c.set(cx, cy - 1, "v3")
        # small cracks, the pad is old
        c.line(cx + 12, cy - 9, cx + 16, cy - 5, "s0")
        c.line(cx - 15, cy + 6, cx - 11, cy + 9, "s0")
    else:
        c.ellipse(cx, cy, 15, 10.5, "s0")                # worn socket under the tower
        c.ring(cx, cy, 15, 10.5, 1.0, "g1")
    return c


# ---------------------------------------------------------------- altar
def altar() -> Canvas:
    """128x128 Ritual Altar (the defended objective): stepped octagon, gold, soul crystal."""
    c = Canvas(128, 128)
    cx = 63.5
    # ground shadow
    c.ellipse(cx + 2, 104, 54, 18, "ink")
    # three stepped tiers (3/4 view): side then top
    tiers = [(52, 17, 104, "s1", "s3", "s0"), (42, 13, 95, "s2", "s4", "s1"), (31, 10, 87, "s2", "s5", "s1")]
    for rx, ry, cy, top, rim, side in tiers:
        c.ellipse(cx, cy + 5, rx, ry, side)
        # gilded front band on the tier side
        for x in range(int(cx - rx) + 2, int(cx + rx) - 1):
            t = (x - cx) / rx
            if abs(t) < 0.97:
                yb = cy + ry * math.sqrt(1 - t * t) + 2
                c.set(x, yb, "g2")
                c.set(x, yb + 1, "g1")
                if x % 6 == 0:
                    c.set(x, yb, "g4")
        c.ellipse(cx, cy, rx, ry, top)
        # rim light on the back edge, shadow on the front edge
        for i in range(72):
            a = i / 72 * math.tau
            px, py = cx + math.cos(a) * (rx - 0.5), cy + math.sin(a) * (ry - 0.5)
            c.set(px, py, rim if math.sin(a) < 0 else side)
    # rune circle on the top tier
    for i in range(14):
        a = i / 14 * math.tau
        c.set(cx + math.cos(a) * 24, 87 + math.sin(a) * 7.5, "v3" if i % 2 else "v2")
    # candles on the middle tier
    for dx, dy in ((-36, 93), (36, 93), (-24, 101), (24, 101)):
        c.rect(cx + dx - 1, dy - 7, cx + dx + 1, dy, "b2")
        c.set(cx + dx + 1, dy - 7, "b1")
        c.set(cx + dx, dy - 9, "g3")
        c.set(cx + dx, dy - 10, "g4")
        c.set(cx + dx, dy - 8, "v3")
    # skulls flanking the obelisk
    for dx in (-16, 16):
        skull(c, cx + dx, 84)
    # obelisk: dark plinth with gold bands
    c.rect(cx - 9, 66, cx + 9, 86, "s1")
    c.rect(cx - 9, 66, cx - 7, 86, "s3")
    c.rect(cx + 7, 66, cx + 9, 86, "s0")
    c.rect(cx - 10, 84, cx + 10, 86, "g1")
    c.rect(cx - 10, 84, cx + 10, 84, "g3")
    c.rect(cx - 10, 66, cx + 10, 68, "g1")
    c.rect(cx - 10, 66, cx + 10, 66, "g3")
    for y in (72, 78):
        c.set(cx, y, "v3")
        c.set(cx - 1, y + 1, "v2")
        c.set(cx + 1, y + 1, "v2")
    # soul crystal: faceted diamond floating above the plinth
    top, mid, bottom = 18, 42, 62
    for y in range(top, bottom + 1):
        half = (y - top) / (mid - top) * 11 if y <= mid else (bottom - y) / (bottom - mid) * 11
        for x in range(int(cx - half), int(cx + half) + 1):
            left = x < cx
            tone = ("v3" if y < mid else "v2") if left else ("v2" if y < mid else "v1")
            c.set(x, y, tone)
    c.line(cx, top + 2, cx, bottom - 2, "v4")
    c.line(cx - 6, mid - 6, cx - 2, mid - 12, "v4")
    c.set(cx - 3, mid - 3, "v4")
    # halo sparks
    for i in range(10):
        a = i / 10 * math.tau
        c.set(cx + math.cos(a) * 17, 40 + math.sin(a) * 21, "v3" if i % 2 else "v4")
    c.outline()
    return c


def skull(c: Canvas, x, y):
    c.ellipse(x, y - 1, 3.6, 3.2, "b2")
    c.rect(x - 2, y + 1, x + 2, y + 3, "b2")
    c.set(x - 1.5, y - 1, "ink")
    c.set(x + 1.5, y - 1, "ink")
    c.set(x, y + 1, "b0")
    c.set(x - 1, y + 3, "b0")
    c.set(x + 1, y + 3, "b0")
    c.set(x - 2, y - 3, "b3")


# ---------------------------------------------------------------- props
def props() -> Canvas:
    """8 decorative props, 32x32 each, in one 256x32 strip."""
    strip = Canvas(256, 32)
    painters = [prop_skull_pile, prop_broken_column, prop_candles, prop_bones,
                prop_rubble, prop_brazier, prop_tombstone, prop_mossy_rock]
    for index, paint in enumerate(painters):
        cell = Canvas(32, 32)
        cell.ellipse(16, 27, 12, 3.5, "ink")
        paint(cell)
        cell.outline()
        for y in range(32):
            for x in range(32):
                if cell.px[y][x][3]:
                    strip.px[y][index * 32 + x] = cell.px[y][x]
    return strip


def prop_skull_pile(c):
    for x, y in ((10, 23), (22, 23), (16, 16)):
        big_skull(c, x, y)


def big_skull(c: Canvas, x, y):
    c.ellipse(x, y - 1, 5.2, 4.6, "b2")
    c.rect(x - 3, y + 2, x + 3, y + 5, "b2")
    c.ellipse(x - 2.2, y - 0.5, 1.4, 1.6, "ink")
    c.ellipse(x + 2.2, y - 0.5, 1.4, 1.6, "ink")
    c.set(x - 2, y - 1, "v3")
    c.set(x, y + 2, "b0")
    for dx in (-2, 0, 2):
        c.set(x + dx, y + 5, "b0")
    c.set(x - 3, y - 4, "b3")
    c.set(x - 2, y - 5, "b3")
    c.set(x + 4, y + 1, "b1")


def prop_broken_column(c):
    c.rect(10, 12, 21, 26, "s3")
    c.rect(10, 12, 12, 26, "s4")
    c.rect(19, 12, 21, 26, "s1")
    c.rect(8, 25, 23, 27, "s2")
    c.rect(8, 25, 23, 25, "s4")
    for x, y in ((10, 12), (11, 11), (13, 10), (15, 11), (17, 9), (19, 11), (21, 12)):
        c.set(x, y, "s4")
    c.line(14, 13, 16, 20, "s0")
    c.rect(22, 23, 26, 26, "s2")
    c.set(22, 23, "s4")


def prop_candles(c):
    for x, y, h in ((11, 25, 9), (16, 26, 13), (21, 25, 7), (14, 27, 5)):
        c.rect(x - 1, y - h, x + 1, y, "b2")
        c.set(x - 1, y - h, "b3")
        c.set(x + 1, y, "b1")
        c.set(x, y - h - 1, "v3")
        c.set(x, y - h - 2, "v4")
        c.set(x, y - h - 3, "v3")
    c.line(9, 26, 23, 26, "b1")


def prop_bones(c):
    c.line(7, 22, 20, 18, "b2")
    c.line(7, 23, 20, 19, "b1")
    for ex, ey in ((7, 22), (20, 18)):
        c.ellipse(ex, ey, 1.6, 1.6, "b2")
    c.line(14, 25, 25, 25, "b2")
    for ex in (14, 25):
        c.ellipse(ex, 25, 1.5, 1.5, "b2")
    skull(c, 22, 20)


def prop_rubble(c):
    for x, y, rx, ry, tone in ((11, 24, 4, 3, "s3"), (19, 24, 5, 3, "s2"), (15, 20, 4, 3, "s4"), (23, 21, 2, 2, "s3")):
        c.ellipse(x, y, rx, ry, tone)
        c.set(x - rx + 1, y - 1, "s5")
        c.set(x + rx - 1, y + 1, "s1")


def prop_brazier(c):
    c.line(11, 27, 14, 19, "i1")
    c.line(21, 27, 18, 19, "i1")
    c.line(16, 27, 16, 20, "i0")
    c.ellipse(16, 18, 7, 2.5, "i2")
    c.ellipse(16, 17, 6, 1.6, "i0")
    for x, h in ((13, 5), (15, 9), (17, 11), (19, 6)):
        for k in range(h):
            c.set(x + (k % 3 == 1), 16 - k, "v4" if k < 2 else ("v3" if k < h - 3 else "v2"))
    c.set(16, 3, "v2")


def prop_tombstone(c):
    c.rect(10, 12, 21, 26, "s3")
    c.ellipse(15.5, 12, 5.5, 4, "s3")
    c.rect(10, 10, 11, 26, "s4")
    c.rect(20, 12, 21, 26, "s1")
    c.line(13, 15, 18, 15, "s1")
    c.line(15, 13, 15, 21, "s1")
    c.set(15, 18, "v3")
    c.rect(8, 26, 23, 27, "m1")
    c.set(9, 25, "m2")
    c.set(22, 25, "m2")


def prop_mossy_rock(c):
    c.ellipse(16, 21, 10, 6, "s2")
    c.ellipse(15, 19, 8, 4, "s3")
    c.set(10, 18, "s5")
    c.set(11, 17, "s4")
    for x, y in ((12, 16), (13, 16), (14, 15), (17, 16), (18, 17), (20, 18), (21, 19), (16, 15)):
        c.set(x, y, "m2" if (x + y) % 2 else "m1")


# ---------------------------------------------------------------- gate & wall
def gate() -> Canvas:
    """48x64 western entrance: stone arch with an iron portcullis."""
    c = Canvas(48, 64)
    c.rect(4, 6, 43, 61, "s2")
    c.rect(4, 6, 7, 61, "s4")
    c.rect(40, 6, 43, 61, "s0")
    for y in range(10, 60, 8):
        c.line(4, y, 43, y, "s1")
    c.ellipse(24, 22, 13, 13, "ink")
    c.rect(11, 22, 37, 61, "ink")
    for x in range(13, 37, 4):
        c.line(x, 14 if 18 <= x <= 30 else 20, x, 58, "i2")
        c.line(x + 1, 14 if 18 <= x <= 30 else 20, x + 1, 58, "i1")
    for y in range(26, 58, 8):
        c.line(12, y, 36, y, "i2")
    c.set(24, 7, "v3")
    c.set(23, 8, "v2")
    c.set(25, 8, "v2")
    c.rect(4, 4, 43, 6, "g1")
    c.line(4, 4, 43, 4, "g3")
    c.outline()
    return c


def wall_segment() -> Canvas:
    """48x66 eastern citadel wall tile with a lit arrow slit (stacks vertically)."""
    c = Canvas(48, 66)
    c.rect(8, 0, 39, 65, "s2")
    c.rect(8, 0, 10, 65, "s4")
    c.rect(37, 0, 39, 65, "s0")
    for y in range(0, 66, 11):
        c.line(8, y, 39, y, "s1")
        off = 0 if (y // 11) % 2 == 0 else 8
        for x in range(12 + off, 38, 16):
            c.line(x, y, x, y + 10, "s1")
    c.rect(2, 10, 45, 30, "s3")
    c.rect(2, 10, 45, 11, "s5")
    c.rect(2, 29, 45, 30, "s1")
    for x in range(4, 44, 8):
        c.rect(x, 6, x + 4, 10, "s3")
        c.set(x, 6, "s5")
    c.rect(21, 15, 26, 26, "ink")
    c.rect(22, 17, 25, 25, "g2")
    c.rect(23, 18, 24, 24, "g4")
    c.outline()
    return c


def assets():
    yield "ground_256.png", ground_tile().image()
    yield "road_64.png", road_tile().image()
    yield "pad_empty_64.png", pad(False).image()
    yield "pad_built_64.png", pad(True).image()
    yield "altar_128.png", altar().image()
    yield "props_8x32.png", props().image()
    yield "gate_48x64.png", gate().image()
    yield "wall_48x66.png", wall_segment().image()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify", action="store_true", help="compare with committed PNGs, never write")
    parser.add_argument("--output", type=Path, default=ROOT)
    args = parser.parse_args()
    failed = []
    for name, image in assets():
        target = args.output / name
        if args.verify:
            if not target.is_file():
                failed.append(f"missing: {target}")
                continue
            with Image.open(target) as existing:
                if existing.convert("RGBA").tobytes() != image.tobytes():
                    failed.append(f"pixel mismatch: {target}")
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        image.save(target)
        print(f"generated: {target}")
    if failed:
        raise SystemExit("\n".join(failed))
    if args.verify:
        print("PASS: battlefield pixel art matches its reproducible source")


if __name__ == "__main__":
    main()
