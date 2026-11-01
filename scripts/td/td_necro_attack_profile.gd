extends RefCounted
## One source of truth for Soul Altar combat cadence and attack presentation.
## Values intentionally preserve the existing gameplay balance and VFX sizes.
const PROFILES := {
    "base": {
        "cooldown": 0.8,
        "kill_streak_threshold": 3,
        "empowered_spirit": false,
        "projectile_size": Vector2(32.0, 32.0),
        "projectile_tint": Color.WHITE,
        "impact_size": Vector2(44.0, 44.0),
        "arc_height": 0.0,
        "impact_color": Color("#b774ff")
    },
    "siege": {
        "cooldown": 0.8,
        "kill_streak_threshold": 3,
        "empowered_spirit": true,
        "projectile_size": Vector2(40.0, 40.0),
        "projectile_tint": Color("#efffe7"),
        "impact_size": Vector2(54.0, 54.0),
        "arc_height": 14.0,
        "impact_color": Color("#e9a0ff")
    },
    "swarm": {
        "cooldown": 0.45,
        "kill_streak_threshold": 2,
        "empowered_spirit": false,
        "projectile_size": Vector2(26.0, 26.0),
        "projectile_tint": Color("#9affbd"),
        "impact_size": Vector2(36.0, 36.0),
        "arc_height": 7.0,
        "impact_color": Color("#8e6bff")
    }
}

static func for_specialization(specialization: String) -> Dictionary:
    var key := specialization if PROFILES.has(specialization) else "base"
    return PROFILES[key].duplicate(true)

## Visual-only arc: combat damage still resolves on fire.
static func projectile_position(origin: Vector2, target: Vector2, progress: float, specialization: String) -> Vector2:
    var t := clampf(progress, 0.0, 1.0)
    var point := origin.lerp(target, t)
    var delta := target - origin
    if delta.length_squared() < 0.0001:
        return point
    var arc_height: float = float(for_specialization(specialization)["arc_height"])
    return point + Vector2(-delta.y, delta.x).normalized() * (4.0 * t * (1.0 - t) * arc_height)
