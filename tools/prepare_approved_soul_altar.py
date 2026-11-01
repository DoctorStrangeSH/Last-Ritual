#!/usr/bin/env python3
"""Export ONLY previously approved standalone transparent Soul Altar renders.
Source PNGs are preserved byte-for-byte. Not an SVG importer or concept generator.
Dependency: Pillow. Command:
python tools/prepare_approved_soul_altar.py --source /path/to/originals --output build/approved-soul-altar
"""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image

SOURCES = {
    "level_1": "imagegen.png",
    "level_2": "алтарь_душ_с_фиолетовым_пламенем.png",
    "level_3": "пиксельный_алтарь_душ_с_фиолетовым_пламенем.png",
    "reaper": "готическая_алтарная_башня_жнеца_душ.png",
}
CANVAS = (192, 192)

def validate(image, name):
    if image.mode != "RGBA":
        raise ValueError("%s must be RGBA" % name)
    lo, hi = image.getchannel("A").getextrema()
    if lo > 3 or hi < 252:
        raise ValueError("%s lacks transparent and painted pixels" % name)
    w, h = image.size
    for pos in [(0, 0), (w-1, 0), (0, h-1), (w-1, h-1)]:
        if image.getpixel(pos)[3] > 3:
            raise ValueError("%s has a painted corner: %s" % (name, pos))

def sprite(image):
    mask = image.getchannel("A").point(lambda a: 255 if a > 8 else 0)
    bbox = mask.getbbox()
    if bbox is None:
        raise ValueError("Empty render")
    crop = image.crop(bbox)
    scale = min(178 / crop.width, 178 / crop.height)
    scaled = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.NEAREST)
    out = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    out.alpha_composite(scaled, ((192-scaled.width)//2, 192-scaled.height-5))
    validate(out, "export")
    return out

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    (args.output/"source").mkdir(parents=True, exist_ok=True)
    (args.output/"sprites").mkdir(exist_ok=True)
    manifest = {"status": "standalone-art-qa-only", "runtime_enabled": False,
                "canvas": [192, 192], "complete": False, "entries": {}}
    for key, filename in SOURCES.items():
        original = args.source/filename
        if not original.is_file():
            raise FileNotFoundError(original)
        image = Image.open(original)
        validate(image, key)
        source = args.output/"source"/(key+"_original.png")
        source.write_bytes(original.read_bytes())
        output = args.output/"sprites"/(key+".png")
        sprite(image).save(output, optimize=True)
        manifest["entries"][key] = {"source": str(source.relative_to(args.output)),
                                    "source_sha256": sha(source),
                                    "sprite": str(output.relative_to(args.output)),
                                    "sprite_sha256": sha(output)}
    (args.output/"manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False)+"\n", encoding="utf-8")
    print("Four RGBA candidates exported. Legion, modular layers and 8-way art remain incomplete.")

if __name__ == "__main__":
    main()
