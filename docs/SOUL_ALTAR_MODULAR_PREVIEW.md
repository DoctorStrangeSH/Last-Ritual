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
