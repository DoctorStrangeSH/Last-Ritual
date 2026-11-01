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

## Align +X-authored projectile sprites with the instantaneous travel tangent.
## Derivative of the curved visual path; no gameplay hit timing is changed.
static func projectile_rotation(origin: Vector2, target: Vector2, progress: float, specialization: String) -> float:
    var delta := target - origin
    if delta.length_squared() < 0.0001:
        return 0.0
    var t := clampf(progress, 0.0, 1.0)
    var arc_height: float = float(for_specialization(specialization)["arc_height"])
    var tangent := delta + Vector2(-delta.y, delta.x).normalized() * (4.0 * (1.0 - 2.0 * t) * arc_height)
    return tangent.angle()

## Lightweight visual-only particle samples attached to a flying soul.
## This generates no gameplay objects and leaves all approved PNGs untouched.
static func trail_samples(origin: Vector2, target: Vector2, progress: float, specialization: String) -> Array[Dictionary]:
    var samples: Array[Dictionary] = []
    if specialization != "siege" and specialization != "swarm":
        return samples
    # Suppress lingering particles at landing; impacts own the final visual.
    var landing_fade := clampf((1.0 - progress) / 0.22, 0.0, 1.0)
    if landing_fade <= 0.0:
        return samples
    var count := 4 if specialization == "siege" else 2
    var step := 0.055 if specialization == "siege" else 0.09
    var max_radius := 4.5 if specialization == "siege" else 3.0
    for index in range(count):
        var age_progress: float = clampf(progress - float(index + 1) * step, 0.0, 1.0)
        if progress <= float(index + 1) * step:
            continue
        var opacity := (1.0 - float(index) / float(count)) * 0.65 * landing_fade
        samples.append({
            "position": projectile_position(origin, target, age_progress, specialization),
            "radius": max_radius * (1.0 - float(index) / float(count)) + 0.5,
            "opacity": opacity
        })
    return samples
