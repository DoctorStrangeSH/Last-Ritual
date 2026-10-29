extends RefCounted
## Versioned persistent meta progression. Never stores transient run-only relics.
const SCHEMA_VERSION := 1
const DEFAULT_PATH := "user://last_ritual_meta_v1.json"
const MAX_LEVEL := 3
const ACHIEVEMENT_REWARDS := {"first_steps": 2, "survivor": 4, "ritual_master": 6}
var save_path := DEFAULT_PATH
var fragments := 0
var hero_level := 0
var treasury_level := 0
var runs_started := 0
var runs_won := 0
var runs_lost := 0
var phases_cleared := 0
var claimed_achievement_rewards: Array[String] = []

func load_profile() -> bool:
    if not FileAccess.file_exists(save_path):
        return false
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
    if not data is Dictionary or data.get("version", -1) != SCHEMA_VERSION:
        return false
    var currency: Variant = data.get("fragments", -1)
    var hero: Variant = data.get("hero_level", -1)
    var treasury: Variant = data.get("treasury_level", -1)
    if not (currency is int or currency is float) or not (hero is int or hero is float) or not (treasury is int or treasury is float):
        return false
    if float(currency) != floorf(float(currency)) or float(hero) != floorf(float(hero)) or float(treasury) != floorf(float(treasury)):
        return false
    if currency < 0 or hero < 0 or hero > MAX_LEVEL or treasury < 0 or treasury > MAX_LEVEL:
        return false
    var stats := [data.get("runs_started", 0), data.get("runs_won", 0), data.get("runs_lost", 0), data.get("phases_cleared", 0)]
    for value in stats:
        if not (value is int or value is float) or float(value) != floorf(float(value)) or value < 0:
            return false
    if stats[1] + stats[2] > stats[0]:
        return false
    var claims: Variant = data.get("claimed_achievement_rewards", [])
    if not claims is Array:
        return false
    var validated_claims: Array[String] = []
    for claim in claims:
        if not claim is String or not ACHIEVEMENT_REWARDS.has(claim) or validated_claims.has(claim):
            return false
        validated_claims.append(claim)
    fragments = int(currency)
    hero_level = int(hero)
    treasury_level = int(treasury)
    runs_started = int(stats[0])
    runs_won = int(stats[1])
    runs_lost = int(stats[2])
    phases_cleared = int(stats[3])
    claimed_achievement_rewards = validated_claims
    return true

func save_profile() -> bool:
    var file := FileAccess.open(save_path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify({"version": SCHEMA_VERSION, "fragments": fragments, "hero_level": hero_level, "treasury_level": treasury_level, "runs_started": runs_started, "runs_won": runs_won, "runs_lost": runs_lost, "phases_cleared": phases_cleared, "claimed_achievement_rewards": claimed_achievement_rewards}))
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

func record_start() -> void:
    runs_started += 1

func record_phase_clear() -> void:
    phases_cleared += 1
    grant_achievement_rewards()

func record_result(won: bool) -> void:
    if won:
        runs_won += 1
        grant_achievement_rewards()
    else:
        runs_lost += 1

func grant_achievement_rewards() -> Array[String]:
    var newly_claimed: Array[String] = []
    for raw_id in ACHIEVEMENT_REWARDS.keys():
        var id := str(raw_id)
        if achievement_unlocked(id) and not claimed_achievement_rewards.has(id):
            fragments += int(ACHIEVEMENT_REWARDS[id])
            claimed_achievement_rewards.append(id)
            newly_claimed.append(id)
    return newly_claimed

func achievement_unlocked(id: String) -> bool:
    match id:
        "first_steps":
            return phases_cleared >= 1
        "survivor":
            return phases_cleared >= 6
        "ritual_master":
            return runs_won >= 1
        _:
            return false
