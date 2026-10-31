#!/usr/bin/env python3
"""Verify tracked PNG files without third-party dependencies.

Check: PNG signature, complete chunk stream, CRCs, IDAT zlib decompression,
image row filter codes and exact uncompressed payload length for non-interlaced
8-bit RGBA/indexed/grayscale images used by this repository.
"""
import pathlib
import struct
import sys
import zlib

SIGNATURE = b"\x89PNG\r\n\x1a\n"

def validate(path: pathlib.Path) -> None:
    data = path.read_bytes()
    if not data.startswith(SIGNATURE):
        raise ValueError("invalid PNG signature")
    pos = 8
    chunks = []
    idat = bytearray()
    width = height = depth = kind = interlace = None
    ended = False
    while pos + 12 <= len(data):
        n = struct.unpack_from(">I", data, pos)[0]
        end = pos + 12 + n
        if end > len(data):
            raise ValueError("truncated chunk")
        tag = data[pos + 4:pos + 8]
        payload = data[pos + 8:pos + 8 + n]
        crc = struct.unpack_from(">I", data, end - 4)[0]
        if zlib.crc32(tag + payload) & 0xffffffff != crc:
            raise ValueError(f"bad CRC in {tag!r}")
        chunks.append(tag)
        if tag == b"IHDR":
            if n != 13:
                raise ValueError("invalid IHDR")
            width, height, depth, kind, compression, filtering, interlace = struct.unpack(">IIBBBBB", payload)
            if width == 0 or height == 0 or compression or filtering or interlace:
                raise ValueError("unsupported IHDR")
        elif tag == b"IDAT":
            idat.extend(payload)
        elif tag == b"IEND":
            ended = True
            pos = end
            break
        pos = end
    if not ended or pos != len(data) or chunks[0] != b"IHDR" or not idat:
        raise ValueError("missing IEND, IHDR or IDAT, or trailing garbage")
    if depth != 8 or kind not in (0, 2, 3, 4, 6):
        raise ValueError("unsupported depth/color type")
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[kind]
    try:
        decomp = zlib.decompressobj()
        raw = decomp.decompress(bytes(idat)) + decomp.flush()
    except zlib.error as e:
        raise ValueError(f"corrupted IDAT: {e}") from e
    if not decomp.eof or decomp.unused_data:
        raise ValueError("incomplete or trailing IDAT stream")
    pitch = width * channels
    if len(raw) != height * (pitch + 1):
        raise ValueError("wrong decompressed scanline length")
    if any(raw[i * (pitch + 1)] > 4 for i in range(height)):
        raise ValueError("invalid PNG scanline filter")

def main() -> int:
    paths = sorted(pathlib.Path("assets").rglob("*.png"))
    if not paths:
        print("No PNG images found", file=sys.stderr)
        return 1
    errors = 0
    for path in paths:
        try:
            validate(path)
            print(f"OK PNG: {path}")
        except (ValueError, OSError) as exc:
            errors += 1
            print(f"FAIL PNG: {path}: {exc}", file=sys.stderr)
    return 1 if errors else 0

if __name__ == "__main__":
    sys.exit(main())
