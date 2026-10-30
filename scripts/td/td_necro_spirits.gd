extends RefCounted
## Pure spirit construction and nearest-enemy targeting; battle rewards stay in TD scene.
static func create(origin: Vector2, empowered: bool) -> Dictionary:
    return {"pos": origin, "life": 5.0 if empowered else 4.0, "cooldown": 0.0, "damage": 4 if empowered else 2}

static func select_target(spirit: Dictionary, enemies: Array) -> Dictionary:
    var target: Dictionary = {}
    var nearest := 170.0
    for enemy in enemies:
        if float(enemy.get("delay", 0.0)) > 0.0:
            continue
        var distance: float = spirit["pos"].distance_to(enemy["pos"])
        if distance < nearest:
            nearest = distance
            target = enemy
    return target
