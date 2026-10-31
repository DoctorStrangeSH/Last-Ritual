extends RefCounted
## Pure burn status calculations. Caller handles enemy removal and rewards.
static func apply(enemy: Dictionary, fire_bonus: int) -> void:
    enemy["burn_time"] = 3.0
    enemy["burn_tick"] = 0.5
    enemy["burn_damage"] = 1 + fire_bonus

static func advance(enemy: Dictionary, delta: float) -> bool:
    if float(enemy.get("burn_time", 0.0)) <= 0.0:
        return false
    var active_delta: float = minf(maxf(delta, 0.0), float(enemy["burn_time"]))
    enemy["burn_time"] = maxf(0.0, float(enemy["burn_time"]) - active_delta)
    enemy["burn_tick"] = float(enemy.get("burn_tick", 0.5)) - active_delta
    while float(enemy["burn_tick"]) <= 0.0:
        enemy["hp"] -= int(enemy.get("burn_damage", 1))
        enemy["burn_tick"] = float(enemy["burn_tick"]) + 0.5
        if enemy["hp"] <= 0:
            return true
    return false
