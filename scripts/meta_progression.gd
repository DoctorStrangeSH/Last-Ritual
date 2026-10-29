extends RefCounted
## Versioned persistent meta progression. Never stores transient run-only relics.
const SCHEMA_VERSION := 1
const DEFAULT_PATH := "user://last_ritual_meta_v1.json"
const MAX_LEVEL := 3
var save_path := DEFAULT_PATH
var fragments := 0
var hero_level := 0
var treasury_level := 0

func load_profile() -> bool:
    if not FileAccess.file_exists(save_path):
        return false
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
    if not data is Dictionary or data.get("version", -1) != SCHEMA_VERSION:
        return false
    var currency: Variant = data.get("fragments", -1)
    var hero: Variant = data.get("hero_level", -1)
    var treasury: Variant = data.get("treasury_level", -1)
    if not currency is int or not hero is int or not treasury is int:
        return false
    if currency < 0 or hero < 0 or hero > MAX_LEVEL or treasury < 0 or treasury > MAX_LEVEL:
        return false
    fragments = currency
    hero_level = hero
    treasury_level = treasury
    return true

func save_profile() -> bool:
    var file := FileAccess.open(save_path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify({"version": SCHEMA_VERSION, "fragments": fragments, "hero_level": hero_level, "treasury_level": treasury_level}))
    file.close()
    return true

func award(amount: int) -> bool:
    if amount <= 0:
        return false
    fragments += amount
    return true

func buy_upgrade(kind: String) -> bool:
    var level := hero_level if kind == "hero" else treasury_level if kind == "treasury" else -1
    if level < 0 or level >= MAX_LEVEL:
        return false
    var cost := level + 1
    if fragments < cost:
        return false
    fragments -= cost
    if kind == "hero":
        hero_level += 1
    else:
        treasury_level += 1
    return true
