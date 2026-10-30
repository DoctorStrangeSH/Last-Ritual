extends RefCounted
## Select additional enemies hit by existing bone pierce or fire Sparks.
static func targets(tower: Dictionary, target: Dictionary, enemies: Array, attack_range: float) -> Array:
    var result: Array = [target]
    var kind: String = str(tower.get("tower", ""))
    if kind == "fire" and str(tower.get("specialization", "")) == "swarm":
        for candidate in enemies:
            if candidate == target or float(candidate.get("delay", 0.0)) > 0.0 or result.size() >= 3:
                continue
            if tower["pos"].distance_to(candidate["pos"]) <= attack_range:
                result.append(candidate)
    elif kind == "bone":
        var nearest: float = tower["pos"].distance_to(target["pos"])
        var direction: Vector2 = (target["pos"] - tower["pos"]).normalized()
        for candidate in enemies:
            if candidate == target or float(candidate.get("delay", 0.0)) > 0.0 or result.size() >= 3:
                continue
            var relative: Vector2 = candidate["pos"] - tower["pos"]
            var along: float = relative.dot(direction)
            var across: float = absf(direction.cross(relative))
            if along > nearest and along <= attack_range and across <= 24.0:
                result.append(candidate)
    return result
