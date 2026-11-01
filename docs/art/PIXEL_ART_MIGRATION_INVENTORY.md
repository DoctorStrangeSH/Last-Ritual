# Pixel Art Migration Inventory & Legacy Sprite Removal Plan

**Updated:** 2026-11-01, main snapshot after PR #312 `955252af84ab0eba86775a859fbb029122996e29`.

This is the working inventory for replacing the old art and then removing it completely. It is not a claim that the Pixel Art migration is already complete.

## Owner decision

The owner has explicitly authorized deleting the old non-pixel sprite families from the repository and shipped game. **Do not preserve superseded old sprites as permanent fallback art.** However, do not delete assets that the current runtime still loads before their replacements are committed and switched: doing so would break the game during migration.

Keep:
- license, attribution and mapping/provenance records required for any redistributed third-party-derived content;
- new editable Pixel Art sources, deterministic export scripts, manifests and palette/pivot data;
- approved Soul Altar v0.5 concept sheet as a non-runtime art-direction reference (keep only while useful); old raster cutouts and all old runtime sprite exports are eligible for complete deletion after the Pixel Art replacements are accepted.

## Soul Altar modular manifest contract (PR #312)

- `assets/spire/towers/necro/manifest.json` defines the planned production layout and technical metadata.
- `scripts/td/td_modular_tower_assets.gd` loads/validates manifests, maps eight aim directions and resolves base, weapon and VFX paths.
- `tests/td_modular_tower_assets_smoke.gd` runs in the Godot CI workflow.
- Manifest status is `contract_only`; `runtime_enabled=false`. The PNG paths are future targets, not files already present. The current live renderer still uses the existing assembled/candidate art.
- Keep this manifest generic enough to reuse for the other towers. Create editable pixel source, production PNGs and provenance before enabling it.

## Current active gameplay identities

Defined in `scripts/td/td_tower_stats.gd`:
- `bone`
- `fire`
- `necro`
- `frost`

Asset aliases in `scripts/td/td_tower_visuals.gd`:
- `bone → ballista`
- `fire → fire`
- `necro → pulse` (with experimental/production necro overrides)
- `frost → spark` (with experimental frost overrides)

Do not treat `spark` and `pulse` folders as independently implemented playable gameplay IDs. Their presence is an asset mapping, not a separate tower implementation.

## Existing art families to replace

| Family / path | Current role | Migration / deletion rule |
|---|---|---|
| `assets/spire/towers/ballista/` | Bone/ballista base, weapon, projectile, impact and icons | Replace with Bone Ballista Pixel Art kit, switch runtime, then delete old family |
| `assets/spire/towers/fire/` | Fire tower base, weapon, projectile, impact and icons | Replace with Fire Turret Pixel Art kit, switch runtime, then delete old family |
| `assets/spire/towers/pulse/` | Current necro legacy asset alias | Delete after Soul Altar Pixel Art runtime no longer references it |
| `assets/spire/towers/spark/` | Current frost legacy asset alias | Delete after Frost Obelisk Pixel Art runtime no longer references it |
| `assets/spire/towers/necro/experimental/` | Experimental base/weapon PNGs; current fallback/preview mapping | Delete when the complete Pixel Art Soul Altar runtime is switched |
| `assets/spire/towers/necro/production/` | Original concept-derived, non-pixel candidate PNGs | Replace in runtime with approved Pixel Art; keep originals/source as reference, not as old runtime fallback |
| `assets/spire/towers/necro/source/layers/`, `source/vector/`, `source/vfx/` | Previous SVG source artwork | May be removed after new editable Pixel Art source is committed and provenance no longer depends on these files |
| `assets/spire/towers/frost/experimental/` | Experimental base/weapon PNGs | Delete after Frost Pixel Art runtime is switched |
| `assets/spire/towers/frost/source/` | Previous SVG source artwork | May be removed after replacement source and provenance are committed |
| `assets/spire/towers/frost/vfx/` | Current Frost projectile/impact PNGs | Delete after Pixel Art projectile/impact sheets are switched |
| `assets/spire/towers_atlas.png`, `assets/spire/variants/specialization_icons_atlas.png` | Legacy shared atlases | Scan direct and dynamic references; delete only after no runtime/UI references remain |
| `assets/spire/towers/{ballista,fire,pulse,spark}/specializations/*/icon.svg` | Existing specialization icons | Replace with Pixel Art icons and then delete |

Current Git tree inventory contained 120 image files at the snapshot above (PNG/SVG/etc.). Recount from the tree before each cleanup PR; never rely on this historical count.

## Already removed

PR #306 removed 17 unreferenced standalone SVGs from:
- `assets/backgrounds/`
- `assets/buildings/`
- `assets/characters/`
- `assets/enemies/`
- `assets/towers/`

Evidence: `docs/art/LEGACY_ASSET_CLEANUP.md`. These are already gone and should not be re-created.

## Migration order

1. **Soul Altar Pixel Art pilot:** L1/L2/L3, Reaper, Legion, separate static base and aiming upper weapon (or eight-direction upper poses), unique base/Reaper/Legion projectiles and impacts, idle/attack/build/sell, icons.
2. **Bone Ballista.**
3. **Fire Turret.**
4. **Frost Obelisk.**
5. **Spark/Pulse gameplay art aliases only as needed by actual runtime identities**; do not add playable IDs from art alone.
6. **Enemies and bosses.**
7. **Hero.**
8. **Fortress/TD world, tiles, paths and environmental props.**
9. **Dungeon rooms, walls, doors, chests, loot and night effects.**
10. **UI, menu, HUD, inventory, achievements and icons.**
11. Final reference scan and removal of remaining legacy sprite atlases and folders.

## Required per-family checklist

- [ ] Pixel Art is hand-authored at a logical resolution; no pixelation filter on realistic art.
- [ ] Consistent camera angle, silhouette, palette ramps and outline weight.
- [ ] Editable source committed (Aseprite/LibreSprite or documented equivalent).
- [ ] Transparent PNG exports committed.
- [ ] Manifest records file path, dimensions, frame grid/count, FPS, loop/one-shot, pivot, forward axis, palette, source and license.
- [ ] Runtime paths switched; no old sprite fallback remains for the migrated family.
- [ ] Scene/resource/script/test/tool/workflow references scanned.
- [ ] Godot 4.4.1 import and `tests/topdown_smoke.gd` pass.
- [ ] Windows preview/export succeeds.
- [ ] Owner visually approves the family in the EXE at gameplay 1×.
- [ ] Old sprite files removed in a separate, auditable cleanup commit; removed paths listed in the cleanup report.
- [ ] Roadmap, `AI_HANDOFF.md`, `AI_HANDOFF_PIXEL_ART.md` and `PROJECT_STATE.md` updated.

## Documentation cadence

Update this inventory and the four handoff/roadmap documents after every meaningful asset family migration, asset deletion, merged PR or owner QA result. Always record exact commit/PR, tests, removed paths, and any manual QA still outstanding.
