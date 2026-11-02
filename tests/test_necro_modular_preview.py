import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "render_necro_modular_preview", ROOT / "tools" / "render_necro_modular_preview.py"
)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class SoulAltarContactSheetTests(unittest.TestCase):
    def test_single_level_sheet_has_three_weapon_rows(self):
        self.assertEqual(MODULE.sheet_dimensions(1), (2156, 1132))

    def test_all_levels_sheet_contains_72_poses_without_row_overlap(self):
        self.assertEqual(MODULE.sheet_dimensions(3), (2156, 3312))
        row_height = MODULE.LABEL + MODULE.COMPOSITE[1] * MODULE.SCALE + MODULE.GAP
        level_height = MODULE.LEVEL_HEADER + len(MODULE.BRANCHES) * row_height + MODULE.GAP
        self.assertEqual(level_height, 1090)
        self.assertEqual(3 * len(MODULE.BRANCHES) * 8, 72)

    def test_native_1x_sheet_uses_exact_source_pixel_dimensions(self):
        self.assertEqual(MODULE.sheet_dimensions(1, scale=1), (1132, 664))
        self.assertEqual(MODULE.sheet_dimensions(3, scale=1), (1132, 1908))

    def test_invalid_level_count_and_scale_are_rejected(self):
        for count in (0, 4):
            with self.subTest(count=count):
                with self.assertRaises(ValueError):
                    MODULE.sheet_dimensions(count)
        for scale in (0, 3):
            with self.subTest(scale=scale):
                with self.assertRaises(ValueError):
                    MODULE.sheet_dimensions(3, scale=scale)


if __name__ == "__main__":
    unittest.main()
