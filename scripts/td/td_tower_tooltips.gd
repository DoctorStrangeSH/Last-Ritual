extends RefCounted
## Player-facing tower explanations. Keep mechanical values in td_tower_stats.gd.
const STATS = preload("res://scripts/td/td_tower_stats.gd")
const DAMAGE = preload("res://scripts/td/td_tower_damage.gd")
const DETAILS := {
    "bone": {"role": "СНАЙПЕР • ПРЯМОЙ УРОН", "effect": "Сильные одиночные попадания.", "combo": "Рядом с ледяной: +1 по замедленным."},
    "fire": {"role": "ПОДЖОГ • УРОН СО ВРЕМЕНЕМ", "effect": "Поджигает выживших после попадания.", "combo": "Рядом с ледяной: +1 по замедленным."},
    "necro": {"role": "ПРИЗЫВ • ПОДДЕРЖКА", "effect": "Убийства помогают призывать духов.", "combo": "Рядом со льдом духи продлевают холод."},
    "frost": {"role": "КОНТРОЛЬ • ЗАМЕДЛЕНИЕ", "effect": "Замедляет выживших на 2 секунды.", "combo": "Даёт бонусы костям, огню и духам."}
}

static func shop_info(kind: String) -> Dictionary:
    if not DETAILS.has(kind):
        return {}
    var details: Dictionary = DETAILS[kind]
    return {
        "title": str(STATS.DISPLAY_NAMES[kind]),
        "role": str(details["role"]),
        "effect": str(details["effect"]),
        "combo": str(details["combo"]),
        "cost": int(STATS.COSTS[kind]),
        "range": int(STATS.RANGES[kind]),
        "damage": int(DAMAGE.direct_damage(kind, 1, "", 0, 0))
    }

static func upgrade_info(kind: String, level: int, specialization: String, fire_bonus: int, bone_bonus: int) -> Dictionary:
    if not DETAILS.has(kind) or level < 1:
        return {}
    var maxed: bool = level >= 3
    var current_damage: int = DAMAGE.direct_damage(kind, level, specialization, fire_bonus, bone_bonus)
    var next_damage: int = DAMAGE.direct_damage(kind, level + 1, specialization, fire_bonus, bone_bonus) if not maxed else current_damage
    return {
        "title": str(STATS.DISPLAY_NAMES[kind]),
        "maxed": maxed,
        "cost": 0 if maxed else level * 20,
        "current_damage": current_damage,
        "next_damage": next_damage,
        "range": int(STATS.RANGES[kind]),
        "attack_interval": 0.45 if specialization == "swarm" else 0.8,
        "extra": "ОТКРОЮТСЯ 2 ПУТИ РАЗВИТИЯ" if level == 1 else ("ЭФФЕКТ И РАДИУС НЕ МЕНЯЮТСЯ" if not maxed else "БАШНЯ ПОЛНОСТЬЮ УЛУЧШЕНА"),
        "next_level": mini(level + 1, 3),
        "specialization": "На 2 ур. выбери путь башни." if level == 1 else ("Специализация сохранится." if not maxed else "Максимальный уровень."),
        "effect": str(DETAILS[kind]["effect"])
    }

const PATH_DETAILS := {
    "bone": {
        "siege": ["БАЛЛИСТА • ПРОБОЙ", "+2 урона за попадание.", "Костяной снаряд пробивает строй."],
        "swarm": ["КОСТЯНОЙ РОЙ", "Атака раз в 0,45 с вместо 0,8 с.", "На 1 меньше урона за удар."]
    },
    "fire": {
        "siege": ["ИНФЕРНО • ЖАР", "+2 прямого урона.", "Горение сильнее на 2; длится 4 с."],
        "swarm": ["ИСКРЫ • ОХВАТ", "До 3 целей за атаку.", "Быстрее, но -1 прямого урона."]
    },
    "necro": {
        "siege": ["ЖНЕЦ • МОЩЬ", "Дух наносит 4 вместо 2 урона.", "Живёт 5 вместо 4 секунд."],
        "swarm": ["ЛЕГИОН • ЧИСЛО", "Призыв после 2 убийств вместо 3.", "Быстрее атака, -1 прямого урона."]
    },
    "frost": {
        "siege": ["МОРОЗ • СИЛА", "Замедление 40% вместо 25%.", "+2 прямого урона за атаку."],
        "swarm": ["МЕТЕЛЬ • ОХВАТ", "До 3 целей; замедление 20%.", "Быстрее атака, -1 прямого урона."]
    }
}

static func specialization_info(kind: String, path: String, level: int) -> Dictionary:
    if not PATH_DETAILS.has(kind) or not PATH_DETAILS[kind].has(path):
        return {}
    var lines: Array = PATH_DETAILS[kind][path]
    return {
        "title": str(lines[0]),
        "line1": str(lines[1]),
        "line2": str(lines[2]),
        "damage": DAMAGE.direct_damage(kind, level, path, 0, 0),
        "cooldown": 0.45 if path == "swarm" else 0.8
    }

## Synergy wording is based on td_synergy_rules.gd and frost/necro combat handlers.
static func synergy_lines(kind: String, near_fire: bool, near_bone: bool, near_frost: bool) -> Array[String]:
    var lines: Array[String] = []
    if kind == "bone":
        lines.append(("АКТИВНО" if near_fire else "НУЖЕН ОГОНЬ") + ": +2 урона горящим врагам.")
        lines.append(("АКТИВНО" if near_frost else "НУЖЕН ЛЁД") + ": +1 урона замедленным.")
    elif kind == "fire":
        lines.append(("АКТИВНО" if near_bone else "НУЖНЫ КОСТИ") + ": +1 урона горящим врагам.")
        lines.append(("АКТИВНО" if near_frost else "НУЖЕН ЛЁД") + ": +1 урона замедленным.")
    elif kind == "necro":
        lines.append(("АКТИВНО" if near_bone else "НУЖНЫ КОСТИ") + ": +1 урона любому врагу.")
        lines.append(("АКТИВНО" if near_fire else "НУЖЕН ОГОНЬ") + ": +1 урона горящим.")
        lines.append(("АКТИВНО" if near_frost else "НУЖЕН ЛЁД") + ": духи продлевают заморозку.")
    elif kind == "frost":
        lines.append("САМАЯ СИНЕРГИЯ: замедление открывает бонусы.")
        lines.append("КОСТИ И ОГОНЬ: +1 по замедленным.")
        lines.append("НЕКРОМАНТ: духи продлевают заморозку.")
    return lines
