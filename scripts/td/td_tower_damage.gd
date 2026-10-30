extends RefCounted
## Pure direct-hit damage calculation shared by all existing tower schools.
static func direct_damage(kind: String, level: int, specialization: String, fire_bonus: int, bone_bonus: int) -> int:
    const BASE_DAMAGE := {"bone": 2, "fire": 1, "necro": 3, "frost": 1}
    if not BASE_DAMAGE.has(kind) or level < 1:
        return 0
    var damage: int = int(BASE_DAMAGE[kind]) * level
    if specialization == "siege":
        damage += 2
    elif specialization == "swarm":
        damage = maxi(1, damage - 1)
    if kind == "fire":
        damage += fire_bonus
    elif kind == "bone":
        damage += bone_bonus
    return damage
