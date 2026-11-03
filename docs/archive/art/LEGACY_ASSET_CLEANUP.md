# Legacy SVG cleanup — 2026-11-01

## Removed in this branch

The following 17 legacy standalone SVG assets were removed because they have no references in the current runtime source files or scenes:

### Backgrounds
- `assets/backgrounds/blood_mines.svg`
- `assets/backgrounds/catacombs.svg`
- `assets/backgrounds/cursed_crypt.svg`
- `assets/backgrounds/first_kings_tomb.svg`
- `assets/backgrounds/light_cathedral.svg`
- `assets/backgrounds/siege_dusk.svg`

### Building and character
- `assets/buildings/dark_fortress.svg`
- `assets/characters/dark_lord.svg`

### Enemies
- `assets/enemies/abyss_guardian.svg`
- `assets/enemies/brute.svg`
- `assets/enemies/light_mage.svg`
- `assets/enemies/raider.svg`
- `assets/enemies/runner.svg`
- `assets/enemies/saboteur.svg`

### Old tower illustrations
- `assets/towers/bone_tower.svg`
- `assets/towers/infernal_ballista.svg`
- `assets/towers/necromancer_tower.svg`

## Reference audit

Checked all current `.gd` scripts (including TD, night, run-loop and helper modules), all three `.tscn` scenes, `project.godot`, `export_presets.cfg` and `tests/topdown_smoke.gd`. No direct references to these paths or the old root folders were found.

Current tower runtime paths are separately defined by `scripts/td/td_tower_visuals.gd` and `scripts/td/td_specialization_icons.gd`; those live under `assets/spire/` and are **not part of this deletion**.

## Explicitly retained

- All current `assets/spire/` tower runtime/fallback art and atlases.
- The complete Soul Altar production pack under `assets/spire/towers/necro/production/`.
- Original concept and source cutouts under `assets/spire/towers/necro/source/original/` and `source/concepts/`.
- Foozle CC0 license and mapping file.
- Existing source SVG layers and export/import tools until a replacement pixel-art source pipeline is committed and tested.

## Why this is partial cleanup

The owner approved deleting old sprites, but the game has not yet completed the Pixel Art migration. Deleting active fallback or source files before replacement would create missing textures and break the ability to reproduce the art. Remaining legacy/experimental files are tracked for a later cleanup PR after the corresponding runtime paths are replaced.

## Validation required

This PR must pass Godot 4.4.1 import, `tests/topdown_smoke.gd`, and Windows export. The owner must visually test the resulting EXE. A headless CI pass is not a substitute for manual visual QA.
