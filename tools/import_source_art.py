#!/usr/bin/env python3
"""Restore unchanged original Last Ritual concept PNGs from archived ZIP.

Usage: python tools/import_source_art.py /path/to/LastRitual_Art_Source_2026-10-31.zip
Requires Python 3.10+ only. Never resizes, converts or regenerates an image.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "docs/art/source/manifests/source_art_manifest.json"


def restore(archive: Path, output_root: Path = ROOT, dry_run: bool = False) -> list[str]:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    entries = manifest["items"]
    expected_paths = set()
    for item in entries:
        path = item["path"]
        if (not path.startswith("docs/art/source/concepts/")
                or not path.endswith(".png")
                or ".." in Path(path).parts
                or Path(path).is_absolute()
                or path in expected_paths):
            raise ValueError(f"Unsafe/duplicate manifest path: {path}")
        expected_paths.add(path)

    verified: list[tuple[Path, bytes]] = []
    with zipfile.ZipFile(archive) as zf:
        corrupt = zf.testzip()
        if corrupt is not None:
            raise ValueError(f"Corrupt ZIP entry: {corrupt}")
        for item in entries:
            name = item["path"]
            if zf.namelist().count(name) != 1:
                raise ValueError(f"Missing/duplicate ZIP item: {name}")
            data = zf.read(name)
            digest = hashlib.sha256(data).hexdigest()
            if digest != item["sha256"] or len(data) != item["bytes"]:
                raise ValueError(f"Source image differs from approved SHA-256/length: {name}")
            if not data.startswith(b"\x89PNG\r\n\x1a\n"):
                raise ValueError(f"Invalid PNG signature: {name}")
            target = output_root / name
            if target.exists() and target.read_bytes() != data:
                raise ValueError(f"Refusing to overwrite changed existing image: {target}")
            verified.append((target, data))

    if not dry_run:
        for target, data in verified:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
    for target, data in verified:
        print(f"{'VERIFIED' if dry_run else 'RESTORED'} {target} ({len(data)} bytes)")
    return [str(target) for target, _ in verified]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("zip", type=Path)
    parser.add_argument("--verify-only", action="store_true", help="Check SHA-256 without writing")
    args = parser.parse_args()
    try:
        restore(args.zip, dry_run=args.verify_only)
    except (ValueError, OSError, zipfile.BadZipFile, KeyError) as exc:
        print(f"Source import FAILED: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
