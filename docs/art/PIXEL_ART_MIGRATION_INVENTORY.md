# Pixel Art Migration Inventory & Legacy Sprite Removal Plan

**Updated: 03.11.2026 — current main snapshot.**  
Main: e1300d21b6bab9c112653a700d361a24f1ef5268. Soul Altar production art is integrated by PR #376; Frost modular art is candidate-only (PR #378); Ballista modular art is candidate-only (PR #380); Fire Turret modular art is candidate-only (PR #382).

This is the authoritative working inventory for replacing old sprite families and then removing them safely. It does not claim that the complete game has already migrated to Pixel Art.

## Owner decision and safe deletion rule

The owner authorized removing the old non-pixel sprite families from the repository and shipped game. Do not keep superseded sprites as permanent fallback art. However, do not delete any resource that the current runtime still loads before its replacement is committed, switched, tested and approved. Keep license/provenance records and editable source for replacement assets.

## Current gameplay identities and asset aliases

Defined in scripts/td/td_tower_stats.gd:
- bone — Bone Ballista; asset folder ballista
- fire — Fire Turret; asset folder fire
- necro — Soul Altar; legacy asset alias pulse, with approved production Pixel Art overrides
- frost — Frost Obelisk; legacy asset alias spark, with experimental Frost overrides

Do not rename gameplay IDs or migrate save data during art-only PRs. Do not treat spark/pulse as independent playable towers; they are asset/design identities, not implemented gameplay IDs.

## Production / candidate status

| Family | Asset status | Runtime status | Remaining gate |
|---|---|---|---|
| Soul Altar (necro) | Owner-approved modular bases L1–L3 and base/Reaper/Legion eight-way weapon atlases; PR #376 | runtime enabled; legacy fallback retained | Owner Windows EXE QA, then separate legacy cleanup |
| Frost Obelisk (frost) | PR #378 candidate pack: 3 bases, 3 eight-way weapon branches, 6 VFX strips, 9/72 contact sheets | runtime disabled; current experimental/Foozle assets unchanged | Owner visual approval at 1×, then separate runtime PR and Windows QA |
| Bone Ballista (bone / ballista) | Candidate pack in progress: 3 bases, base/siege_bolt/bone_volley 8-way weapon branches, 6 VFX strips, 9/72 contact sheets | runtime disabled; original Foozle assets unchanged | Candidate PR CI, owner visual approval at 1×, then separate runtime PR and Windows QA |
| Fire Turret (fire) | PR #382 candidate pack: 3 bases, base/inferno/sparks 8-way weapons, 6 VFX strips, 9/72 contact sheets | runtime disabled; original Foozle assets unchanged | Exact-head CI #41589195484 and post-merge Windows Preview #41589363962 SUCCESS; owner visual approval at 1×, separate runtime PR and Windows QA |

## Soul Altar — production details

- PR #376 merged; root manifest assets/spire/towers/necro/manifest.json is owner_approved_production / runtime_enabled=true.
- Production PNGs: base/level_1..3.png and weapon/base, weapon/reaper, weapon/legion/weapon_8way.png.
- Reaper maps to siege; Legion maps to swarm.
- Existing validated production projectile/impact strips are reused; candidate VFX are not automatically promoted.
- The original candidate archive and reproducible source tools/generate_necro_modular_candidates.py remain in Git.
- Legacy assembled sprites/fallback have not been deleted. Manual Windows QA is still required before cleanup.

## Frost Obelisk — candidate details

- PR #378 merged; exact-head CI #41583127652 and post-merge Windows Preview #41583281398 succeeded.
- Manifest assets/spire/towers/frost/manifest.json: review_candidate / runtime_enabled=false.
- 3 bases; weapon branches base/frost_lance/blizzard; six eight-frame VFX strips.
- Mapping: siege → frost_lance; swarm → blizzard.
- Source: tools/generate_frost_modular_candidates.py; renderer: tools/render_frost_modular_preview.py.
- Existing experimental/Foozle resources remain untouched. No runtime promotion without explicit owner approval.

## Bone Ballista — candidate details

- PR #380 merged; exact-head CI #41585101342 and post-merge Windows Preview #41585253951 SUCCESS. Contact sheets are published in the windows-preview release.
- Manifest: assets/spire/towers/ballista/manifest.json; review_candidate / runtime_enabled=false.
- 3 bases; weapon branches base/siege_bolt/bone_volley; six eight-frame VFX strips.
- Mapping: siege → siege_bolt (heavy single-target bolt); swarm → bone_volley (three-bolt volley).
- Gameplay ID remains bone. Current gameplay labels and stats are unchanged.
- Source: tools/generate_ballista_modular_candidates.py; renderer: tools/render_ballista_modular_preview.py; tests: tests/test_ballista_modular_candidates.py.
- Existing Foozle source/base/weapon/projectile/impact files remain untouched pending approval and separate runtime integration.

## Fire Turret — candidate details

- PR #382 merged; exact-head CI #41589195484 and post-merge Windows Preview #41589363962 SUCCESS. Review sheets are published in windows-preview.
- Manifest: assets/spire/towers/fire/manifest.json; review_candidate / runtime_enabled=false.
- 3 bases; weapon branches base/inferno/sparks; six eight-frame VFX strips.
- Mapping: siege → inferno (heavy flame cannon/explosive impact); swarm → sparks (three-spark volley). Existing gameplay ID and labels are unchanged.
- Source: tools/generate_fire_turret_modular_candidates.py; renderer: tools/render_fire_turret_modular_preview.py; tests: tests/test_fire_turret_modular_candidates.py.
- Review sheets: candidate/review/contact_sheet_9_1x.png, contact_sheet_72_1x.png, contact_sheet_72_2x.png.
- All original Foozle base/weapon/projectiles/weapon_impact files remain untouched. No runtime promotion without owner approval and a separate integration PR.

## Existing legacy families eligible for later removal

| Family / path | Current role | Removal gate |
|---|---|---|
| assets/spire/towers/ballista/ original Foozle paths | Current Bone Ballista base, weapon, projectile and impact | After approved replacement is active, all refs are audited, Windows QA passes |
| assets/spire/towers/fire/ | Current Fire Turret base, weapon, projectile and impact | Same gate after Fire Pixel Art integration |
| assets/spire/towers/pulse/ | Legacy asset alias for Soul Altar | After runtime no longer references it |
| assets/spire/towers/spark/ | Legacy asset alias for Frost Obelisk | After Frost runtime no longer references it |
| assets/spire/towers/necro/experimental/ and production/ | Experimental/legacy Soul Altar resources | After production renderer QA and reference audit |
| assets/spire/towers/frost/experimental/ and vfx/ | Current Frost fallback art and effects | After Frost Pixel Art runtime QA |
| assets/spire/towers_atlas.png and shared variant atlases | Legacy shared atlases | After direct and dynamic reference scan |
| old specialization icon resources | Legacy UI icon art | After replacement PNG icons are committed and UI references are switched |

The old SVG cleanup is complete (PR #314 and prior cleanup PRs). Recount tracked SVGs from the current Git tree before future cleanup; do not recreate removed files.

## Migration order

1. Soul Altar production integration — complete; owner Windows QA pending.
2. Frost Obelisk candidate — complete as candidate; owner visual approval and runtime integration pending.
3. Bone Ballista candidate — complete as candidate; owner visual approval and runtime integration pending.
4. Fire Turret candidate — prepared in active PR; owner visual approval and runtime integration pending.
5. Reconcile Spark/Pulse art identities only against actual runtime gameplay IDs.
6. Enemies and bosses.
7. Hero and player VFX.
8. Fortress/TD world, tiles, paths and environmental props.
9. Dungeon rooms, walls, doors, chests, loot and night effects.
10. UI, menu, HUD, inventory, achievements and icons.
11. Final direct/dynamic reference audit and deletion of superseded sprite atlases/folders.

## Required per-family checklist

- [ ] Hand-authored Pixel Art at a logical resolution; no pixelation filter on realistic art.
- [ ] Consistent camera angle, readable silhouette, palette ramps and outline weight.
- [ ] Editable source committed (Aseprite/LibreSprite or documented procedural/layered equivalent).
- [ ] Transparent PNG exports committed.
- [ ] Manifest records paths, dimensions, frame count, FPS, loop/one-shot, pivot, forward axis and provenance.
- [ ] All eight weapon directions are distinct and share a consistent pivot.
- [ ] Runtime paths switched only after explicit owner approval.
- [ ] Scene/resource/script/test/tool/workflow references scanned.
- [ ] Godot 4.4.1 import and smoke tests pass.
- [ ] Windows preview/export succeeds.
- [ ] Owner visually approves the family in the EXE at gameplay 1×.
- [ ] Old sprite files removed in a separate auditable cleanup PR; list removed paths.
- [ ] ROADMAP, PROJECT_STATE, AI_HANDOFF and AI_HANDOFF_PIXEL_ART updated.

## Documentation cadence

Update this inventory and all handoff/roadmap documents after every meaningful asset migration, deletion, merged PR or owner QA result. Record exact commit/PR, tests, removed paths and manual QA still outstanding.
