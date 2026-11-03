"""Verify the explicit owner-approved Soul Altar production promotion."""
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets/spire/towers/necro"
CANDIDATE = ART / "candidate"
BRANCHES = ("base", "reaper", "legion")


class CandidatePromotionGateTests(unittest.TestCase):
    def test_candidate_manifest_is_preserved_as_disabled_source_archive(self):
        manifest = json.loads((CANDIDATE / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["status"], "approved_source_archive")
        self.assertIs(manifest["runtime_enabled"], False)
        self.assertEqual(manifest["id"], "necro")
        for branch in BRANCHES:
            self.assertTrue(manifest["weapon"][branch]["path"].startswith("candidate/"))

    def test_production_manifest_is_enabled_only_with_six_approved_pngs(self):
        manifest = json.loads((ART / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["status"], "owner_approved_production")
        self.assertIs(manifest["runtime_enabled"], True)
        required = [ART / f"base/level_{level}.png" for level in (1, 2, 3)]
        required.extend(ART / f"weapon/{branch}/weapon_8way.png" for branch in BRANCHES)
        self.assertTrue(all(path.is_file() for path in required))
        self.assertEqual(manifest["base"]["levels"]["1"], "base/level_1.png")
        for branch in BRANCHES:
            self.assertFalse(manifest["weapon"][branch]["path"].startswith("candidate/"))

    def test_production_reuses_existing_vfx_and_does_not_promote_candidate_vfx(self):
        manifest = json.loads((ART / "manifest.json").read_text(encoding="utf-8"))
        candidate = json.loads((CANDIDATE / "manifest.json").read_text(encoding="utf-8"))
        for branch in BRANCHES:
            for section in ("projectiles", "impacts"):
                production_path = ART / manifest[section][branch]["path"]
                candidate_path = ART / candidate[section][branch]["path"]
                self.assertTrue(production_path.is_file())
                self.assertTrue(candidate_path.is_file())
                self.assertFalse(manifest[section][branch]["path"].startswith("candidate/"))

    def test_review_sheet_is_not_a_runtime_texture(self):
        renderer = ROOT / "tools/render_soul_altar_compact_review.py"
        self.assertTrue(renderer.is_file())
        source = renderer.read_text(encoding="utf-8")
        self.assertIn("build/soul_altar_9_compositions_1x.png", source)
        self.assertNotIn('ART / "manifest.json"', source)


if __name__ == "__main__":
    unittest.main()
