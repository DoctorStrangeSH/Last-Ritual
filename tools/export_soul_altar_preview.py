#!/usr/bin/env python3
"""Export a standalone Windows executable for the isolated Soul Altar art review scene.

The production project.godot is restored byte-for-byte even if Godot export fails.
This tool must only be used in a disposable CI workspace.
"""
from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRODUCTION_SCENE = 'run/main_scene="res://scenes/run_loop.tscn"'
PREVIEW_SCENE = 'run/main_scene="res://scenes/dev/soul_altar_modular_motion_preview.tscn"'
PRODUCTION_NAME = 'config/name="Last Ritual 2.0 — Top Down"'
PREVIEW_NAME = 'config/name="Last Ritual — Soul Altar Art Preview"'


def make_preview_config(original: str) -> str:
    if original.count(PRODUCTION_SCENE) != 1:
        raise ValueError("Expected exactly one production main-scene setting")
    if original.count(PRODUCTION_NAME) != 1:
        raise ValueError("Expected exactly one production project-name setting")
    updated = original.replace(PRODUCTION_SCENE, PREVIEW_SCENE, 1)
    updated = updated.replace(PRODUCTION_NAME, PREVIEW_NAME, 1)
    return updated


def export_preview(godot: Path, output: Path, dry_run: bool = False) -> None:
    project_file = ROOT / "project.godot"
    original = project_file.read_bytes()
    original_text = original.decode("utf-8")
    preview_text = make_preview_config(original_text)
    if dry_run:
        if preview_text == original_text:
            raise RuntimeError("Preview project config did not change")
        if PRODUCTION_SCENE not in original_text or PREVIEW_SCENE not in preview_text:
            raise RuntimeError("Main scene override validation failed")
        print("Preview export configuration validated; no project files changed.")
        return

    output.parent.mkdir(parents=True, exist_ok=True)
    try:
        project_file.write_text(preview_text, encoding="utf-8", newline="\n")
        command = [
            str(godot),
            "--headless",
            "--path",
            str(ROOT),
            "--export-release",
            "Windows Desktop",
            str(output),
        ]
        subprocess.run(command, cwd=ROOT, check=True, timeout=240)
    finally:
        project_file.write_bytes(original)

    if not output.is_file() or output.stat().st_size <= 0:
        raise RuntimeError("Godot did not produce the standalone preview executable")
    print(f"Created isolated art preview: {output} ({output.stat().st_size} bytes)")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", type=Path, default=ROOT / "Godot_v4.4.1-stable_linux.x86_64")
    parser.add_argument("--output", type=Path, default=ROOT / "build/windows/LastRitual-ArtPreview.exe")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    export_preview(args.godot.resolve(), args.output.resolve(), args.dry_run)


if __name__ == "__main__":
    main()
