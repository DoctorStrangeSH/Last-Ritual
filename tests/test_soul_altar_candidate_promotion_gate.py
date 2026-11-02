"""Guard Soul Altar candidate-only status until explicit art approval.

Technical CI must never silently promote review art into the live game.
These checks intentionally require a deliberate follow-up PR to change.
"""
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets/spire/towers/necro"
CANDIDATE = ART / "candidate"
BRANCHES = ("base", "reaper", "legion")


class CandidatePromotionGateTests(unittest.TestCase):
    def test_candidate_manifest_requires_manual_approval(self):
        manifest = json.loads((CANDIDATE / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["status"], "candidate_for_review")
        self.assertIs(manifest["runtime_enabled"], False)
        self.assertEqual(manifest["id"], "necro")
        self.assertEqual(tuple(manifest["weapon"].keys()), BRANCHES)
        for branch in BRANCHES:
            self.assertTrue(manifest["weapon"][branch]["path"].startswith("candidate/"))

    def test_production_manifest_is_not_enabled_without_six_authored_files(self):
        manifest = json.loads((ART / "manifest.json").read_text(encoding="utf-8"))
        self.assertIs(manifest["runtime_enabled"], False)
        required = [ART / f"base/level_{level}.png" for level in (1, 2, 3)]
        required.extend(ART / f"weapon/{branch}/weapon_8way.png" for branch in BRANCHES)
        self.assertFalse(any(path.is_file() for path in required),
                         "Candidate assets must not be copied to production without art signoff")

    def test_review_sheet_is_not_a_runtime_texture(self):
        renderer = ROOT / "tools/render_soul_altar_compact_review.py"
        self.assertTrue(renderer.is_file())
        source = renderer.read_text(encoding="utf-8")
        self.assertIn("build/soul_altar_9_compositions_1x.png", source)
        self.assertNotIn("ART / \"manifest.json\"", source)


if __name__ == "__main__":
    unittest.main()
