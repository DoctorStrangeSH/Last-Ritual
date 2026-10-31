extends RefCounted
## Design-only catalog for day-phase roguelite choices.
## Combat effects are NOT active until explicitly integrated and balanced.

const BOONS := {
    "ember_heart": {"title": "Пепельное сердце", "school": "fire", "rarity": "rare", "effect": "Горящие враги взрываются при смерти."},
    "bone_legion": {"title": "Костяной легион", "school": "bone", "rarity": "rare", "effect": "Каждое десятое убийство призывает скелета."},
    "eternal_frost": {"title": "Вечная мерзлота", "school": "frost", "rarity": "common", "effect": "Замедленные враги получают дополнительный урон."},
    "blood_pact": {"title": "Кровавый договор", "school": "universal", "rarity": "cursed", "effect": "Больше урона башен ценой здоровья алтаря."},
    "necro_crown": {"title": "Корона некроманта", "school": "necro", "rarity": "legendary", "effect": "Призванные существа усиливают ближайшие башни."},
    "ritual_reserve": {"title": "Ритуальный запас", "school": "universal", "rarity": "common", "effect": "Экономическая награда для подготовки к следующей волне."}
}

static func info(id: String) -> Dictionary:
    return BOONS.get(id, {}).duplicate(true)

static func offers(run_seed: int, day: int, count: int = 3) -> Array[String]:
    var ids: Array[String] = []
    if day < 1 or day > 5 or count < 1:
        return ids
    for id in BOONS.keys():
        ids.append(str(id))
    var rng := RandomNumberGenerator.new()
    rng.seed = (run_seed & 0x7fffffff) * 101 + day * 7919 + 47
    for i in range(ids.size() - 1, 0, -1):
        var j: int = rng.randi_range(0, i)
        var previous: String = ids[i]
        ids[i] = ids[j]
        ids[j] = previous
    ids.resize(mini(count, ids.size()))
    return ids
