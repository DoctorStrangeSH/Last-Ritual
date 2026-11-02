import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "export_soul_altar_preview", ROOT / "tools" / "export_soul_altar_preview.py"
)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class SoulAltarPreviewExportTests(unittest.TestCase):
    def test_preview_config_changes_only_name_and_main_scene(self):
        original = (ROOT / "project.godot").read_text(encoding="utf-8")
        updated = MODULE.make_preview_config(original)
        self.assertIn(MODULE.PREVIEW_SCENE, updated)
        self.assertIn(MODULE.PREVIEW_NAME, updated)
        self.assertNotIn(MODULE.PRODUCTION_SCENE, updated)
        self.assertNotIn(MODULE.PRODUCTION_NAME, updated)
        self.assertIn(MODULE.PRODUCTION_SCENE, original)
        self.assertIn(MODULE.PRODUCTION_NAME, original)

    def test_duplicate_or_unexpected_project_settings_are_rejected(self):
        original = (ROOT / "project.godot").read_text(encoding="utf-8")
        with self.assertRaises(ValueError):
            MODULE.make_preview_config(original + "\\n" + MODULE.PRODUCTION_SCENE)

    def test_preview_scene_is_the_isolated_review_scene(self):
        self.assertEqual(
            MODULE.PREVIEW_SCENE,
            'run/main_scene="res://scenes/dev/soul_altar_modular_motion_preview.tscn"',
        )


if __name__ == "__main__":
    unittest.main()
