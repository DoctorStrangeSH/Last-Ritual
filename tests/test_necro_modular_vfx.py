import importlib.util
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "generate_necro_modular_candidates",
    ROOT / "tools" / "generate_necro_modular_candidates.py",
)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class SoulAltarAnimatedVfxTests(unittest.TestCase):
    def test_six_vfx_atlases_are_reproducible_and_have_eight_visible_frames(self):
        generated = list(MODULE.vfx_assets())
        self.assertEqual(len(generated), 6)
        for path, atlas in generated:
            with self.subTest(path=str(path)):
                self.assertEqual(atlas.mode, "RGBA")
                self.assertEqual(atlas.width % 8, 0)
                frame_width = atlas.width // 8
                self.assertEqual(atlas.height, frame_width)
                frames = [
                    atlas.crop((index * frame_width, 0, (index + 1) * frame_width, frame_width))
                    for index in range(8)
                ]
                self.assertTrue(all(frame.getchannel("A").getbbox() for frame in frames))
                self.assertEqual(len({frame.tobytes() for frame in frames}), 8)

    def test_manifest_points_only_to_candidate_attack_vfx(self):
        manifest_path = ROOT / "assets" / "spire" / "towers" / "necro" / "candidate" / "manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        self.assertFalse(manifest["runtime_enabled"])
        for branch in ("base", "reaper", "legion"):
            for section in ("projectiles", "impacts"):
                entry = manifest[section][branch]
                self.assertTrue(entry["path"].startswith("candidate/vfx/"))
                self.assertEqual(entry["frame_count"], 8)
                self.assertEqual(entry["fps"], 24)
                self.assertTrue((ROOT / "assets" / "spire" / "towers" / "necro" / entry["path"]).is_file())

    def test_branch_signatures_are_visually_distinct(self):
        by_name = {path.name: image for path, image in MODULE.vfx_assets()}
        for kind in ("projectile", "impact"):
            signatures = {
                branch: by_name[f"{branch}_{kind}_8f.png"].crop((0, 0, by_name[f"{branch}_{kind}_8f.png"].width // 8, by_name[f"{branch}_{kind}_8f.png"].height)).tobytes()
                for branch in ("base", "reaper", "legion")
            }
            self.assertEqual(len(set(signatures.values())), 3)


if __name__ == "__main__":
    unittest.main()
