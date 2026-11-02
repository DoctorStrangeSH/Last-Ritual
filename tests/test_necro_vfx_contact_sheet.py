import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "render_necro_vfx_contact_sheet",
    ROOT / "tools" / "render_necro_vfx_contact_sheet.py",
)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class SoulAltarVfxContactSheetTests(unittest.TestCase):
    def test_contact_sheet_dimensions_fit_all_48_frames(self):
        self.assertEqual(MODULE.sheet_dimensions(), (2216, 582))
        self.assertEqual(len(MODULE.BRANCHES) * len(MODULE.KINDS) * 8, 48)

    def test_all_six_candidate_atlases_exist(self):
        for branch, _ in MODULE.BRANCHES:
            for kind, _ in MODULE.KINDS:
                with self.subTest(branch=branch, kind=kind):
                    self.assertTrue((MODULE.ART / f"{branch}_{kind}_8f.png").is_file())


if __name__ == "__main__":
    unittest.main()
