extends RefCounted
## Deterministic decorative particles for the short build/sell transition.
## Visual-only: does not touch tower state, resources or combat timing.
const OFFSETS := [
    Vector2(-22.0, -10.0),
    Vector2(-13.0, -28.0),
    Vector2(0.0, -35.0),
    Vector2(14.0, -25.0),
    Vector2(23.0, -8.0),
    Vector2(0.0, 8.0)
]

static func particles(origin: Vector2, progress: float, appearing: bool) -> Array[Dictionary]:
    var t := clampf(progress, 0.0, 1.0)
    var result: Array[Dictionary] = []
    for i in range(OFFSETS.size()):
        var offset: Vector2 = OFFSETS[i]
        var phase := float(i) / float(OFFSETS.size() - 1)
        var travel := t if appearing else 1.0 - t
        var direction := -1.0 if appearing else 1.0
        var drift := Vector2(sin((t * 1.4 + phase) * TAU) * 3.0, direction * (8.0 + phase * 13.0) * travel)
        var alpha := (1.0 - t) if appearing else t
        result.append({
            "position": origin + offset + drift,
            "alpha": clampf(alpha * (0.45 + 0.45 * sin((phase + 0.15) * PI)), 0.0, 1.0),
            "size": 1.5 + (1.0 - phase) * 1.5
        })
    return result
