#!/usr/bin/env python3
"""Install the owner's existing, approved Soul Altar RGBA ZIP into a review-only folder.

Uses only stdlib. No art generation, background removal, pixel resampling or
Aseprite fabrication. Every original and sprite is copied byte-for-byte after
SHA256 and PNG-header verification. Assets remain runtime-disabled.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import struct
import zipfile

NAMES = ("level_1", "level_2", "level_3", "reaper")
REQUIRED_SIZE = (192, 192)
DEST = "assets/spire/towers/necro/approved_renders"
MAX_ARCHIVE_BYTES = 30_000_000
MAX_ITEM_BYTES = 6_000_000


def png_dimensions(data: bytes) -> tuple[int, int]:
    if len(data) < 33 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ValueError("Not a PNG file")
    width, height = struct.unpack(">II", data[16:24])
    if width < 1 or height < 1 or width > 4096 or height > 4096:
        raise ValueError("Unreasonable PNG dimensions")
    # PNG colour type 6 = RGBA. We only accept existing alpha, not an
    # RGB image with a purple backdrop.
    if data[25] != 6:
        raise ValueError("PNG must be RGBA (colour type 6)")
    return width, height


def extract_verified(archive: Path, output: Path) -> dict:
    if not archive.is_file():
        raise FileNotFoundError(archive)
    if archive.stat().st_size > MAX_ARCHIVE_BYTES:
        raise ValueError("Archive too large")
    payload: dict[str, bytes] = {}
    with zipfile.ZipFile(archive) as package:
        listing = package.infolist()
        if len(listing) > 40 or sum(x.file_size for x in listing) > MAX_ARCHIVE_BYTES:
            raise ValueError("Archive has too many/too large entries")
        if len(set(x.filename for x in listing)) != len(listing):
            raise ValueError("Duplicate ZIP names")
        for entry in listing:
            if entry.filename.startswith("/") or ".." in Path(entry.filename).parts or "\\" in entry.filename:
                raise ValueError("Unsafe ZIP name")
        manifest = json.loads(package.read("manifest.json"))
        if manifest.get("runtime_enabled") is not False:
            raise ValueError("The review archive must not enable runtime")
        entries = manifest.get("entries", {})
        if set(entries) != set(NAMES):
            raise ValueError("Unexpected or incomplete source manifest")
        for name in NAMES:
            record = entries[name]
            for key, sha_key, expected in (
                ("source", "source_sha256", None),
                ("sprite", "sprite_sha256", REQUIRED_SIZE),
            ):
                path = record.get(key)
                if path != f"{key}/{name}{'_original' if key == 'source' else ''}.png":
                    raise ValueError(f"Unexpected {key} path for {name}")
                meta = package.getinfo(path)
                if meta.file_size > MAX_ITEM_BYTES:
                    raise ValueError("Oversize PNG")
                data = package.read(path)
                if hashlib.sha256(data).hexdigest() != record.get(sha_key):
                    raise ValueError(f"SHA256 mismatch in {path}")
                size = png_dimensions(data)
                if expected is not None and size != expected:
                    raise ValueError(f"Unexpected sprite dimensions: {path}: {size}")
                payload[path] = data
        manifest["production_ready"] = False
        manifest["runtime_enabled"] = False
        manifest["status"] = "standalone-art-qa-only"
    # No files are written until the whole archive has been validated.
    for path, data in payload.items():
        destination = output / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
    (output / "manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path, help="Existing LastRitual_SoulAltar_Approved_RGBA_Source_and_Sprites.zip")
    parser.add_argument("--output", type=Path, default=Path(DEST))
    args = parser.parse_args()
    manifest = extract_verified(args.archive, args.output)
    print(f"Verified {len(manifest['entries'])} approved RGBA renders at {args.output}")
    print("Runtime not changed. Commit source/, sprites/ and manifest.json together.")


if __name__ == "__main__":
    main()
