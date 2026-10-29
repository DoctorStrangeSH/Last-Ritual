extends RefCounted
## Stable descriptions of the five Abyss reward offers.

static func name_for(kind: int) -> String:
    match kind:
        0: return "МОЩЬ БАШЕН"
        1: return "ЗАПАС МАНЫ"
        2: return "КРЕПОСТЬ"
        3: return "ДАНЬ ДУШ"
        4: return "ЗАПРЕТНЫЙ ОБМЕН"
    return "НЕИЗВЕСТНЫЙ ДАР"

static func detail_for(kind: int) -> String:
    match kind:
        0: return "+12% урона башен"
        1: return "+35 маны сейчас"
        2: return "+35 здоровья стен"
        3: return "+3 души сейчас"
        4: return "+65 маны, -15 HP стен"
    return ""

static func note_for(kind: int) -> String:
    match kind:
        0: return "до конца забега"
        1: return "+5 маны за врага"
        2: return "восстановление стен"
        3: return "на ритуал или улучшение"
        4: return "риск ради силы"
    return ""
