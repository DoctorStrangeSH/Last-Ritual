extends RefCounted
## Deterministic connected dungeon topology. No scene transitions yet.
const ROOM_TOTAL := 10
const STEPS := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

static func generate_floor(seed_value: int) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var positions: Array[Vector2i] = [Vector2i.ZERO]
    var occupied := {Vector2i.ZERO: 0}
    var edges: Array[Vector2i] = []
    var attempts := 0
    while positions.size() < ROOM_TOTAL and attempts < 1000:
        attempts += 1
        var parent_id := rng.randi_range(0, positions.size() - 1)
        var origin := positions[parent_id]
        var direction: Vector2i = STEPS[rng.randi_range(0, STEPS.size() - 1)]
        var destination: Vector2i = origin + direction
        if occupied.has(destination):
            continue
        var id := positions.size()
        occupied[destination] = id
        positions.append(destination)
        edges.append(Vector2i(parent_id, id))
    var rooms: Array[Dictionary] = []
    for id in range(positions.size()):
        var kind := "БОЙ"
        if id == 0:
            kind = "ВХОД"
        elif id == positions.size() - 1:
            kind = "БОСС"
        elif id == positions.size() - 2:
            kind = "СОКРОВИЩНИЦА"
        elif id == positions.size() - 3:
            kind = "МАГАЗИН"
        elif id % 4 == 0:
            kind = "ЭЛИТА"
        rooms.append({"id": id, "grid": positions[id], "kind": kind, "neighbors": []})
    for edge in edges:
        rooms[edge.x]["neighbors"].append(edge.y)
        rooms[edge.y]["neighbors"].append(edge.x)
    return {"seed": seed_value, "start": 0, "boss": positions.size() - 1, "rooms": rooms}

static func reachable(floor_data: Dictionary) -> bool:
    var rooms: Array = floor_data.get("rooms", [])
    if rooms.is_empty() or not floor_data.has("start") or not floor_data.has("boss"):
        return false
    var start_id := int(floor_data["start"])
    if start_id < 0 or start_id >= rooms.size():
        return false
    var seen := {start_id: true}
    var queue := [start_id]
    while not queue.is_empty():
        var id: int = queue.pop_front()
        for neighbor in rooms[id]["neighbors"]:
            var next_id := int(neighbor)
            if next_id < 0 or next_id >= rooms.size():
                return false
            if not seen.has(next_id):
                seen[next_id] = true
                queue.append(next_id)
    return seen.size() == rooms.size() and seen.has(int(floor_data["boss"]))
