"""Native-scale regression guards for candidate Soul Altar stone, gold and soul runes.

These tests quantify colour usage and distinct L1-L3 outlines, not artistic approval.
They use the editable Pillow source rather than relying on image compression bytes.
"""
import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/generate_necro_modular_candidates.py"
spec = importlib.util.spec_from_file_location("necro_candidate_source", SOURCE)
art = importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)


class SoulAltarBaseReadabilityTests(unittest.TestCase):
    def test_each_level_has_stone_gold_and_violet_runes(self):
        for level in (1, 2, 3):
            with self.subTest(level=level):
                pixels = list(art.base(level).getdata())
                stone = sum(p in (1, 2, 3, 4, 5) for p in pixels)
                gold = sum(p in (6, 7) for p in pixels)
                violet = sum(p in (8, 9, 10, 11, 12) for p in pixels)
                self.assertGreater(stone, 300, "stone architecture disappeared")
                self.assertGreater(gold, 25, "gold accents disappeared")
                self.assertGreater(violet, 10, "violet soul runes disappeared")

    def test_level_silhouettes_are_unique_at_native_scale(self):
        masks = []
        for level in (1, 2, 3):
            image = art.base(level)
            mask = image.point(lambda value: 0 if value == 0 else 255)
            masks.append(mask.tobytes())
        self.assertEqual(len(set(masks)), 3, "tiers must not share the same silhouette")

    def test_atlas_palette_is_fixed_and_transparent(self):
        self.assertEqual(art.PALETTE[0], (0, 0, 0, 0))
        self.assertEqual(len(art.PALETTE), 20)
        for level in (1, 2, 3):
            self.assertLess(max(art.base(level).getdata()), len(art.PALETTE))


if __name__ == "__main__":
    unittest.main()
