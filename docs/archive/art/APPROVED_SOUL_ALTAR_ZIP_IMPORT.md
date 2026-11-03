# Approved Soul Altar ZIP import — 2026-11-01

The user's original archive is named `LastRitual_SoulAltar_Approved_RGBA_Source_and_Sprites.zip` (supplied in the conversation). **Do not regenerate another tower.** Its four standalone RGBA images (levels 1–3 and Reaper), original sources, checksums and manifest are the only inputs for this importer.

```bash
python3 tools/install_approved_soul_altar_zip.py LastRitual_SoulAltar_Approved_RGBA_Source_and_Sprites.zip
python3 -m unittest discover -s tests -p 'test_install_approved_soul_altar_zip.py' -v
```

The tool checks exact filenames and byte-for-byte SHA-256 against the archive manifest, accepts only RGBA PNG and 192×192 sprites, rejects unsafe ZIP paths and incomplete files, then writes `assets/spire/towers/necro/approved_renders/{source,sprites,manifest.json}`. Commit all outputs together. These are *whole tower* frames and are isolated for review; they are **not** the separate base/rotating-weapon atlas contract, nor a full Legion/VFX kit. Do not enable `runtime_enabled` or remove current art until full modular 8-direction/3-branch sprites and user gameplay QA are ready.

**Current git status:** This PR supplies only a byte-verified importer and test. It does not include the local binary PNGs from the chat: the available GitHub action cannot read binary files from the chat container. Those binaries must be transferred to Git separately; do not claim this has occurred. The ZIP itself remains downloadable from the chat attachment.
