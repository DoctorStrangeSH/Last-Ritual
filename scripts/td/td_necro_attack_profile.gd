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
        "impact_size": Vector2(44.0, 44.0)
    },
    "siege": {
        "cooldown": 0.8,
        "kill_streak_threshold": 3,
        "empowered_spirit": true,
        "projectile_size": Vector2(40.0, 40.0),
        "projectile_tint": Color("#efffe7"),
        "impact_size": Vector2(54.0, 54.0)
    },
    "swarm": {
        "cooldown": 0.45,
        "kill_streak_threshold": 2,
        "empowered_spirit": false,
        "projectile_size": Vector2(26.0, 26.0),
        "projectile_tint": Color("#9affbd"),
        "impact_size": Vector2(36.0, 36.0)
    }
}

static func for_specialization(specialization: String) -> Dictionary:
    var key := specialization if PROFILES.has(specialization) else "base"
    return PROFILES[key].duplicate(true)
