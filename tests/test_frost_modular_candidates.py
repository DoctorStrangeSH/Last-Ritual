from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import generate_frost_modular_candidates as generator
import render_frost_modular_preview as renderer


class FrostModularCandidateTests(unittest.TestCase):
    def test_manifest_is_review_only_and_maps_existing_specializations(self):
        manifest = json.loads((generator.ART / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["id"], "frost")
        self.assertEqual(manifest["status"], "review_candidate")
        self.assertIs(manifest["runtime_enabled"], False)
        self.assertEqual(manifest["specialization_branches"], {
            "siege": "frost_lance",
            "swarm": "blizzard",
        })
        self.assertEqual(manifest["specialization_labels"]["siege"], "МОРОЗ: СИЛЬНЕЕ")
        self.assertEqual(manifest["specialization_labels"]["swarm"], "МЕТЕЛЬ: БЫСТРЕЕ")

    def test_three_base_layers_are_transparent_distinct_and_progressive(self):
        counts = []
        for level in (1, 2, 3):
            path = generator.CANDIDATE / "base" / f"level_{level}.png"
            with Image.open(path) as source:
                image = source.convert("RGBA")
            self.assertEqual(image.size, (128, 128))
            self.assertTrue(image.getchannel("A").getbbox())
            self.assertEqual([image.getpixel(p)[3] for p in ((0, 0), (127, 0), (0, 127), (127, 127))], [0] * 4)
            counts.append(sum(1 for alpha in image.getchannel("A").getdata() if alpha > 0))
        self.assertEqual(len(set(counts)), 3)
        self.assertLess(counts[0], counts[1])
        self.assertLess(counts[1], counts[2])

    def test_each_weapon_branch_contains_eight_distinct_transparent_poses(self):
        for branch in ("base", "frost_lance", "blizzard"):
            path = generator.CANDIDATE / "weapon" / branch / "weapon_8way.png"
            with Image.open(path) as source:
                strip = source.convert("RGBA")
            self.assertEqual(strip.size, (1024, 128))
            fingerprints = set()
            for index in range(8):
                frame = strip.crop((index * 128, 0, (index + 1) * 128, 128))
                self.assertEqual([frame.getpixel(p)[3] for p in ((0, 0), (127, 0), (0, 127), (127, 127))], [0] * 4)
                self.assertGreater(sum(1 for a in frame.getchannel("A").getdata() if a > 0), 8)
                fingerprints.add(frame.tobytes())
            self.assertEqual(len(fingerprints), 8, f"{branch} repeats a direction")

    def test_all_six_vfx_strips_have_eight_distinct_nonempty_frames(self):
        for branch in ("base", "frost_lance", "blizzard"):
            for kind, cell in (("projectile", (32, 32)), ("impact", (64, 64))):
                path = generator.CANDIDATE / "vfx" / f"{branch}_{kind}_8f.png"
                with Image.open(path) as source:
                    strip = source.convert("RGBA")
                self.assertEqual(strip.size, (cell[0] * 8, cell[1]))
                fingerprints = set()
                for index in range(8):
                    frame = strip.crop((index * cell[0], 0, (index + 1) * cell[0], cell[1]))
                    self.assertGreater(sum(1 for a in frame.getchannel("A").getdata() if a > 0), 8)
                    self.assertEqual([frame.getpixel(p)[3] for p in ((0, 0), (cell[0]-1, 0), (0, cell[1]-1), (cell[0]-1, cell[1]-1))], [0] * 4)
                    fingerprints.add(frame.tobytes())
                self.assertEqual(len(fingerprints), 8, f"{branch} {kind} repeats an animation frame")

    def test_procedural_source_reproduces_every_committed_asset(self):
        generator.verify_assets()

    def test_review_sheets_render_at_native_and_enlarged_scales(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            one_x = root / "frost_72_1x.png"
            two_x = root / "frost_72_2x.png"
            compact = root / "frost_9_1x.png"
            renderer.render_full(one_x, all_levels=True, scale=1)
            renderer.render_full(two_x, all_levels=True, scale=2)
            renderer.render_compact(compact)
            with Image.open(one_x) as image:
                self.assertEqual(image.size, (1132, 1908))
            with Image.open(two_x) as image:
                self.assertEqual(image.size, (2156, 3312))
            with Image.open(compact) as image:
                self.assertEqual(image.size, (472, 662))


if __name__ == "__main__":
    unittest.main()
