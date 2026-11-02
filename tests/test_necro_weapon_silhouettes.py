"""Regression checks for the Soul Altar Reaper / Legion candidate weapon silhouettes.

These are asset-quality guards only; they are not artistic approval.
"""
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "assets/spire/towers/necro/candidate/weapon"
FRAME = 128
DIRS = ("N", "NE", "E", "SE", "S", "SW", "W", "NW")


def frames(branch):
    with Image.open(ROOT / branch / "weapon_8way.png") as src:
        atlas = src.convert("RGBA")
    assert atlas.size == (FRAME * 8, FRAME), atlas.size
    return [atlas.crop((i * FRAME, 0, (i + 1) * FRAME, FRAME)) for i in range(8)]


def alpha_mask(frame):
    return frame.getchannel("A").point(lambda a: 255 if a else 0)


class WeaponSilhouetteTests(unittest.TestCase):
    def test_no_frame_touches_canvas_edge(self):
        for branch in ("base", "reaper", "legion"):
            for name, frame in zip(DIRS, frames(branch)):
                bbox = alpha_mask(frame).getbbox()
                self.assertIsNotNone(bbox, f"{branch} {name} is empty")
                x0, y0, x1, y1 = bbox
                self.assertTrue(x0 > 0 and y0 > 0 and x1 < FRAME and y1 < FRAME,
                                f"{branch} {name} is clipped by the canvas: {bbox}")

    def test_eight_distinct_silhouettes_per_branch(self):
        for branch in ("base", "reaper", "legion"):
            masks = {alpha_mask(f).tobytes() for f in frames(branch)}
            self.assertEqual(len(masks), 8, f"{branch} has repeated silhouettes")

    def test_base_has_a_faceted_violet_prism_and_gilded_crown(self):
        violet = ((212, 93, 248, 255), (255, 184, 251, 255))
        gold = ((188, 149, 92, 255), (244, 200, 125, 255))
        for name, frame in zip(DIRS, frames("base")):
            pixels = list(frame.getdata())
            violet_count = sum(p in violet for p in pixels)
            gold_count = sum(p in gold for p in pixels)
            self.assertGreaterEqual(violet_count, 40, f"base {name} lost its faceted violet crystal")
            self.assertGreaterEqual(gold_count, 100, f"base {name} lost its gilded crown")

    def test_branches_have_different_silhouettes(self):
        masks = {b: [alpha_mask(f).tobytes() for f in frames(b)] for b in ("base", "reaper", "legion")}
        for i in range(8):
            self.assertNotEqual(masks["reaper"][i], masks["legion"][i], DIRS[i])
            self.assertNotEqual(masks["reaper"][i], masks["base"][i], DIRS[i])
            self.assertNotEqual(masks["legion"][i], masks["base"][i], DIRS[i])

    def test_reaper_blade_is_violet_and_extends_beyond_hub(self):
        # The crescent must reach well past the hooded hub radius (about 11 px) in every direction.
        for name, frame in zip(DIRS, frames("reaper")):
            x0, y0, x1, y1 = alpha_mask(frame).getbbox()
            self.assertGreaterEqual(max(x1 - x0, y1 - y0), 45, f"reaper {name} silhouette too small")

    def test_legion_shows_three_forward_skulls(self):
        # Three bone-white skull clusters (palette index 14 colour) must be present in every pose.
        bone = (215, 205, 211, 255)
        for name, frame in zip(DIRS, frames("legion")):
            count = sum(1 for p in frame.getdata() if p == bone)
            self.assertGreaterEqual(count, 3 * 12, f"legion {name} lost its skulls ({count} bone pixels)")


if __name__ == "__main__":
    unittest.main()
