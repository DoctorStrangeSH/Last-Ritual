"""Night trophy icons: reproducible pixel source, size, transparency and outline."""
import importlib.util
import pathlib
import re
import unittest

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("ti", ROOT / "tools" / "generate_trophy_icons.py")
ti = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ti)
PNG = ROOT / "assets" / "trophies" / "trophy_icons_8x24.png"


class TrophyIconTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.generated = ti.atlas()
        with Image.open(PNG) as committed:
            cls.committed = committed.convert("RGBA")

    def test_committed_png_matches_source(self):
        self.assertEqual(self.committed.tobytes(), self.generated.tobytes())

    def test_size_and_order_match_the_game_catalogue(self):
        self.assertEqual(self.generated.size, (24 * 8, 24))
        catalogue = (ROOT / "scripts" / "run_trophies.gd").read_text(encoding="utf-8")
        order = re.search(r"const ORDER := \[(.*?)\]", catalogue, re.S).group(1)
        self.assertEqual(re.findall(r'"([a-z_]+)"', order), ti.ORDER)

    def test_each_icon_is_visible_distinct_and_has_transparent_corners(self):
        frames = [self.generated.crop((i * 24, 0, i * 24 + 24, 24)) for i in range(8)]
        self.assertEqual(len({f.tobytes() for f in frames}), 8)
        for index, frame in enumerate(frames):
            alpha = frame.getchannel("A")
            opaque = sum(1 for a in alpha.getdata() if a)
            self.assertGreater(opaque, 120, ti.ORDER[index])
            for corner in ((0, 0), (23, 0), (0, 23), (23, 23)):
                self.assertEqual(frame.getpixel(corner)[3], 0, f"{ti.ORDER[index]} corner {corner}")

    def test_silhouette_is_outlined_in_ink(self):
        ink = ti.P["ink"]
        for index in range(8):
            frame = self.generated.crop((index * 24, 0, index * 24 + 24, 24))
            px = frame.load()
            for y in range(24):
                for x in range(24):
                    if px[x, y][3] == 0:
                        continue
                    edge = any(not (0 <= x + dx < 24 and 0 <= y + dy < 24) or px[x + dx, y + dy][3] == 0
                               for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                    if edge:
                        self.assertEqual(px[x, y], ink, f"{ti.ORDER[index]} edge pixel {(x, y)} is not ink")


if __name__ == "__main__":
    unittest.main()
