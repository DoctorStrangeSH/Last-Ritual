"""Verify all 72 displayed Soul Altar combinations are assembled from the correct art.

The large review sheet is candidate-only, never a production texture.
"""
import importlib.util
import tempfile
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "necro_sheet", ROOT / "tools/render_necro_modular_preview.py"
)
sheet = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(sheet)


class SoulAltarFullSheetIntegrityTests(unittest.TestCase):
    def test_every_direction_level_and_branch_at_native_scale(self):
        with tempfile.TemporaryDirectory() as folder:
            out = Path(folder) / "all_72.png"
            sheet.render(out, all_levels=True, scale=1)
            with Image.open(out) as src:
                board = src.convert("RGB")
            self.assertEqual(board.size, (1132, 1908))
            row_height = sheet.LABEL + sheet.COMPOSITE[1] + sheet.GAP
            level_height = sheet.LEVEL_HEADER + len(sheet.BRANCHES) * row_height + sheet.GAP
            for level_idx, level in enumerate((1, 2, 3)):
                with Image.open(sheet.ART / f"base/level_{level}.png") as src:
                    base = src.convert("RGBA")
                for branch_idx, (branch, _) in enumerate(sheet.BRANCHES):
                    with Image.open(sheet.ART / f"weapon/{branch}/weapon_8way.png") as src:
                        atlas = src.convert("RGBA")
                    for direction in range(8):
                        with self.subTest(level=level, branch=branch, direction=direction):
                            weapon = atlas.crop((direction * 128, 0, (direction + 1) * 128, 128))
                            expected = Image.new("RGBA", sheet.COMPOSITE, (0, 0, 0, 0))
                            expected.alpha_composite(base, (0, 0))
                            expected.alpha_composite(weapon, (0, 28))
                            x0 = sheet.GAP + direction * (128 + sheet.GAP)
                            y0 = (sheet.HEADER + level_idx * level_height
                                  + sheet.LEVEL_HEADER + branch_idx * row_height + sheet.LABEL)
                            checked = 0
                            # Avoid frame border and direction text at top-left.
                            for y in range(32, sheet.COMPOSITE[1] - 2):
                                for x in range(32, 126):
                                    rgb = expected.getpixel((x, y))
                                    if rgb[3] != 255:
                                        continue
                                    self.assertEqual(board.getpixel((x0 + x, y0 + y)), rgb[:3])
                                    checked += 1
                            self.assertGreater(checked, 50)


if __name__ == "__main__":
    unittest.main()
