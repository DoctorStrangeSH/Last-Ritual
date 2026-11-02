# Soul Altar modular motion preview

This is an isolated review scene. It does **not** replace the production tower renderer and refuses any candidate manifest with `runtime_enabled=true`.

## Launch

From the repository root with Godot 4.4.1:

```sh
godot --path . scenes/dev/soul_altar_modular_motion_preview.tscn
```

The target moves around the tower. The weapon frame updates to the nearest of eight directions.

## Controls

- `1`, `2`, `3`: choose the base level.
- `B`: standard Soul Altar weapon.
- `R`: Reaper weapon.
- `L`: Legion weapon.

The preview uses the candidate manifest and candidate PNGs only. It aligns the weapon pivot `(64,90)` to the base ground anchor `(64,118)`; therefore the weapon canvas is drawn 28 pixels lower than the base canvas. Nearest-neighbour filtering preserves pixel edges.

A missing/invalid manifest or texture produces a visible warning and never falls back by replacing the production tower. This scene is a technical motion/alignment preview, not artistic approval or a gameplay integration.

## Standalone Windows review build

The Windows Preview release also contains `LastRitual-ArtPreview.exe`. It starts directly in this isolated scene, so the owner can test the moving-target direction changes without installing Godot or changing the normal game executable.

- `LastRitual.exe`: normal game; its main scene remains `scenes/run_loop.tscn`.
- `LastRitual-ArtPreview.exe`: review-only build; starts in this scene.
- `soul_altar_modular_contact_sheet.png`: static 24-pose sheet with pivot-correct compositing.

The preview executable is a QA aid, not a gameplay build. Candidate sprites remain disabled in the production manifest.

## Full 72-pose contact sheet

The release contact sheet now shows **all three base levels**, not only level 3:

- Level 1: standard / Reaper / Legion, eight directions each.
- Level 2: standard / Reaper / Legion, eight directions each.
- Level 3: standard / Reaper / Legion, eight directions each.

Run `python tools/render_necro_modular_preview.py --all-levels`. The PNG is 2156×3312 and contains 72 base/weapon composites. Row spacing includes the full 156px source composite height at 2× nearest-neighbour scale; no rows overlap.

## Manual direction inspection

The standalone preview supports deterministic inspection in addition to its moving target:

- Numpad `8, 9, 6, 3, 2, 1, 4, 7`: lock weapon to N, NE, E, SE, S, SW, W, NW.
- `A`: resume automatic moving-target mode.
- `H`: toggle base/weapon bounds and shared pivot guide.
- `1/2/3`: base level; `B/R/L`: standard/Reaper/Legion.

This makes it possible to inspect every individual frame and each of the nine base/weapon combinations at a fixed direction. It remains a review-only scene.
