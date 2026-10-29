extends RefCounted
## Pure presentation descriptions for tower abilities.

static func ability_description(kind: String, level: int = 1) -> String:
    if kind == "bone":
        return "Замедление %.1f с" % (2.5 + 0.35 * float(level - 1))
    if kind == "necro":
        return "Скелет: %.0f HP / 6 с" % (65.0 + float(level - 1) * 30.0)
    return "Крит %.0f%% + взрыв" % ((0.18 + 0.04 * float(level - 1)) * 100.0)
