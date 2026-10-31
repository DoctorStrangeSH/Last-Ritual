extends RefCounted
## Pure target selection independent from scene state.
static func choose(tower: Dictionary, enemies: Array, ranges: Dictionary) -> Dictionary:
    var kind: String = str(tower.get("tower", ""))
    if kind == "" or not ranges.has(kind):
        return {}
    var priority: String = str(tower.get("target_priority", "nearest"))
    var best: Dictionary = {}
    var best_score := -INF
    for enemy in enemies:
        if float(enemy.get("delay", 0.0)) > 0.0:
            continue
        var distance: float = tower["pos"].distance_to(enemy["pos"])
        if distance > float(ranges[kind]):
            continue
        var score: float = -distance
        if priority == "support":
            score += 10000.0 if str(enemy.get("role", "")) == "healer" else 0.0
        elif priority == "front":
            score = float(enemy["pos"].x)
        if score > best_score:
            best_score = score
            best = enemy
    return best
