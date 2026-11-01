import hashlib
import json
from pathlib import Path
import struct
import tempfile
import unittest
import zipfile
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from install_approved_soul_altar_zip import extract_verified, png_dimensions, NAMES


def stub_rgba_png(width=192, height=192):
    # Header-only fixture for the archive integrity test, not a shippable PNG.
    return b"\x89PNG\r\n\x1a\n" + struct.pack(">I", 13) + b"IHDR" + struct.pack(">II", width, height) + bytes([8, 6, 0, 0, 0]) + b"\0" * 4


class ApprovedArchiveTests(unittest.TestCase):
    def archive(self, path, tamper=False, missing=False):
        image = stub_rgba_png()
        entries = {}
        with zipfile.ZipFile(path, "w") as z:
            for name in NAMES:
                if missing and name == "reaper":
                    continue
                src = f"source/{name}_original.png"
                spr = f"sprite/{name}.png"
                # The real source archive uses 'sprites/', not 'sprite/'.
                spr = f"sprites/{name}.png"
                z.writestr(src, image)
                z.writestr(spr, image + (b"modified" if tamper and name == "reaper" else b""))
                entries[name] = dict(source=src, sprite=spr, source_sha256=hashlib.sha256(image).hexdigest(), sprite_sha256=hashlib.sha256(image).hexdigest())
            z.writestr("manifest.json", json.dumps(dict(runtime_enabled=False, entries=entries)))

    def test_header(self):
        self.assertEqual(png_dimensions(stub_rgba_png()), (192, 192))
        with self.assertRaises(ValueError):
            png_dimensions(stub_rgba_png()[:25] + b"\x02" + stub_rgba_png()[26:])

    def test_valid_manifest_and_source_integrity(self):
        with tempfile.TemporaryDirectory() as d:
            archive, out = Path(d)/"input.zip", Path(d)/"installed"
            self.archive(archive)
            manifest = extract_verified(archive, out)
            self.assertFalse(manifest["runtime_enabled"])
            self.assertEqual(len(list((out/"source").glob("*.png"))), 4)
            self.assertEqual(len(list((out/"sprites").glob("*.png"))), 4)

    def test_rejects_tampered_and_partial_archives(self):
        with tempfile.TemporaryDirectory() as d:
            for kw in (dict(tamper=True), dict(missing=True)):
                archive, out = Path(d)/"input.zip", Path(d)/"installed"
                self.archive(archive, **kw)
                with self.assertRaises(ValueError):
                    extract_verified(archive, out)


if __name__ == "__main__":
    unittest.main()
