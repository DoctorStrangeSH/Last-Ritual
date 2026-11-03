# Last Ritual — six tower asset sets

The four uploaded Foozle towers have been classified by their actual **weapon and projectile** PNGs, not by the old folder labels.

| New asset ID | Russian display name | Was uploaded under | Evidence |
|---|---|---|---|
| `ballista` | Баллиста | `bone` | Crossbow frames and arrow projectiles; 3 upgrade tiers |
| `fire` | Огненная турель | `fire` | Flame-tipped shots, flaming weapon barrel; 3 tiers |
| `spark` | Искровой разрядник | `frost` | Long charged emitter and green electrical spark projectiles; 3 tiers |
| `pulse` | Импульсный излучатель | `necro` | Prismatic emitter with expanding white shockwave projectile; 3 tiers |
| `necro` | Алтарь душ | Original concept created by assistant | Owner-approved modular bases and eight-way weapons; production integrated by PR #376 |
| `frost` | Ледяной обелиск | Original concept created by assistant | Modular Pixel Art candidate pack in `candidate/`; owner review and separate runtime PR still required |

**DO NOT rename existing runtime game IDs automatically.** Current Godot gameplay still uses `bone`, `fire`, `necro`, `frost`. Adding two new IDs `spark` and `pulse` and migrating `bone` to `ballista` requires a separate tested gameplay PR with save compatibility, stats and synergies.

Folder layout for each tower:
`base/level_1..3`, `weapon/level_1..3`, `projectiles/level_1..3`, `weapon_impact/level_1..3`, `specializations/siege`, `specializations/swarm`.

Original Foozle files preserve names and bytes, including horizontal animation sheets. `weapon_impact` is a hit VFX; `projectiles` contains flying ammo. A repeated frame is not an endless construction animation. The editor-side renderer layers base + weapon and uses only verified frame animation timings.

The uploaded `pulse` folder has no weapon_impact PNG in current GitHub input; do not fabricate or mislabel it. The independently generated `necro`/`frost` art should be treated according to each manifest status, not inferred from folder presence.

Manual QA is required before production promotion. Original Foozle packs are CC0 per `assets/spire/LICENSE_AND_MAPPING.txt`; preserve source attribution metadata.
