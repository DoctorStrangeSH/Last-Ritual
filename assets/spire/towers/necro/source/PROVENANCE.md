# Soul Altar art provenance

## Approved art direction
- The owner-approved art direction reference is preserved at `source/concepts/soul_altar_tower_concept_v05.png`.
- The approved visual language is dark fantasy pixel art: charcoal stone, brass/gold trim, saturated violet soul-fire, skull motifs, and crisp high-contrast silhouettes.
- The owner explicitly rejected further alternate Soul Altar concepts. Do not generate another tower design.

## Source status
- The current session produced five separate transparent RGBA tower renders matching the approved visual direction: base levels 1–3, Reaper, and Legion.
- Those generated source PNGs are 1254×1254. A trimmed five-frame atlas has been prepared locally at 96×132 pixels per frame with alpha transparency. The original source filenames and SHA-256 digests are recorded in the current working session.
- The generated source PNGs and prepared atlas have **not yet been committed to this Git branch**. Do not claim they are available to the game until the binary assets appear in Git and pass Godot import.
- No editable Aseprite project exists yet. Do not create an empty or fabricated `.aseprite` file and call it source. Preserve the generated PNG originals and create an editable layered project only when a real source project is available.

## Removed legacy formats
- All tracked SVG sprite/template/icon/VFX assets were removed in the SVG cleanup branch.
- The old SVG preview exporters and validator were removed from CI.
- The specialization UI currently retains Russian labels but no image icon until PNG icons are committed.
