#!/usr/bin/env python3
"""Small standard-library regression tests for immutable source art import."""
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

MODULE_PATH = Path(__file__).resolve().parents[1] / "tools/import_source_art.py"
spec = importlib.util.spec_from_file_location("import_source_art", MODULE_PATH)
source = importlib.util.module_from_spec(spec)
spec.loader.exec_module(source)


class ImporterTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.name = "docs/art/source/concepts/example.png"
        self.picture = b"\x89PNG\r\n\x1a\n" + b"test image bytes"
        self.manifest = self.root / "manifest.json"
        self.zip = self.root / "source.zip"
        self.write_manifest(self.picture)
        with zipfile.ZipFile(self.zip, "w") as z:
            z.writestr(self.name, self.picture)
        self.prev = source.MANIFEST
        source.MANIFEST = self.manifest
        self.addCleanup(setattr, source, "MANIFEST", self.prev)

    def write_manifest(self, data):
        self.manifest.write_text(json.dumps({"items": [
            {"path": self.name, "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)}
        ]}), encoding="utf-8")

    def test_restores_original_bytes(self):
        result = source.restore(self.zip, self.root)
        self.assertEqual(len(result), 1)
        self.assertEqual((self.root / self.name).read_bytes(), self.picture)

    def test_dry_run_does_not_create_file(self):
        source.restore(self.zip, self.root, dry_run=True)
        self.assertFalse((self.root / self.name).exists())

    def test_rejects_bad_checksum(self):
        self.write_manifest(b"different")
        with self.assertRaisesRegex(ValueError, "SHA-256"):
            source.restore(self.zip, self.root)
        self.assertFalse((self.root / self.name).exists())

    def test_rejects_unsafe_path(self):
        self.name = "../escape.png"
        self.write_manifest(self.picture)
        with self.assertRaisesRegex(ValueError, "Unsafe"):
            source.restore(self.zip, self.root)

    def test_does_not_overwrite_changed_file(self):
        target = self.root / self.name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(b"hand-edited")
        with self.assertRaisesRegex(ValueError, "Refusing"):
            source.restore(self.zip, self.root)
        self.assertEqual(target.read_bytes(), b"hand-edited")


if __name__ == "__main__":
    unittest.main()
