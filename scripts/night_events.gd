extends RefCounted
## Night events: each СОБЫТИЕ room shows one of these, chosen per floor so two
## event rooms on the same night differ. Pure data; the effects live in
## topdown_night_prototype.gd (choose_shrine_blessing). Art:
## assets/night/event_icons_4x48.png drawn by tools/generate_night_events.py.

const ICON_PATH := "res://assets/night/event_icons_4x48.png"
const ICON_SIZE := 48
const ORDER := ["altar", "grave", "fountain", "mirror"]
const CATALOG := {
    "altar": {"title": "ДРЕВНИЙ АЛТАРЬ", "text": "Фиолетовое пламя просит дара.",
        "options": ["+15 ЗДОРОВЬЯ", "−10 ЗД · +1 УРОН", "ОТКАЗАТЬСЯ"]},
    "grave": {"title": "РАЗРЫТАЯ МОГИЛА", "text": "Под костями блестят души. Мёртвые не спят.",
        "options": ["КОПАТЬ: +5 ДУШ, ЗАСАДА", "ПОМОЛИТЬСЯ: +10 ЗД", "УЙТИ"]},
    "fountain": {"title": "КРОВАВЫЙ ФОНТАН", "text": "Кровь даёт силу — и забирает её.",
        "options": ["ИСПИТЬ: −20 ЗД · +6 ДУШ", "ОМЫТЬСЯ: +30 ЗД · 3 ДУШИ", "УЙТИ"]},
    "mirror": {"title": "ЗЕРКАЛО ТЕНЕЙ", "text": "Отражение предлагает трофей. Или проклятие.",
        "options": ["ЗАГЛЯНУТЬ: ТРОФЕЙ ИЛИ ПРОКЛЯТИЕ", "РАЗБИТЬ: +2 УРОНА · −15 ЗД", "УЙТИ"]},
}
const GRAVE_SOULS := 5
const GRAVE_AMBUSH := 3
const FOUNTAIN_DRINK_HP := 20
const FOUNTAIN_DRINK_SOULS := 6
const FOUNTAIN_BATHE_HP := 30
const FOUNTAIN_BATHE_COST := 3
const MIRROR_BREAK_DAMAGE := 2
const MIRROR_BREAK_HP := 15

static func title(id: String) -> String:
    return str(CATALOG.get(id, {}).get("title", ""))

static func text(id: String) -> String:
    return str(CATALOG.get(id, {}).get("text", ""))

static func options(id: String) -> Array:
    return CATALOG.get(id, {}).get("options", [])

static func icon_index(id: String) -> int:
    return ORDER.find(id)

## Event for the `ordinal`-th event room of a floor (0, 1, ...): a per-floor
## shuffle of ORDER, so one night never repeats an event.
static func for_room(floor_seed: int, ordinal: int) -> String:
    var rng := RandomNumberGenerator.new()
    rng.seed = floor_seed * 97 + 13
    var deck: Array = ORDER.duplicate()
    for i in range(deck.size() - 1, 0, -1):
        var j: int = rng.randi_range(0, i)
        var swap = deck[i]
        deck[i] = deck[j]
        deck[j] = swap
    return str(deck[posmod(ordinal, deck.size())])
