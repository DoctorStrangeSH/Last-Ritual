# Last Ritual — Pixel Art Style Guide (v1)

**Owner-approved direction:** move the whole game to one cohesive, detailed dark-fantasy pixel-art style. This is a production specification, not a claim that all existing art has already been migrated.

## 1. Art direction

- Dark fantasy / gothic roguelite with strong readable silhouettes.
- Hand-authored pixel clusters. Do not apply a pixelation filter to realistic renders and call it finished.
- Materials: charcoal stone, aged bronze, iron, bone, dark wood, ice and magical crystals.
- Magic colors: soul green `#55F28C`, fire `#FF703B`, electric teal `#28E5B0`, arcane violet `#B15FFF`, frost blue `#66CFFF`, bone ivory `#D5B788`.
- Consistent top-down / 3-quarter camera angle across every asset.
- High contrast between units/towers and the ground. Silhouette must remain identifiable at gameplay zoom 1× and when displayed at 50%.
- Keep text out of sprite textures; all Russian names/descriptions belong in Godot UI.

## 2. Pixel grid and sizes

These are starting targets; validate against the actual viewport, pad footprint and camera before locking an asset family.

| Asset | Source target | Notes |
|---|---:|---|
| Small projectile | 16×16 or 24×24 | Strong direction silhouette |
| Standard projectile | 24×24 or 32×32 | Animated 6–8 frames |
| Impact | 32×32 or 48×48 | 6–8 frames, one-shot |
| UI icon | 32×32 or 48×48 | Readable at 24–32 px |
| Standard tower | 64×64 or 96×96 | Transparent canvas, feet/base pivot |
| Large/boss tower | 96×96 or 128×128 | Same logical ground footprint |
| Character | 32×32 or 48×48 | 4/8 directional movement sheets |
| World tile | 16×16 or 32×32 | One tile grid across the project |

Do not upscale small sources non-integerly. Prefer authoring at target resolution. If a larger source is needed, use integer nearest-neighbor scaling only.

## 3. Rendering and Godot import

- Use nearest-neighbor texture filtering for pixel-art CanvasItems. Set the project default and verify per-node overrides; do not assume the current mipmap setting alone enables nearest filtering.
- Disable texture smoothing and mipmap blur for pixel-art assets.
- Avoid fractional scale and subpixel camera positions where they cause shimmer. Use integer scaling/pixel snapping where compatible with the 1152×648 viewport and `canvas_items` stretch mode.
- Do not change the global filter until all active assets are reviewed: a mixed legacy/Pixel Art phase may require per-resource/per-node filtering temporarily.
- Glow is optional and restrained. If used, keep the sprite itself crisp and the glow on a separate layer; avoid blurred halos obscuring the silhouette.

## 4. Palette and material ramps

Use small consistent ramps rather than arbitrary per-sprite colors:
- Stone: deep blue-black → slate → cool grey highlight.
- Bronze: dark umber → bronze → warm gold edge.
- Bone: brown-black shadow → warm ivory → near-white highlight.
- Soul: deep forest green → emerald → mint → pale soul-white.
- Fire: ember brown → orange → gold-white.
- Ice: navy → cyan → pale blue-white.

Use approximately 3–5 tones per material plus tightly controlled highlight pixels. Outlines should be consistent in weight and usually darker than the material, not pure black everywhere.

## 5. Tower modularity and aiming

Every tower should be authored as independently positioned layers:
1. Static base with stable ground/feet pivot.
2. Upper weapon/head layer with a documented rotation pivot.
3. Specialization-specific visual layer.
4. Muzzle flash.
5. Projectile.
6. Impact.
7. Optional idle loop and one-shot build/sell effects.

For a rotating upper part, choose either:
- eight hand-authored directional poses (preferred for pixel art), or
- a single weapon layer that has been checked for rotation artefacts.

Never rotate the complete tower/base. Base remains fixed. Ensure all directional poses share the exact same pivot and canvas bounds.

## 6. Sprite-sheet contract

Every sheet must have a manifest entry with:
- file path, dimensions, frame width/height, columns, rows, frame count;
- FPS, loop/one-shot, frame order;
- pivot/origin and authored forward direction (right/up/down);
- padding, alpha bounds, palette/version, source file and license.

Conventions:
- Horizontal strips unless a documented grid is more efficient.
- Projectile animation: 6–8 frames; each cell has same pivot and forward axis.
- Impact animation: 6–8 frames; one-shot, centred at collision point.
- Tower idle: 6–8 frames, seamless loop; no construction frames in idle.
- Build/destruction: separate one-shot sheets.
- Aim directions: 8-way sheet, or explicitly documented rotation if the art is rotation-safe.

For projectiles authored facing right, align their +X axis to `(target - current).angle()`; for sprites authored facing up, subtract/add the appropriate quarter-turn. Record this in manifest so the next AI does not guess.

## 7. Soul Altar canonical kit

Base forms: L1, L2, L3. The fourth upgrade chooses one permanent branch:
- Жнец / `siege`: heavy single-target soul/scythe shot, slow and high impact.
- Легион / `swarm`: multiple souls/skulls per volley, group pressure.

Create separate base, Reaper and Legion projectile/impact art. Each projectile animates while flying and rotates to travel direction. Tower base remains still; only the top/weapon aims. Keep the sprite visibly larger and centred on the placement pad. Remove stray layers and the accidental line-shot.

## 8. Deliverables and source preservation

For every production asset commit:
- Editable source (Aseprite/LibreSprite or layered equivalent) when created.
- Exported transparent PNG(s).
- Manifest and deterministic export settings/script.
- Source/license/provenance notes.
- Contact sheet for review (not used as runtime art).
- Godot import + headless tests.
- In-game 1× screenshot for visual approval.

Preserve the original Soul Altar concept and source files byte-for-byte. Do not delete a previous asset family until replacement is committed, runtime references are switched, tests pass and the owner has inspected the replacement in an EXE.

## 9. Review checklist

- [ ] Reads at gameplay 1×.
- [ ] One camera angle and coherent perspective.
- [ ] Correct transparent padding and pivots.
- [ ] Nearest filtering, no blur/aliasing.
- [ ] Tower base/weapon layers align at every level.
- [ ] Projectile frame sequence is readable and points forward.
- [ ] Projectile rotates toward actual travel vector.
- [ ] Impact is distinct and one-shot.
- [ ] Specializations differ mechanically and visually.
- [ ] Palette/material ramps match the style bible.
- [ ] Source, manifest, provenance and license committed.
- [ ] CI passes; Windows visual QA recorded separately.
