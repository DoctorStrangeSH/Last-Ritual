extends RefCounted
## Night trophies: run-long relics won at night (elite rooms, the Dark
## Merchant, the Mirror). Each one changes the day siege AND the night hero
## for the rest of the run. Curses pay more but cost
## something. Pure data + helpers; the effects live in topdown_td_prototype.gd
## (search "has_trophy"). Icons: assets/trophies/trophy_icons_8x24.png,
## drawn by tools/generate_trophy_icons.py in ORDER.

const ICON_PATH := "res://assets/trophies/trophy_icons_8x24.png"
const ICON_SIZE := 24
const ORDER := ["warlord_skull", "grave_lantern", "looter_satchel", "warden_stone",
    "phoenix_ash", "soul_lantern", "cursed_idol", "blood_millstone"]
const CATALOG := {
    "warlord_skull": {"title": "ЧЕРЕП ПОЛКОВОДЦА", "effect": "Башни: +2 урона капитанам и боссу", "night": "Ночью: герой +1 урона по чемпионам и боссу", "curse": false},
    "grave_lantern": {"title": "МОГИЛЬНЫЙ ФОНАРЬ", "effect": "Радиус всех башен +6%", "night": "Ночью: дальность атаки героя +15%", "curse": false},
    "looter_satchel": {"title": "СУМА МАРОДЁРА", "effect": "+8 золота за каждую отбитую волну", "night": "Ночью: +1 душа за зачищенную комнату", "curse": false},
    "warden_stone": {"title": "КАМЕНЬ СТРАЖА", "effect": "Каждое утро алтарь +15 ОЗ", "night": "Ночью: входящий урон −2 (не ниже 1)", "curse": false},
    "phoenix_ash": {"title": "ПЕПЕЛ ФЕНИКСА", "effect": "Первый прорыв за день не ранит алтарь", "night": "Ночью: один раз спасает героя от смерти", "curse": false},
    "soul_lantern": {"title": "ФОНАРЬ ДУШ", "effect": "Духи некроманта — на 1 убийство раньше", "night": "Ночью: каждое 4-е убийство лечит 6 ОЗ", "curse": false},
    "cursed_idol": {"title": "ПРОКЛЯТЫЙ ИДОЛ", "effect": "+60 золота утром, но враги быстрее на 10%", "night": "Ночью: враги быстрее на 10%", "curse": true},
    "blood_millstone": {"title": "КРОВАВЫЙ ЖЕРНОВ", "effect": "Башни +1 урона, но ремонт алтаря закрыт", "night": "Ночью: герой +1 урона, лечение вдвое слабее", "curse": true},
}
## Tuning shared by the controller and tests.
const WARLORD_BONUS := 2
const LANTERN_RANGE := 1.06
const SATCHEL_GOLD := 8
const WARDEN_HEAL := 15
const IDOL_GOLD := 60
const IDOL_SPEED := 1.10
const MILLSTONE_BONUS := 1
## Night side (scripts/topdown_night_prototype.gd, search "night_trophy").
const NIGHT_WARLORD_BONUS := 1
const NIGHT_LANTERN_RANGE := 1.15
const NIGHT_SATCHEL_SOULS := 1
const NIGHT_WARDEN_BLOCK := 2
const NIGHT_SOUL_LANTERN_KILLS := 4
const NIGHT_SOUL_LANTERN_HEAL := 6
const NIGHT_IDOL_SPEED := 1.10
const NIGHT_MILLSTONE_BONUS := 1

static func is_valid(id: String) -> bool:
    return CATALOG.has(id)

static func title(id: String) -> String:
    return str(CATALOG.get(id, {}).get("title", ""))

static func effect(id: String) -> String:
    return str(CATALOG.get(id, {}).get("effect", ""))

static func night_effect(id: String) -> String:
    return str(CATALOG.get(id, {}).get("night", ""))

static func is_curse(id: String) -> bool:
    return bool(CATALOG.get(id, {}).get("curse", false))

static func icon_index(id: String) -> int:
    return ORDER.find(id)

## Unique, known ids in catalogue order (drops junk and duplicates).
static func sanitize(list: Array) -> Array[String]:
    var result: Array[String] = []
    for id in ORDER:
        if list.has(id):
            result.append(id)
    return result

## Up to three offers for one elite room: two blessings and, while any curse
## remains, one curse — so every pick is a real "safe or greedy" choice.
## Deterministic for a seed; never offers something already owned.
static func offers(seed_value: int, owned: Array) -> Array[String]:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var blessings: Array[String] = []
    var curses: Array[String] = []
    for id in ORDER:
        if owned.has(id):
            continue
        if is_curse(id):
            curses.append(id)
        else:
            blessings.append(id)
    shuffle(blessings, rng)
    shuffle(curses, rng)
    var picks: Array[String] = []
    for id in blessings:
        if picks.size() >= (2 if not curses.is_empty() else 3):
            break
        picks.append(id)
    if not curses.is_empty() and picks.size() < 3:
        picks.append(curses[0])
    return picks

static func shuffle(list: Array[String], rng: RandomNumberGenerator) -> void:
    for i in range(list.size() - 1, 0, -1):
        var j: int = rng.randi_range(0, i)
        var swap: String = list[i]
        list[i] = list[j]
        list[j] = swap
