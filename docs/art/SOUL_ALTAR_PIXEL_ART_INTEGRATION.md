# Soul Altar — approved Pixel Art runtime integration

**Stage:** the owner's approved five-frame atlas is now integrated into the live top-down TD renderer.

## In-game mapping
- One transparent indexed PNG atlas: 320×88 px, five 64×88 cells.
- Frame order: L1, L2, L3, Reaper, Legion.
- Each cell is drawn at 2× nearest-neighbour size (128×176 px) and anchored by its bottom edge to the tower placement point.
- Existing gameplay specialization IDs remain unchanged: `siege` selects Reaper and `swarm` selects Legion.

## Scope boundary
The five images are complete tower silhouettes, not separate base/weapon layers. The upper weapon cannot independently aim yet. New Pixel Art projectile/impact sets and idle/attack/build/sell animations are not included. The modular manifest runtime remains disabled until those resources exist.

## Source
The atlas is the committed raster source; the approved concept remains at `assets/spire/towers/necro/source/concepts/soul_altar_tower_concept_v05.png`. `tools/export_soul_altar_approved_atlas.py` extracts each frame and 2× nearest-neighbour variants. No Aseprite file is fabricated.

## Acceptance
Godot import + alpha/frame-mapping smoke test + existing top-down smoke test + Windows Preview. Owner visual QA remains a separate gate before deleting old non-SVG resources.
