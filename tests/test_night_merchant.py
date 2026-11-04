"""Dark Merchant sprite: reproducible pixel source, size, transparency, ink outline."""
import importlib.util
import pathlib
import sys
import unittest

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
spec = importlib.util.spec_from_file_location("nm", ROOT / "tools" / "generate_night_merchant.py")
nm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(nm)
PNG = ROOT / "assets" / "night" / "dark_merchant_48.png"


class DarkMerchantTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.generated = nm.to_image(nm.merchant())
        with Image.open(PNG) as committed:
            cls.committed = committed.convert("RGBA")

    def test_committed_png_matches_source(self):
        self.assertEqual(self.committed.tobytes(), self.generated.tobytes())

    def test_size_corners_and_fill(self):
        self.assertEqual(self.generated.size, (48, 48))
        for corner in ((0, 0), (47, 0), (0, 47), (47, 47)):
            self.assertEqual(self.generated.getpixel(corner)[3], 0)
        opaque = sum(1 for a in self.generated.getchannel("A").getdata() if a)
        self.assertGreater(opaque, 600)

    def test_edges_are_ink(self):
        from generate_battlefield_pixel_art import P
        px = self.generated.load()
        for y in range(48):
            for x in range(48):
                if px[x, y][3] == 0:
                    continue
                if any(not (0 <= x + dx < 48 and 0 <= y + dy < 48) or px[x + dx, y + dy][3] == 0
                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    self.assertEqual(px[x, y], P["ink"], f"edge pixel {(x, y)}")


if __name__ == "__main__":
    unittest.main()
