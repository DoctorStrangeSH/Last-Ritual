#!/usr/bin/env python3
"""Create labeled contact sheets and frame metadata for the Foozle BuilderPack.

Requires Pillow (python -m pip install Pillow).
Usage: python tools/analyze_foozle_builderpack.py /path/to/BuilderPack.zip
Outputs go to build/foozle_builderpack_preview/ and are not game assets.
The grid dimensions are exact divisors of the source PNG sizes; grid position
alone does not assert which cells form a particular animation.
"""
from pathlib import Path
import json
import sys
import zipfile
from PIL import Image, ImageDraw

SOURCES = {
    "construction": ("Building Animations/PNGs/Tower Construction.png", 6, 8, 192, 192),
    "collapse": ("Building Animations/PNGs/Tower - Collapse.png", 26, 1, 128, 192),
    "wisp": ("Wisp/Spritesheet/Wisp - Animations.png", 9, 6, 64, 64),
}


def contact_sheet(image: Image.Image, columns: int, rows: int, fw: int, fh: int, title: str, output: Path) -> None:
    scale = 2 if fw <= 192 else 1
    label_h = 20
    cell_w, cell_h = fw * scale, fh * scale
    sheet = Image.new("RGBA", (columns * cell_w, rows * (cell_h + label_h)), (28, 31, 38, 255))
    draw = ImageDraw.Draw(sheet)
    for row in range(rows):
        for col in range(columns):
            frame = image.crop((col * fw, row * fh, (col + 1) * fw, (row + 1) * fh))
            if scale != 1:
                frame = frame.resize((cell_w, cell_h), Image.Resampling.NEAREST)
            x, y = col * cell_w, row * (cell_h + label_h)
            sheet.alpha_composite(frame, (x, y + label_h))
            draw.text((x + 3, y + 3), f"r{row} c{col} / #{row * columns + col:02d}", fill=(255, 235, 120, 255))
            draw.rectangle((x, y + label_h, x + cell_w - 1, y + label_h + cell_h - 1), outline=(90, 100, 115, 255))
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    archive = Path(sys.argv[1])
    output_dir = Path("build/foozle_builderpack_preview")
    metadata = {"source_archive": archive.name, "license": "CC0 1.0 (verify bundled Readme.txt)", "sheets": {}}
    with zipfile.ZipFile(archive) as zf:
        bad = zf.testzip()
        if bad:
            raise SystemExit(f"ZIP CRC error in {bad}")
        names = zf.namelist()
        for key, (suffix, cols, rows, fw, fh) in SOURCES.items():
            matches = [name for name in names if name.endswith(suffix)]
            if len(matches) != 1:
                raise SystemExit(f"Expected one {suffix!r}, found {len(matches)}")
            import io
            with Image.open(io.BytesIO(zf.read(matches[0]))) as opened:
                image = opened.convert("RGBA")
            expected = (cols * fw, rows * fh)
            if image.size != expected:
                raise SystemExit(f"{key}: expected {expected}, got {image.size}")
            filename = f"{key}_contact.png"
            contact_sheet(image, cols, rows, fw, fh, key, output_dir / filename)
            metadata["sheets"][key] = {
                "source": matches[0], "size": list(image.size), "mode": "RGBA",
                "grid": {"columns": cols, "rows": rows, "frame_width": fw, "frame_height": fh},
                "frame_count": cols * rows, "contact_sheet": filename,
                "animation_order_confirmed": False
            }
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "frames.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    print(f"Created labeled previews and frames.json in {output_dir}")
    print("Review each sheet visually before assigning frame sequences or FPS.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
