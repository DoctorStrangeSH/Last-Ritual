#!/usr/bin/env python3
"""Validate editable Soul Altar SVG source layers; standard library only.

This is structural safety QA, NOT a substitute for Godot import or visual review.
"""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
LAYERS = ROOT / "assets/spire/towers/necro/source/layers"
NS = "{http://www.w3.org/2000/svg}"
EXPECTED = {
    f"{layer}_level_{level}.svg"
    for layer in ("base", "weapon") for level in (1, 2, 3)
}
ALLOWED = {"svg", "rect", "polygon", "circle", "path"}
BANNED = {"text", "image", "foreignObject", "script", "use", "animate"}
COLOR_ATTRS = ("fill", "stroke")

def check(path: Path) -> None:
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as exc:
        raise ValueError(f"invalid SVG XML: {exc}") from exc
    if root.tag != NS + "svg":
        raise ValueError("missing SVG namespace/root")
    if root.get("viewBox") != "0 0 128 128":
        raise ValueError("unexpected source viewBox")
    if root.get("width") != "128" or root.get("height") != "128":
        raise ValueError("unexpected source dimensions")
    if root.get("shape-rendering") != "crispEdges":
        raise ValueError("missing pixel-art rendering hint")

    painted = 0
    for element in root.iter():
        kind = element.tag.rsplit("}", 1)[-1]
        if kind in BANNED or kind not in ALLOWED:
            raise ValueError(f"unapproved element: {kind}")
        if kind != "svg":
            painted += 1
            if not element.get("fill", "").startswith("#"):
                raise ValueError(f"{kind} must use an explicit hexadecimal fill")
        for key, value in element.attrib.items():
            attr = key.rsplit("}", 1)[-1]
            if attr in ("href", "style") or "url(" in value or "http:" in value or "https:" in value:
                raise ValueError(f"external reference or style: {attr}")
            if attr in COLOR_ATTRS and value.lower() in ("white", "#ffffff", "#fff"):
                raise ValueError("unexpected solid-white element")
    if painted < 12:
        raise ValueError("source art lacks expected detail")

def validate_all() -> None:
    found = {p.name for p in LAYERS.glob("*.svg")}
    if found != EXPECTED:
        raise ValueError(f"source layers mismatch: missing={sorted(EXPECTED-found)}, unexpected={sorted(found-EXPECTED)}")
    for name in sorted(EXPECTED):
        check(LAYERS / name)

if __name__ == "__main__":
    try:
        validate_all()
    except (ValueError, OSError) as exc:
        print(f"FAIL editable art: {exc}", file=sys.stderr)
        raise SystemExit(1)
    print(f"OK editable art: {len(EXPECTED)} isolated SVG layers")
