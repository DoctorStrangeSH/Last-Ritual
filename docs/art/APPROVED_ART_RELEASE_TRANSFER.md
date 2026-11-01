# One-time transfer of the already approved Soul Altar PNGs into Git

**No new art generation.** Four source PNGs and their four 192×192 RGBA sprite exports already exist in the conversation archive `LastRitual_SoulAltar_Approved_RGBA_Source_and_Sprites.zip`. Local verification confirms the alpha channels and all manifest hashes.

The GitHub connector can edit text files but cannot directly receive binary files from the chat attachment. To bridge that boundary once:

1. Download the existing approved ZIP from the conversation.
2. In GitHub, open **Releases → Draft a new release**, create tag **`soul-altar-approved-rgba-v1`**, upload the ZIP **without renaming it**, and publish the release.
3. The workflow `Import owner-approved Soul Altar RGBA archive` runs automatically. It compares the exact SHA-256 hashes of all eight files with the known conversation archive, copies originals byte-for-byte, and opens a PR adding `assets/spire/towers/necro/approved_renders/source/`, `sprites/` and `manifest.json`.
4. If repository policy disables pull requests from GitHub Actions, the uploaded review branch remains available; create a PR manually from `art/approved-soul-altar-rgba-v1`.

**Do not use the Windows-preview tag for this.** These images are whole towers, not independent static base + 8-way weapon and distinct VFX; therefore the runtime `assets/spire/towers/necro/manifest.json` remains `runtime_enabled=false`. The images still require a visual pass at gameplay 1×, Legion, separate weapon poses and new VFX before replacing the live tower.

The approved-art ZIP is the source of truth; do not redraw, replace it with a purple-background concept sheet, or synthesize an Aseprite source file.
