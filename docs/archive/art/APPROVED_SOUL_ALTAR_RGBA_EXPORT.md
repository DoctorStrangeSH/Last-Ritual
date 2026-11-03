# Approved Soul Altar source export (PNG → PNG)

**Owner's fixed decision:** reuse the selected violet/gold Soul Altar art; do not generate more tower concepts. An approved direction sheet exists at `assets/spire/towers/necro/source/concepts/soul_altar_tower_concept_v05.png`.

`tools/prepare_approved_soul_altar.py` is a deterministic, non-generative importer of four original RGBA renders already produced in the conversation. It validates original alpha transparency, preserves each source byte-for-byte, exports nearest-neighbour 192×192 sprites and emits SHA-256 provenance. It does **not** perform aggressive chroma-key removal or fake editable Aseprite files.

Install Pillow, supply the four original PNGs listed in the script, and run:

```bash
python -m pip install Pillow
python tools/prepare_approved_soul_altar.py --source /path/to/approved/originals --output build/approved-soul-altar
```

Expected outputs: `source/*_original.png`, `sprites/{level_1,level_2,level_3,reaper}.png`, `manifest.json`. **The source PNG bytes and exported sprites must be committed together after import.** They are not yet in this PR or in main; this PR only adds the reproducible conversion script and handoff.

Remaining before runtime: separate approved Legion source, genuinely separate upper weapon/base layers and all eight authored directions, distinct base/Reaper/Legion projectile and impact frame atlases, UI icons, Godot preview QA. Do not set `runtime_enabled=true` on the modular tower manifest based only on these four complete-tower sprites.

The original generated PNG files are not accessible through the GitHub connector at this moment. No fabricated binary files or claimed source commits.
