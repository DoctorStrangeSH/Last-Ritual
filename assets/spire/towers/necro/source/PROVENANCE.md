# Soul Altar art provenance

## Approved art direction
- The owner-approved art direction reference is preserved at `source/concepts/soul_altar_tower_concept_v05.png`.
- The approved visual language is dark fantasy pixel art: charcoal stone, brass/gold trim, saturated violet soul-fire, skull motifs, and crisp high-contrast silhouettes.
- The owner explicitly rejected further alternate Soul Altar concepts. Do not generate another tower design.

## Source status
- The current session produced five separate transparent RGBA tower renders matching the approved visual direction: base levels 1–3, Reaper, and Legion.
- Those generated source PNGs are 1254×1254. A trimmed five-frame atlas has been prepared locally at 96×132 pixels per frame with alpha transparency. The original source filenames and SHA-256 digests are recorded in the current working session.
- The generated source PNGs are packaged in the review ZIP; the production atlas is committed in Git. The Aseprite project is not available.
- No editable Aseprite project exists yet. Do not create an empty or fabricated `.aseprite` file and call it source. Preserve the generated PNG originals and create an editable layered project only when a real source project is available.

## Committed production asset
- `production/pixel_art/soul_altar_approved_atlas.png` — transparent RGBA PNG, 320×88, five 64×88 frames in order L1/L2/L3/Reaper/Legion, 32-color indexed palette. The game draws each frame at 2× nearest-neighbour scale.

## Removed legacy formats
- All tracked SVG sprite/template/icon/VFX assets were removed in the SVG cleanup branch.
- The old SVG preview exporters and validator were removed from CI.
- The specialization UI currently retains Russian labels but no image icon until PNG icons are committed.
