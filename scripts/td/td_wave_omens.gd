extends RefCounted
## «Знамения угрозы»: a pre-wave risk/reward choice for the day siege.
##
## Before waves 2–5 the player may accept one of two scouted threats. A threat
## adds specific enemies on one focused route and pays a bounty once the wave
## is cleared; omen enemies give no kill gold. Declining keeps the original wave. Everything here is pure and
## deterministic by (map seed, day, wave), so tests and the balance simulator
## see exactly what the player sees. Omens are per-wave and never saved.

const FIRST_WAVE := 2
const LAST_WAVE := 5

## extra: role -> count added on the focus lane; scale_role gets +1 per two days.
## hp: bonus HP for every ordinary enemy of the wave; brute_hp: only for brutes.
## speed: multiplier for runners; pace: spawn-interval multiplier for the wave.
const CATALOG := {
    "raiders": {"title": "НАЛЁТЧИКИ", "extra": {"runner": 3}, "scale_role": "runner", "speed": 1.15, "reward": 18,
        "hint": "мороз и огонь по площади"},
    "ironclad": {"title": "ЖЕЛЕЗНЫЙ КУЛАК", "extra": {"brute": 2}, "scale_role": "brute", "brute_hp": 4, "reward": 22,
        "hint": "огонь пробивает броню"},
    "zealots": {"title": "ФАНАТИКИ", "extra": {"healer": 1, "grunt": 1}, "scale_role": "grunt", "hp": 3, "reward": 20,
        "hint": "цель «Поддержка»"},
    "horde": {"title": "ОРДА", "extra": {"grunt": 4}, "scale_role": "grunt", "reward": 18,
        "hint": "Легион и Искры"},
    "vanguard": {"title": "АВАНГАРД", "extra": {"grunt": 2, "runner": 1}, "scale_role": "runner", "pace": 0.65, "reward": 16,
        "hint": "кости пробивают строй"},
}
const ORDER := ["raiders", "ironclad", "zealots", "horde", "vanguard"]
const ROLE_LABELS := {"runner": "бегун", "brute": "щитоносец", "healer": "лекарь", "grunt": "пехотинец"}

static func available(wave: int) -> bool:
    return wave >= FIRST_WAVE and wave <= LAST_WAVE

## Two distinct omen IDs for the given upcoming wave, or [] when none apply.
static func offers(map_seed: int, day: int, wave: int) -> Array[String]:
    var result: Array[String] = []
    if not available(wave):
        return result
    var rng := RandomNumberGenerator.new()
    rng.seed = (map_seed & 0x7fffffff) * 977 + day * 131 + wave * 17 + 5
    var pool: Array = ORDER.duplicate()
    var first: int = rng.randi_range(0, pool.size() - 1)
    result.append(str(pool[first]))
    pool.remove_at(first)
    result.append(str(pool[rng.randi_range(0, pool.size() - 1)]))
    return result

## Resolved effect of one omen for a day/wave: counts, modifiers, reward, lane.
static func resolve(omen_id: String, map_seed: int, day: int, wave: int, lane_count: int) -> Dictionary:
    if not CATALOG.has(omen_id) or not available(wave) or lane_count < 1:
        return {}
    var data: Dictionary = CATALOG[omen_id]
    var extra: Dictionary = (data["extra"] as Dictionary).duplicate()
    var scale_role: String = str(data["scale_role"])
    var day_scale: int = maxi(0, day - 1) / 2
    extra[scale_role] = int(extra.get(scale_role, 0)) + day_scale
    var rng := RandomNumberGenerator.new()
    rng.seed = (map_seed & 0x7fffffff) * 389 + day * 53 + wave * 7 + ORDER.find(omen_id) * 3 + 1
    return {
        "id": omen_id,
        "title": str(data["title"]),
        "extra": extra,
        "hp": int(data.get("hp", 0)),
        "brute_hp": int(data.get("brute_hp", 0)),
        "speed": float(data.get("speed", 1.0)),
        "pace": float(data.get("pace", 1.0)),
        "reward": int(data["reward"]) + day * 2 + wave,
        "lane": rng.randi_range(0, lane_count - 1),
        "hint": str(data["hint"]),
    }

static func extra_count(effect: Dictionary) -> int:
    var total := 0
    for role in (effect.get("extra", {}) as Dictionary).keys():
        total += int(effect["extra"][role])
    return total

## Short Russian description of what the omen adds, e.g. "+3 бегуна, +12% скорости".
static func describe(effect: Dictionary) -> String:
    if effect.is_empty():
        return ""
    var parts: PackedStringArray = []
    for role in ["runner", "brute", "healer", "grunt"]:
        var count: int = int((effect["extra"] as Dictionary).get(role, 0))
        if count > 0:
            parts.append("+%d %s" % [count, ROLE_LABELS[role]])
    if float(effect["speed"]) > 1.0:
        parts.append("бегуны +%d%% скорости" % roundi((float(effect["speed"]) - 1.0) * 100.0))
    if int(effect["hp"]) > 0:
        parts.append("все +%d ОЗ" % int(effect["hp"]))
    if int(effect["brute_hp"]) > 0:
        parts.append("щиты +%d ОЗ" % int(effect["brute_hp"]))
    if float(effect["pace"]) < 1.0:
        parts.append("плотный строй")
    return ", ".join(parts)

## Route names from top to bottom by the average height of each path.
static func lane_names(paths: Array) -> Array[String]:
    var names: Array[String] = []
    var heights: Array = []
    for path in paths:
        var total := 0.0
        for point in path:
            total += float((point as Vector2).y)
        heights.append(total / maxf(1.0, float((path as Array).size())))
    for index in range(paths.size()):
        var rank := 0
        for other in range(paths.size()):
            if float(heights[other]) < float(heights[index]):
                rank += 1
        if paths.size() == 2:
            names.append("СЕВЕРНЫЙ" if rank == 0 else "ЮЖНЫЙ")
        else:
            names.append(["СЕВЕРНЫЙ", "СРЕДНИЙ", "ЮЖНЫЙ"][mini(rank, 2)])
    return names
