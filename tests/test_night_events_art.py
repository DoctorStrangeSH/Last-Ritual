"""Night event illustrations: reproducible pixel source, order, transparency, ink outline."""
import importlib.util
import pathlib
import re
import sys
import unittest

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
spec = importlib.util.spec_from_file_location("ne", ROOT / "tools" / "generate_night_events.py")
ne = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ne)
from generate_battlefield_pixel_art import P  # noqa: E402

PNG = ROOT / "assets" / "night" / "event_icons_4x48.png"


class NightEventArtTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.generated = ne.atlas()

    def test_committed_png_matches_source(self):
        with Image.open(PNG) as committed:
            self.assertEqual(committed.convert("RGBA").tobytes(), self.generated.tobytes())

    def test_order_matches_the_game_catalogue(self):
        catalogue = (ROOT / "scripts" / "night_events.gd").read_text(encoding="utf-8")
        order = re.search(r"const ORDER := \[(.*?)\]", catalogue, re.S).group(1)
        self.assertEqual(re.findall(r'"([a-z_]+)"', order), ne.ORDER)
        self.assertEqual(self.generated.size, (48 * 4, 48))

    def test_frames_are_distinct_filled_and_outlined(self):
        frames = [self.generated.crop((i * 48, 0, i * 48 + 48, 48)) for i in range(4)]
        self.assertEqual(len({f.tobytes() for f in frames}), 4)
        for index, frame in enumerate(frames):
            px = frame.load()
            self.assertGreater(sum(1 for a in frame.getchannel("A").getdata() if a), 500, ne.ORDER[index])
            for corner in ((0, 0), (47, 0), (0, 47), (47, 47)):
                self.assertEqual(px[corner][3], 0)
            for y in range(48):
                for x in range(48):
                    if px[x, y][3] and any(not (0 <= x + dx < 48 and 0 <= y + dy < 48) or px[x + dx, y + dy][3] == 0
                                           for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                        self.assertEqual(px[x, y], P["ink"], f"{ne.ORDER[index]} edge {(x, y)}")


if __name__ == "__main__":
    unittest.main()
