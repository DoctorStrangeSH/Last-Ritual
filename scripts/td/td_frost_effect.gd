extends RefCounted
## Frost tower status rules, pure and reusable. No tower is unlocked yet.
const MIN_SPEED_MULTIPLIER := 0.45

static func apply(enemy: Dictionary, duration: float = 2.0, strength: float = 0.25) -> void:
    enemy["frost_time"] = maxf(float(enemy.get("frost_time", 0.0)), maxf(duration, 0.0))
    enemy["frost_strength"] = clampf(maxf(float(enemy.get("frost_strength", 0.0)), strength), 0.0, 1.0 - MIN_SPEED_MULTIPLIER)

static func multiplier(enemy: Dictionary) -> float:
    if float(enemy.get("frost_time", 0.0)) <= 0.0:
        return 1.0
    # Elites retain enough movement to remain threatening even under renewed chill.
    var role: String = str(enemy.get("role", ""))
    var minimum: float = 0.70 if role == "boss" else (0.60 if role == "captain" else MIN_SPEED_MULTIPLIER)
    return maxf(minimum, 1.0 - float(enemy.get("frost_strength", 0.0)))

static func advance(enemy: Dictionary, delta: float) -> void:
    if float(enemy.get("frost_time", 0.0)) > 0.0:
        enemy["frost_time"] = maxf(0.0, float(enemy["frost_time"]) - maxf(delta, 0.0))
        if float(enemy["frost_time"]) <= 0.0:
            enemy["frost_strength"] = 0.0
