from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import generate_enemy_roster_pixel_art as generator
import render_enemy_roster_preview as renderer


class EnemyRosterPixelArtTests(unittest.TestCase):
    def test_manifest_is_review_only_and_maps_current_gameplay_roles(self):
        manifest = json.loads((generator.ART / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["id"], "enemy_roster")
        self.assertEqual(manifest["status"], "review_candidate")
        self.assertIs(manifest["runtime_enabled"], False)
        self.assertEqual(manifest["role_mapping"]["td"], {
            "runner": "runner",
            "brute": "brute",
            "captain": "captain",
            "healer": "healer",
            "boss": "boss",
        })
        self.assertEqual(manifest["role_mapping"]["night"], {
            "regular": "runner",
            "flanker": "runner",
            "ranged": "ranged",
            "champion": "brute",
            "boss": "boss",
        })

    def test_each_role_has_eight_distinct_directions_and_four_walk_frames(self):
        for role in generator.ROLES:
            size = 96 if role == "boss" else 48
            path = generator.ART / "candidate" / role / "walk_8way_4f.png"
            with Image.open(path) as source:
                atlas = source.convert("RGBA")
            self.assertEqual(atlas.size, (size * 4, size * 8))
            for direction in range(8):
                directional_frames = []
                for frame in range(4):
                    cell = atlas.crop((frame * size, direction * size,
                                       (frame + 1) * size, (direction + 1) * size))
                    self.assertGreater(sum(1 for alpha in cell.getchannel("A").getdata() if alpha > 0), 20)
                    self.assertEqual(
                        [cell.getpixel(p)[3] for p in (
                            (0, 0), (size - 1, 0), (0, size - 1), (size - 1, size - 1)
                        )],
                        [0] * 4,
                        f"{role} direction {direction} frame {frame} touches atlas-cell corner",
                    )
                    directional_frames.append(cell.tobytes())
                self.assertEqual(len(set(directional_frames)), 4, f"{role} direction {direction} repeats walk frames")
            first_frames = {
                atlas.crop((0, direction * size, size, (direction + 1) * size)).tobytes()
                for direction in range(8)
            }
            self.assertEqual(len(first_frames), 8, f"{role} repeats a facing direction")

    def test_roles_have_distinct_silhouettes_and_boss_has_native_resolution(self):
        fingerprints = set()
        for role in generator.ROLES:
            size = 96 if role == "boss" else 48
            with Image.open(generator.ART / "candidate" / role / "walk_8way_4f.png") as source:
                atlas = source.convert("RGBA")
            first = atlas.crop((0, 0, size, size))
            fingerprints.add(first.tobytes())
        self.assertEqual(len(fingerprints), len(generator.ROLES))
        self.assertEqual(generator.manifest_data()["enemies"]["boss"]["frame_size"], [96, 96])
        self.assertEqual(generator.manifest_data()["enemies"]["runner"]["frame_size"], [48, 48])

    def test_procedural_source_reproduces_every_committed_candidate_asset(self):
        generator.verify_assets()

    def test_review_sheets_render_with_expected_dimensions(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            overview = root / "enemy_roster_8way_2x.png"
            cycles = root / "enemy_walk_cycles_2x.png"
            renderer.render_overview(overview)
            renderer.render_walk_cycles(cycles)
            with Image.open(overview) as image:
                self.assertEqual(image.size, (892, 884))
            with Image.open(cycles) as image:
                self.assertEqual(image.size, (460, 884))


if __name__ == "__main__":
    unittest.main()
