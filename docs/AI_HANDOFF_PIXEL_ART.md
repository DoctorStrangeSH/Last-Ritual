# Last Ritual — Handoff: Pixel Art Migration & Soul Altar

**Updated:** 2026-11-01 — approved Soul Altar atlas wired into the live TD renderer.  
**Base main:** `5bb40ec30d91fe37c52435117868dd56e7c6a482`. Godot 4.4.1.  
**Owner decision:** the already-selected Soul Altar design is final; do not generate another tower concept.

**Runtime integration:** `assets/spire/towers/necro/production/pixel_art/soul_altar_approved_atlas.png` contains five transparent 64×88 cells in order L1/L2/L3/Reaper/Legion. The TD renderer displays the selected cell at 2× nearest-neighbour size (128×176). The resolver and live drawing are in `scripts/td/td_tower_visuals.gd` and `scripts/topdown_td_prototype.gd::draw_tower_figure()`. A Godot smoke test verifies import, alpha, atlas size and all five mappings.

**Source policy:** the atlas is the committed raster source; the approved concept PNG remains under `source/concepts/`; `tools/export_soul_altar_approved_atlas.py` extracts each frame and 2× version. The five high-resolution generated source PNGs remain in the review ZIP, not yet as individual Git files. No Aseprite project was supplied, so do not fabricate one.

**Still outstanding:** the atlas is five complete tower silhouettes, not separate base and weapon layers. The upper weapon does not aim independently. Separate Pixel Art projectile/impact families, idle/attack/build/sell animations and UI icons remain to be made from this same approved art direction. Keep modular `runtime_enabled=false` until those resources exist; do not delete non-SVG fallback assets before the full replacement passes owner QA.


## 1. Owner decisions (confirmed)

- The entire game should move to one cohesive, hand-authored **dark-fantasy pixel-art** style. This applies to towers, enemies, hero, world/tiles, dungeon rooms, projectiles, impacts, particles, UI, icons and menus — not only Soul Altar.
- Pixel art should be detailed and readable, not primitive geometric placeholders and not realistic art run through a pixelation filter.
- New assets should be easier to author consistently through a shared palette, grid, sizes, pivots, frame rules and manifest.
- Soul Altar progression is exactly **L1 → L2 → L3 → fourth upgrade: choose Reaper OR Legion**. Specialization is not offered at level 2.
- Reaper and Legion must be different gameplay branches and use different projectile/impact visuals.
- Projectiles must animate frame-by-frame and face their actual travel direction. The tower's upper weapon/head should aim toward its current target while the base stays planted.
- Fix the user-tested defects: tower too small/off-centre, stray detached sprite fragment, unreadable tiny projectiles, and occasional line/beam shots.
- Owner explicitly authorizes complete deletion of old non-pixel sprite families from the repository and shipped game after their Pixel Art replacements are integrated. Do not retain old art as permanent fallback. Preserve legal licenses/attribution, editable sources for new art and the approved Soul Altar concept sheet as a reference; old cutout/gameplay sprites may be deleted after replacement.

## 2. Current verified runtime facts (do not guess)

**Merged and verified:** PR #307 implements L1→L2 (20), L2→L3 (40), then a separate fourth purchase (60) to choose specialization while keeping base level 3. The pending-slot modal, invalid/repeated-choice guards, tooltips and legacy-save normalization are implemented. Exact-head and post-merge CI passed. The same four-step progression currently applies to all four active gameplay IDs (`bone`, `fire`, `necro`, `frost`); do not silently narrow it to necro.

### Project and test entry points
- Godot version: 4.4.1 Standard (see `.github/workflows/windows-build.yml`).
- Main scene: `scenes/run_loop.tscn`.
- TD scene: `scenes/topdown_td_prototype.tscn`.
- Night scene: `scenes/topdown_night_prototype.tscn`.
- Main TD controller: `scripts/topdown_td_prototype.gd`.
- Automated test: `tests/topdown_smoke.gd`; command: `godot --headless --path . --script res://tests/topdown_smoke.gd`.

### Active gameplay IDs
The current shop/runtime still uses four IDs in `scripts/td/td_tower_stats.gd`: `bone`, `fire`, `necro`, `frost`. `SHOP_ORDER` is these four IDs. `spark` and `pulse` are design/asset identities, not separate playable combat types yet. Preserve existing IDs and save compatibility unless a dedicated migration is designed and tested.

### Upgrade state-machine change (PR #307 merged)
In `scripts/topdown_td_prototype.gd` and `scripts/td/td_tower_stats.gd`:
- The implementation now defines L1→L2 for 20, L2→L3 for 40, and a fourth purchase at L3 for 60 that opens specialization without changing base level.
- `specialization_pending_slot` locks the modal to the tower being evolved; `choose_specialization()` only accepts `siege`/`swarm` on that level-3 unspecialized tower.
- Existing level-2-specialized fortress snapshots are accepted and normalized to level 3 for backward compatibility.
- `td_tower_tooltips.gd` now explains the two remaining base steps and the separate fourth evolution step.
- Regression tests cover affordability, modal slot lock, invalid/repeated choice, all four current runtime IDs, and legacy-save migration. PR #307 is merged; automated CI passed. Owner should verify the new cost/progression in Windows EXE.

### Current visual/combat status after PR #309
- PR #309 is merged at `300415d74ba7abc1e768673d59cc435c89d394c9`; main CI run #41281253322 passed both `checks` and `windows-preview`.
- Tower progression is fixed by PR #307 for all four active runtime IDs.
- PR #309 enlarged and centred the assembled Soul Altar draw rect to 120px high, preserves aspect ratio, and crops the disconnected left-edge Reaper scythe sliver in the display region only. Original PNG remains unchanged. Owner's next EXE test must confirm actual visible alpha bounds and pad alignment; no manual visual approval is recorded yet.
- Necro projectile phase now animates by elapsed time at 24 FPS, follows `from→to`, rotates its authored +X axis toward travel, then spawns a separate 8-frame one-shot impact. The necro beam/line fallback is removed; missing necro texture uses a small directional soul bolt. Summoned spirits also use soul bolts.
- Reaper fires one large heavy single-target projectile; Legion fires up to three independent smaller projectiles at up to three targets. Both still share the current candidate soul projectile/impact texture family; unique hand-authored Pixel Art sheets are not done.
- Upper tower weapon/head does NOT yet aim independently. Current assembled production PNG is one image; do not rotate the complete tower. Create modular pixel-art base + upper weapon layer or eight directional upper poses.
- The screenshot's scale/crop issues have code fixes but still need owner confirmation in the latest EXE. Global Pixel Art migration has not started.

### Modular asset contract (PR #312 merged)

- Manifest: `assets/spire/towers/necro/manifest.json`.
- Shared helper: `scripts/td/td_modular_tower_assets.gd`.
- Contract test: `tests/td_modular_tower_assets_smoke.gd`, wired into `.github/workflows/windows-build.yml`.
- Canonical weapon direction order: north, north-east, east, south-east, south, south-west, west, north-west. The helper maps the existing specialization IDs `siege→reaper` and `swarm→legion`.
- The manifest describes a 128×128 shared canvas and pivot (64,90), three base levels, separate base/Reaper/Legion weapon sheets, and independent projectile/impact sheets with frame sizes/FPS/forward axis.
- **Contract only:** `runtime_enabled=false`; all listed PNGs are planned paths, not committed Pixel Art exports. The helper is not yet used by the live renderer. Do not remove or replace current runtime art based on the manifest alone.
- Exact-head PR CI #41284865922 passed; post-merge main CI #41284911635 was queued at documentation time.

### Exact combat/visual entry points
- `attack_with_towers(delta)` selects targets via `choose_tower_target(slot_id)`, uses `TD_MULTIHIT.targets(...)`, applies damage through `scripts/td/td_tower_damage.gd`, and appends visual records to `shot_trails`.
- Current trail record is approximately `{from, to, time, kind, level}`; specialization is not currently carried into the projectile record. Add stable fields for specialization/projectile type and direction as needed.
- `update_shot_trails(delta)`, `visible_shot_trail_start(total)`, and `shot_trail_style(kind)` manage current visuals.
- In `_draw()`, the shot-trail loop interpolates from `from` to `to`, draws a projectile texture region when available, but falls back to `draw_line(from, to, ...)` when no projectile texture is loaded. This fallback explains the unwanted line-shot; remove it for necro and provide a deliberate, visible sprite fallback instead.
- The same loop draws impact textures / procedural fallback. Add explicit projectile and impact IDs so base, Reaper and Legion don't share one generic effect.
- `draw_tower_figure(pos, kind, level, specialization)` currently renders the assembled Soul Altar production PNG on a 120px-tall rect, aspect-preserving and bottom-centred at the placement slot; Reaper display crop is `Rect2(40, 0, 152, 192)` to hide a disconnected left-edge sliver. Older experimental layered fallbacks still use a 66×66 rect. Treat 120px as an unverified calibration, not final approval: measure visible alpha bounds and align the stone footprint to the pad.
- The current production images are complete assembled tower sprites, not separate rotatable weapon layers. Do **not** rotate the entire tower image. New pixel-art production source should separate static base and aiming upper/weapon layer, or provide 8-direction upper-layer poses.
- `scripts/td/td_tower_visuals.gd` owns asset paths and sprite-sheet cell validation (`first_frame_region`, `frame_region`, `vfx_path`, `vfx_frame_size`). It currently maps legacy `necro→pulse` and `frost→spark` fallback folders, while Soul Altar production PNG overrides some paths.
- `scripts/td/td_specialization_icons.gd` currently returns an empty texture path after SVG cleanup. Russian text labels remain; add PNG icon paths only when approved transparent icons are committed.
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

### Owner's updated deletion decision (2026-11-01)
The owner explicitly authorizes **complete removal of the old non-pixel sprite families** from the shipped project and repository once their replacements are ready. Do not preserve old sprites as permanent runtime fallbacks. Migrate one asset family at a time, switch all runtime references, pass import/smoke/export checks, then delete the superseded sprite files in the same or a follow-up cleanup PR.

### Preserve (not disposable)
- The approved Soul Altar v0.5 concept and original cutouts in `assets/spire/towers/necro/source/concepts/` and `source/original/` as visual provenance/reference, byte-for-byte.
- License, attribution and mapping records (including `assets/spire/LICENSE_AND_MAPPING.txt` and Foozle license records) while any derived assets remain in the repository or release history.
- New pixel-art editable sources (Aseprite/LibreSprite or equivalent), export scripts, manifests, palette, pivots and source provenance.

### Legacy sprites to remove after replacements
- Active art under `assets/spire/towers/{ballista,fire,pulse,spark,frost,necro}/` still contains legacy PNGs and experimental candidates. All 33 SVG assets were removed in the cleanup branch; replace remaining PNG art family-by-family after approved Pixel Art kits are committed and switched.
- `assets/spire/towers_atlas.png` and `assets/spire/variants/specialization_icons_atlas.png` are also candidates for deletion after a reference scan proves they are no longer loaded.
- PR #306 removed 17 root SVGs; the SVG cleanup branch removes the remaining 33 tracked SVGs. Keep the repository free of new SVG sprite templates.

### Safety gate
Do not delete an active runtime asset before its Pixel Art replacement is committed and the runtime path has been switched; otherwise the current EXE/game will lose visuals. The owner authorizes full removal **as part of migration**, not a broken interim build. Every deletion PR must include a generated inventory, exact removed paths, a reference scan covering scripts/scenes/resources/settings/tests/tools, Godot import + smoke tests, and a successful Windows export. Preserve Git history; do not retain obsolete sprites as a fallback after a family is migrated.

### Safe deletion workflow
1. Generate a complete asset inventory from Git tree.
2. Search exact path/name references in all scripts, scenes, resources, project settings, tests, tools and workflows; account for dynamic path builders.
3. Classify each file: active, fallback, source, license, test-only, unreferenced candidate.
4. Delete only unreferenced candidates in a separate PR; list every removed path and evidence.
5. Run Godot 4.4.1 headless import and `tests/topdown_smoke.gd`; inspect workflow and Windows export.
6. Keep a recoverable commit in Git history. Never delete original Soul Altar sources or licensed provenance.

## 6. PR / QA order (current after PR #307 and #309)

1. Owner manually verifies the latest Windows EXE: L1/L2/L3/fourth specialization purchase, scale/centre/Reaper crop, Reaper single shot, Legion multi-shot, projectile animation/rotation, impacts and no necro beam.
2. Create the first true hand-authored Pixel Art pilot kit for Soul Altar; do not pixelate realistic source images with a filter.
3. Separate static base from aiming upper weapon/head, preferably with eight directional pixel poses sharing one pivot.
4. Create unique base/Reaper/Legion projectile and impact sheets; keep real gameplay projectile records distinct.
5. Commit editable source, deterministic exporter, palette, manifest (dimensions, frames, FPS, pivot, forward axis, license/provenance) and contact sheet.
6. Get owner approval at gameplay 1×; only then lock the pilot as the visual reference for other families.
7. Migrate remaining towers, enemies, hero, world, dungeon, VFX and UI family by family.
8. After each family is switched and validated, delete its old sprite assets completely; no permanent legacy fallback.
9. Run Godot import/smoke tests and Windows export; manual owner QA is recorded separately.
10. Update handoffs, roadmap and inventory after every meaningful merge, asset migration/deletion and owner QA.

## 7. Required recurring documentation updates

After every merged PR or meaningful milestone:
- Update the current summary at the top of `docs/AI_HANDOFF.md`.
- Update this handoff with new file paths/functions, tests, known defects and changed decisions.
- Update the first section of `docs/ROADMAP.md` with checked/unchecked criteria; never mark manual QA complete from headless CI.
- Update the top snapshot in `docs/PROJECT_STATE.md`.
- If a decision changes, record it in `docs/DECISIONS.md`.
- Keep the top summary current and concise; append historical detail only when useful.
- In the final response, report PR, merge commit, exact CI result, manual QA status, removed paths and next step.

## 8. Current next task (after PR #309)

1. Owner tests the latest Windows build and confirms the PR #307 progression plus PR #309 tower size/centering, Reaper crop, Reaper single shot, Legion multi-shot, animated/rotating soul bolts, impacts and absence of necro beam.
2. Create the first true Pixel Art production kit for Soul Altar: L1/L2/L3, distinct Reaper and Legion top/weapon forms, static base + aim layer (or 8-way upper poses), base/Reaper/Legion projectile sheets and impact sheets, idle/build/attack frames, UI icons.
3. Use that kit as the art-direction pilot. Obtain owner approval at gameplay 1× before locking the style for other families.
4. Build the reproducible source pipeline: editable source, palette, export script, manifest with cell size/FPS/pivot/forward axis/license and contact sheet.
5. Migrate the other active tower families, then enemies/hero/world/dungeon/UI. Delete each superseded old sprite family from Git after references are switched and CI/Windows export passes. Do not keep old art as permanent fallback.
6. Preserve only approved reference originals, legal/licensing provenance and new editable source files; never delete licenses needed for redistributed assets.
