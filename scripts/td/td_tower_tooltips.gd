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
        "next_level": mini(level + 1, 3),
        "specialization": "На 2 ур. выбери путь башни." if level == 1 else ("Специализация сохранится." if not maxed else "Максимальный уровень."),
        "effect": str(DETAILS[kind]["effect"])
    }
