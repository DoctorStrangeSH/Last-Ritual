"""Regression checks that the 1x review board contains the actual source layers."""
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets/spire/towers/necro/candidate"
RENDER = ROOT / "tools/render_soul_altar_compact_review.py"
BRANCHES = ("base", "reaper", "legion")


class CompactArtReviewTests(unittest.TestCase):
    def test_all_nine_cards_use_correct_base_and_north_weapon(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "review.png"
            subprocess.run([sys.executable, str(RENDER), "--output", str(output)],
                           cwd=ROOT, check=True, capture_output=True, text=True)
            with Image.open(output) as source:
                board = source.convert("RGB")
            self.assertEqual(board.size, (472, 662))
            for row, branch in enumerate(BRANCHES):
                with Image.open(ART / f"weapon/{branch}/weapon_8way.png") as source:
                    weapon = source.convert("RGBA").crop((0, 0, 128, 128))
                for col, level in enumerate((1, 2, 3)):
                    with self.subTest(branch=branch, level=level):
                        with Image.open(ART / f"base/level_{level}.png") as source:
                            base = source.convert("RGBA")
                        composite = Image.new("RGBA", (128, 156), (0, 0, 0, 0))
                        composite.alpha_composite(base)
                        composite.alpha_composite(weapon, (0, 28))
                        # Compare only opaque source pixels inside the card (away from its border).
                        checked = 0
                        for y in range(2, 154):
                            for x in range(2, 126):
                                red, green, blue, alpha = composite.getpixel((x, y))
                                if alpha != 255:
                                    continue
                                actual = board.getpixel((20 + col * 144 + x,
                                                         54 + row * 196 + 24 + y))
                                self.assertEqual(actual, (red, green, blue))
                                checked += 1
                        self.assertGreater(checked, 100, "review card lacks visible sprite")

if __name__ == "__main__":
    unittest.main()
