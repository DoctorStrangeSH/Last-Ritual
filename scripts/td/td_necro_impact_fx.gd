extends RefCounted
## Procedural soul burst used only when no production impact sheet is mapped.
## Pure visual helper: deterministic and independent of combat/game state.
const DIRECTIONS := [
    Vector2(0.0, -1.0),
    Vector2(0.866, -0.5),
    Vector2(0.866, 0.5),
    Vector2(0.0, 1.0),
    Vector2(-0.866, 0.5),
    Vector2(-0.866, -0.5)
]

static func particles(origin: Vector2, progress: float) -> Array[Dictionary]:
    var t := clampf(progress, 0.0, 1.0)
    var result: Array[Dictionary] = []
    for i in range(DIRECTIONS.size()):
        var direction: Vector2 = DIRECTIONS[i]
        var distance := lerpf(3.0, 25.0, t)
        var wobble := sin(t * PI + float(i) * 0.8) * 2.5
        result.append({
            "position": origin + direction * distance + Vector2(wobble, 0.0),
            "alpha": 1.0 - t,
            "size": lerpf(4.0, 1.0, t),
            "direction": direction
        })
    return result
