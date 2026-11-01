# Last Ritual — Handoff: Pixel Art Migration & Soul Altar Rework

**Updated:** 2026-11-01  
**Verified main snapshot:** PR #304, commit `03222aa1219715fd1f710b66e63e75e255e11382`  
**Primary roadmap:** [ROADMAP.md](ROADMAP.md)  
**Art standard:** [PIXEL_ART_STYLE_GUIDE.md](art/PIXEL_ART_STYLE_GUIDE.md)  
**Project:** `DoctorStrangeSH/Last-Ritual`, Godot 4.4.1, top-down roguelite + Tower Defense.

> This document is the durable handoff for the next AI/developer. Read it before changing art, upgrade logic, combat, or deleting assets. It supersedes older historical statements below when they conflict with the current snapshot. Update it after every meaningful implementation/asset/QA milestone.

## 1. Owner decisions (confirmed)

- The entire game should move to one cohesive, hand-authored **dark-fantasy pixel-art** style. This applies to towers, enemies, hero, world/tiles, dungeon rooms, projectiles, impacts, particles, UI, icons and menus — not only Soul Altar.
- Pixel art should be detailed and readable, not primitive geometric placeholders and not realistic art run through a pixelation filter.
- New assets should be easier to author consistently through a shared palette, grid, sizes, pivots, frame rules and manifest.
- Soul Altar progression is exactly **L1 → L2 → L3 → fourth upgrade: choose Reaper OR Legion**. Specialization is not offered at level 2.
- Reaper and Legion must be different gameplay branches and use different projectile/impact visuals.
- Projectiles must animate frame-by-frame and face their actual travel direction. The tower's upper weapon/head should aim toward its current target while the base stays planted.
- Fix the user-tested defects: tower too small/off-centre, stray detached sprite fragment, unreadable tiny projectiles, and occasional line/beam shots.
- Owner explicitly allows removal of old sprite art. Removal must be dependency-aware: delete obsolete/unused files, but do not break the game, discard the new approved Soul Altar originals, or remove source/licence records needed to reproduce assets.

## 2. Current verified runtime facts (do not guess)

**In-progress implementation on branch `fix/tower-progression-fourth-step-2026-11-01` (awaiting CI/merge):** tower upgrades now use a separate level-3 specialization purchase (cost 60); the first two upgrades remain 20/40. The modal is locked to the pending slot. Old level-2-specialized save snapshots are normalized to level 3 on import. Regression tests were updated for all four runtime schools. Do not call this shipped until its PR exact-head CI and main post-merge workflow succeed.

### Project and test entry points
- Godot version: 4.4.1 Standard (see `.github/workflows/windows-build.yml`).
- Main scene: `scenes/run_loop.tscn`.
- TD scene: `scenes/topdown_td_prototype.tscn`.
- Night scene: `scenes/topdown_night_prototype.tscn`.
- Main TD controller: `scripts/topdown_td_prototype.gd`.
- Automated test: `tests/topdown_smoke.gd`; command: `godot --headless --path . --script res://tests/topdown_smoke.gd`.

### Active gameplay IDs
The current shop/runtime still uses four IDs in `scripts/td/td_tower_stats.gd`: `bone`, `fire`, `necro`, `frost`. `SHOP_ORDER` is these four IDs. `spark` and `pulse` are design/asset identities, not separate playable combat types yet. Preserve existing IDs and save compatibility unless a dedicated migration is designed and tested.

### Upgrade state-machine change (branch in progress)
In `scripts/topdown_td_prototype.gd` and `scripts/td/td_tower_stats.gd`:
- The implementation now defines L1→L2 for 20, L2→L3 for 40, and a fourth purchase at L3 for 60 that opens specialization without changing base level.
- `specialization_pending_slot` locks the modal to the tower being evolved; `choose_specialization()` only accepts `siege`/`swarm` on that level-3 unspecialized tower.
- Existing level-2-specialized fortress snapshots are accepted and normalized to level 3 for backward compatibility.
- `td_tower_tooltips.gd` now explains the two remaining base steps and the separate fourth evolution step.
- Regression tests cover affordability, modal slot lock, invalid/repeated choice, all four current runtime IDs, and legacy-save migration. Exact-head CI and merge are still required before marking this shipped.

### Existing visual/combat defects still open
- `SPECIALIZATION_BUTTONS`, `SPECIALIZATION_LABELS`, `specialization_open`, selected slot UI, and `tower_info_for_slot()` / hover panels remain in the controller.
- Projectile direction/rotation, upper-weapon aiming, projectile/impact branch identity, stray fragment and scale/pivot issues remain open.
- Other towers currently share this upgrade path. Scope the L1→L2→L3→specialization-fourth-step behaviour to `necro` first unless owner explicitly approves changing all tower progression.

### Exact combat/visual entry points
- `attack_with_towers(delta)` selects targets via `choose_tower_target(slot_id)`, uses `TD_MULTIHIT.targets(...)`, applies damage through `scripts/td/td_tower_damage.gd`, and appends visual records to `shot_trails`.
- Current trail record is approximately `{from, to, time, kind, level}`; specialization is not currently carried into the projectile record. Add stable fields for specialization/projectile type and direction as needed.
- `update_shot_trails(delta)`, `visible_shot_trail_start(total)`, and `shot_trail_style(kind)` manage current visuals.
- In `_draw()`, the shot-trail loop interpolates from `from` to `to`, draws a projectile texture region when available, but falls back to `draw_line(from, to, ...)` when no projectile texture is loaded. This fallback explains the unwanted line-shot; remove it for necro and provide a deliberate, visible sprite fallback instead.
- The same loop draws impact textures / procedural fallback. Add explicit projectile and impact IDs so base, Reaper and Legion don't share one generic effect.
- `draw_tower_figure(pos, kind, level, specialization)` currently renders the complete Soul Altar production PNG on an 86×86 rect at `pos + (-43,-76)`; older layered fallbacks use 66×66 at `pos + (-33,-53)`. These are likely too small/misaligned relative to the placement ring shown by the owner. Calibrate using actual transparent bounds and feet/pivot, not arbitrary constants.
- The current production images are complete assembled tower sprites, not separate rotatable weapon layers. Do **not** rotate the entire tower image. New pixel-art production source should separate static base and aiming upper/weapon layer, or provide 8-direction upper-layer poses.
- `scripts/td/td_tower_visuals.gd` owns asset paths and sprite-sheet cell validation (`first_frame_region`, `frame_region`, `vfx_path`, `vfx_frame_size`). It currently maps legacy `necro→pulse` and `frost→spark` fallback folders, while Soul Altar production PNG overrides some paths.
- `scripts/td/td_specialization_icons.gd` maps active IDs to specialization icon SVGs. Replace with pixel-art icons only when replacements are committed and loaded.
- `scripts/td/td_tower_stats.gd` owns shop order, labels, costs/ranges/damage; `scripts/td/td_tower_damage.gd` owns direct-hit damage; `scripts/td/td_targeting.gd` owns target selection.

## 3. Required Soul Altar implementation

### Upgrade state machine
- Level 1 → level 2 → level 3 are the only base-level upgrades.
- At level 3, show a distinct fourth upgrade action: choose one specialization.
- Specialization selection must not accidentally increment the base level beyond 3.
- Once chosen, specialization is permanent for that tower instance unless an explicit respec mechanic is added later.
- Show both specialization choices with Russian name, role, cost, damage/attack style and unique icon.
- UI must clearly distinguish “base level 3” from “specialized level 4”.
- Add tests: L1→L2 doesn't open specialization; L2→L3 doesn't open specialization; only next upgrade opens choice; insufficient coins do nothing; each choice stores correct ID; specialization cannot be selected twice; other tower progression is unchanged.

### Distinct combat branches
- Base Soul Altar: one animated homing/straight-flight soul projectile and its own impact.
- Reaper (`siege` compatibility ID): slow/high-damage single-target attack; unique spectral scythe/soul projectile; strong single-target impact; optionally apply a curse/mark only if fully represented in damage/state/UI/tests.
- Legion (`swarm` compatibility ID): multi-soul/three-skull volley or controlled spread; unique animated projectile; group-oriented impact. Multiple projectiles must be actual projectile records, not a decorative line or a fake multi-hit with one sprite.
- Carry specialization through target selection, projectile spawn, impact, damage and tooltip data. Add regression tests for hit count, target count, damage, cooldown and branch identity.
- Do not rebalance unrelated towers in the same PR.

### Direction and animation
- Projectile frame sheet has explicit manifest fields: frame size, columns/rows, frame count, FPS, loop, source forward direction, pivot/center and alpha bounds.
- Use the vector `to - from`; calculate angle with `Vector2.angle()` / `atan2` and rotate the sprite so its authored forward axis aligns with travel. Document whether the sprite source faces right or up; account for this offset.
- Animate while moving (not just one frame selected from projectile progress). Use delta/time and stable frame selection; avoid frame flicker dependent on FPS.
- Impact is a separate one-shot animation anchored to the actual hit point; it must finish and disappear.
- For the tower, keep base static. Aim only the weapon/head layer. Prefer 8-direction pixel-art poses if arbitrary rotation would distort pixel clusters; if using rotation, confirm the artwork is rotationally suitable.
- Remove the necro line fallback; no line is drawn over or instead of the necro projectile. Other towers' existing visuals should remain unchanged.
- Draw order and pivot must prevent detached weapon/overlay fragments.

## 4. Pixel-art production standard

Read `docs/art/PIXEL_ART_STYLE_GUIDE.md` before drawing/importing assets.

- Hand-authored pixel art, consistent dark-fantasy palette and top-down/3-quarter camera.
- Nearest filtering, no smoothing/blur, no fractional scaling for pixel-art sprites, no mipmap blur.
- Establish a logical pixel grid and integer display scale. Keep world tile size and sprite pixel dimensions compatible with the 1152×648 viewport and camera.
- Use consistent outline weight, material ramps, limited highlights and restrained magic glow.
- Sprite sheets: fixed cell size, transparent padding, consistent pivots and documented frame order/timing.
- Maintain readable silhouette at actual gameplay zoom 1× and on both dark/light map backgrounds.
- Each tower needs a coherent kit: base L1/L2/L3, upper weapon/aim poses, two specializations, idle, muzzle flash, projectile, impact, construction/destruction, UI icons.
- Every new asset must include an editable source (Aseprite/LibreSprite file or documented layered source), exported PNG, manifest and provenance/license. Keep original approved sources byte-for-byte.

## 5. Asset inventory and deletion policy

### Keep (not obsolete)
- `assets/spire/towers/necro/production/` — approved concept-derived production candidate PNGs and manifest.
- `assets/spire/towers/necro/source/original/` and `source/concepts/` — original cutouts and v0.5 concept; preserve byte-for-byte.
- `assets/spire/LICENSE_AND_MAPPING.txt` and original Foozle attribution/license records.
- Active current fallback/runtime assets until each has a tested pixel-art replacement: `assets/spire/towers/{ballista,fire,pulse,spark,necro,frost}/` selected files, specialization icon SVGs, atlases and active Frost/legacy fallback assets.
- Import/export tools and source files until their replacement workflow is committed and validated.

### Initial cleanup candidates (verify again before deleting)
- Legacy standalone SVGs under `assets/backgrounds/`, `assets/buildings/`, `assets/characters/`, `assets/enemies/`, `assets/towers/` appear to have no direct references in the current `.gd` scripts or `.tscn` scenes inspected for this handoff. They may be removed in a dedicated cleanup PR only after a full-project reference scan and successful Godot import/smoke/Windows build.
- Do not delete `assets/spire/towers/necro/experimental/`, `frost/experimental/`, fallback PNGs, source SVG layers, or active icons merely because they are old. First remove code/test/tool references and replace all active visuals.
- No blanket deletion of all `assets/spire` folders: the current four gameplay IDs still resolve paths through `td_tower_visuals.gd`.

### Safe deletion workflow
1. Generate a complete asset inventory from Git tree.
2. Search exact path/name references in all scripts, scenes, resources, project settings, tests, tools and workflows; account for dynamic path builders.
3. Classify each file: active, fallback, source, license, test-only, unreferenced candidate.
4. Delete only unreferenced candidates in a separate PR; list every removed path and evidence.
5. Run Godot 4.4.1 headless import and `tests/topdown_smoke.gd`; inspect workflow and Windows export.
6. Keep a recoverable commit in Git history. Never delete original Soul Altar sources or licensed provenance.

## 6. PR / QA order

1. **P0 gameplay fix:** implement Soul Altar L1→L2→L3→specialization step 4 and tests.
2. **P0 visual fix:** correct tower scale, center/pivot and detached fragment; test five forms on the actual TD pad.
3. **P0 combat VFX:** split base/Reaper/Legion projectile and impact records, animate and rotate projectiles, remove necro line fallback.
4. **Pixel-art pilot:** create and approve a complete Soul Altar pixel-art kit; compare against owner screenshot/reference at in-game 1×.
5. **Style pipeline:** add source files, export/validation tool, manifest and palette/pivot rules.
6. **Tower migration:** convert other active tower kits one at a time; do not expose new tower IDs before combat exists.
7. **World migration:** enemies, hero, environment, paths, dungeon rooms and UI.
8. **Cleanup:** remove superseded old sprites only after references are gone and replacements pass QA.
9. **Windows manual QA:** owner tests current EXE; record scale, centering, projectile direction, animation, impacts, specialization choice and performance.
10. **Release:** update roadmap, AI handoff and project state; publish EXE only from successful main build.

## 7. Required recurring documentation updates

After every merged PR or meaningful milestone:
- Update the current summary at the top of `docs/AI_HANDOFF.md`.
- Update this handoff with new file paths/functions, tests, known defects and changed decisions.
- Update the first section of `docs/ROADMAP.md` with checked/unchecked criteria; never mark manual QA complete from headless CI.
- Update the top snapshot in `docs/PROJECT_STATE.md`.
- If a decision changes, record it in `docs/DECISIONS.md`.
- Keep the top summary current and concise; append historical detail only when useful.
- In the final response, report PR, merge commit, exact CI result, manual QA status, removed paths and next step.

## 8. Current next task

First verify and merge the fourth-step upgrade PR. Then implement the user's screenshot fixes and projectile/impact animation/direction. The 17 unreferenced root SVGs under backgrounds/buildings/characters/enemies/towers were removed in PR #306; see `docs/art/LEGACY_ASSET_CLEANUP.md`. Active `assets/spire` fallbacks and source files remain until their Pixel Art replacements are tested. Do not delete active sprite folders.
