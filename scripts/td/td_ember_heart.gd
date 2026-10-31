extends RefCounted
## One controlled splash on a burn kill. Caller owns removal, rewards and VFX.
const RADIUS := 85.0
const DAMAGE := 2

static func splash_targets(origin: Vector2, enemies: Array[Dictionary], frost_combo: bool = false) -> Array[Dictionary]:
    var defeated: Array[Dictionary] = []
    for enemy in enemies:
        if int(enemy.get("hp", 0)) <= 0 or float(enemy.get("delay", 0.0)) > 0.0:
            continue
        if origin.distance_to(Vector2(enemy.get("pos", Vector2.INF))) > RADIUS:
            continue
        var bonus: int = 1 if frost_combo and float(enemy.get("frost_time", 0.0)) > 0.0 else 0
        enemy["hp"] = int(enemy["hp"]) - DAMAGE - bonus
        if int(enemy["hp"]) <= 0:
            defeated.append(enemy)
    return defeated
