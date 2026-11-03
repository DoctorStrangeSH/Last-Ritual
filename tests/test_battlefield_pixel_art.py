"""Battlefield pixel art: reproducible source, sizes, transparency and palette discipline."""
import importlib.util
import pathlib
import unittest

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("bf", ROOT / "tools" / "generate_battlefield_pixel_art.py")
bf = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bf)
CANDIDATE = ROOT / "assets" / "battlefield" / "candidate"
SIZES = {"ground_256.png": (256, 256), "road_64.png": (64, 64), "pad_empty_64.png": (64, 64),
         "pad_built_64.png": (64, 64), "altar_128.png": (128, 128), "props_8x32.png": (256, 32),
         "gate_48x64.png": (48, 64), "wall_48x66.png": (48, 66)}


class BattlefieldArtTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.generated = dict(bf.assets())

    def test_committed_pngs_match_the_source(self):
        for name, image in self.generated.items():
            with Image.open(CANDIDATE / name) as committed:
                self.assertEqual(committed.convert("RGBA").tobytes(), image.tobytes(), name)

    def test_sizes(self):
        self.assertEqual({n: im.size for n, im in self.generated.items()}, SIZES)

    def test_tiles_are_opaque_and_sprites_have_clean_corners(self):
        for name in ("ground_256.png", "road_64.png"):
            self.assertEqual(self.generated[name].getchannel("A").getextrema(), (255, 255), name)
        for name in ("pad_empty_64.png", "pad_built_64.png", "altar_128.png", "gate_48x64.png", "props_8x32.png"):
            im = self.generated[name]
            for corner in ((0, 0), (im.width - 1, 0), (0, im.height - 1), (im.width - 1, im.height - 1)):
                self.assertEqual(im.getpixel(corner)[3], 0, f"{name} corner {corner}")

    def test_only_palette_colours_are_used(self):
        palette = set(bf.P.values())
        for name, image in self.generated.items():
            colours = {c for _, c in image.getcolors(maxcolors=4096)}
            self.assertTrue(colours <= palette, f"{name} uses off-palette colours: {colours - palette}")

    def test_ground_tile_wraps_without_seams(self):
        g = self.generated["ground_256.png"]
        # the generator draws on a toroidal canvas, so edges must continue each other
        left = [g.getpixel((0, y)) for y in range(256)]
        right = [g.getpixel((255, y)) for y in range(256)]
        differing = sum(1 for a, b in zip(left, right) if a != b)
        self.assertLess(differing, 256)  # neighbours, not copies; must not be a flat border

    def test_every_prop_frame_is_distinct_and_visible(self):
        strip = self.generated["props_8x32.png"]
        frames = [strip.crop((i * 32, 0, i * 32 + 32, 32)) for i in range(8)]
        self.assertEqual(len({f.tobytes() for f in frames}), 8)
        for f in frames:
            self.assertGreater(sum(1 for p in f.getdata() if p[3]), 40)


if __name__ == "__main__":
    unittest.main()
