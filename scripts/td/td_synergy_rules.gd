extends RefCounted
## Pure synergy rules for tower schools. No scene, RNG or combat state.
## Keep combat and inspector on the same result.
static func preview(kind: String, near_fire: bool, near_bone: bool) -> Dictionary:
    var flat := 0
    var burning := 0
    if kind == "bone" and near_fire:
        burning = 2
    elif kind == "fire" and near_bone:
        burning = 1
    elif kind == "necro":
        flat = 1 if near_bone else 0
        burning = 1 if near_fire else 0
    return {"flat": flat, "burning": burning}
