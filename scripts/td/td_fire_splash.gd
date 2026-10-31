extends RefCounted
## Small-radius fire splash, using existing enemy dictionaries without changing saves.
const RADIUS := 32.0
const MAX_ADDITIONAL := 2

static func add_splash_targets(primary: Array, nearby: Array, main_target: Dictionary, radius: float = RADIUS) -> Array:
    var result: Array = primary.duplicate()
    var added := 0
    var center: Vector2 = main_target.get("pos", Vector2.ZERO)
    for enemy in nearby:
        if result.has(enemy) or float(enemy.get("delay", 0.0)) > 0.0:
            continue
        if (enemy.get("pos", Vector2.ZERO) as Vector2).distance_to(center) > radius:
            continue
        result.append(enemy)
        added += 1
        if added >= MAX_ADDITIONAL:
            break
    return result
