extends RefCounted
## Deterministic connected dungeon topology. No scene transitions yet.
const ROOM_TOTAL := 10
const STEPS := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

## Chance that a floor holds a second elite room / a second event room.
const SECOND_ELITE_CHANCE := 0.3
const SECOND_EVENT_CHANCE := 0.5

static func generate_floor(seed_value: int) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    # Grow a random tree; retry (deterministically) until it has dead ends to
    # hide the secret and the treasury in, besides the boss.
    var topology: Dictionary = {}
    for attempt in range(24):
        topology = grow_tree(rng)
        if spare_leaves(topology).size() >= 2:
            break
    var positions: Array = topology["positions"]
    var edges: Array = topology["edges"]
    var kinds: Array = assign_kinds(topology, rng)
    var rooms: Array[Dictionary] = []
    for id in range(positions.size()):
        rooms.append({"id": id, "grid": positions[id], "kind": kinds[id], "neighbors": []})
    for edge in edges:
        rooms[edge.x]["neighbors"].append(edge.y)
        rooms[edge.y]["neighbors"].append(edge.x)
    return {"seed": seed_value, "start": 0, "boss": int(topology["boss"]), "rooms": rooms}

static func grow_tree(rng: RandomNumberGenerator) -> Dictionary:
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
    var degree: Array[int] = []
    degree.resize(positions.size())
    var adjacency: Array = []
    for i in range(positions.size()):
        adjacency.append([])
    for edge in edges:
        degree[edge.x] += 1
        degree[edge.y] += 1
        adjacency[edge.x].append(edge.y)
        adjacency[edge.y].append(edge.x)
    # Depth from the entrance; the boss waits in the farthest room.
    var depth: Array[int] = []
    depth.resize(positions.size())
    depth.fill(-1)
    depth[0] = 0
    var queue := [0]
    while not queue.is_empty():
        var id: int = queue.pop_front()
        for next_id in adjacency[id]:
            if depth[next_id] < 0:
                depth[next_id] = depth[id] + 1
                queue.append(next_id)
    var boss := 0
    for id in range(positions.size()):
        if depth[id] > depth[boss] or (depth[id] == depth[boss] and id > boss):
            boss = id
    return {"positions": positions, "edges": edges, "degree": degree, "depth": depth, "boss": boss}

## Dead ends other than the entrance and the boss room.
static func spare_leaves(topology: Dictionary) -> Array[int]:
    var leaves: Array[int] = []
    var degree: Array = topology["degree"]
    for id in range(1, degree.size()):
        if int(degree[id]) == 1 and id != int(topology["boss"]):
            leaves.append(id)
    return leaves

## Room roles from the graph's shape: secret and treasury hide in dead ends
## (optional detours), the merchant sits deeper than the first rooms, and the
## mix of elites, events and fights changes from floor to floor.
static func assign_kinds(topology: Dictionary, rng: RandomNumberGenerator) -> Array:
    var total: int = topology["positions"].size()
    var boss: int = topology["boss"]
    var depth: Array = topology["depth"]
    var kinds: Array = []
    kinds.resize(total)
    kinds.fill("БОЙ")
    kinds[0] = "ВХОД"
    kinds[boss] = "БОСС"
    var free: Array[int] = []
    for id in range(1, total):
        if id != boss:
            free.append(id)
    var leaves: Array[int] = spare_leaves(topology)
    var secret: int = take(leaves, free, rng)
    if secret >= 0:
        kinds[secret] = "ТАЙНИК"
    var treasury: int = take(leaves, free, rng)
    if treasury < 0:
        treasury = take(free.duplicate(), free, rng)
    kinds[treasury] = "СОКРОВИЩНИЦА"
    var elites: int = 1 + (1 if rng.randf() < SECOND_ELITE_CHANCE else 0)
    var events: int = 1 + (1 if rng.randf() < SECOND_EVENT_CHANCE else 0)
    # Keep at least two ordinary fights after the merchant takes its room.
    while free.size() - 1 - elites - events < 2 and events > 1:
        events -= 1
    while free.size() - 1 - elites - events < 2 and elites > 1:
        elites -= 1
    # Elites first, never next to the entrance (a deeper room always exists:
    # the boss is the farthest room, so depth-2 rooms are on its path).
    for i in range(elites):
        var elite_pool: Array[int] = []
        for id in free:
            if int(depth[id]) >= 2:
                elite_pool.append(id)
        if elite_pool.is_empty():
            break
        kinds[take(elite_pool, free, rng)] = "ЭЛИТА"
    var deep: Array[int] = []
    for id in free:
        if int(depth[id]) >= 2:
            deep.append(id)
    var shop: int = take(deep if not deep.is_empty() else free.duplicate(), free, rng)
    kinds[shop] = "МАГАЗИН"
    for i in range(events):
        var event: int = take(free.duplicate(), free, rng)
        if event >= 0:
            kinds[event] = "СОБЫТИЕ"
    return kinds

## Pick a random id from `pool` that is still in `free`; removes it from both.
static func take(pool: Array, free: Array[int], rng: RandomNumberGenerator) -> int:
    var options: Array[int] = []
    for id in pool:
        if free.has(int(id)):
            options.append(int(id))
    if options.is_empty():
        return -1
    var picked: int = options[rng.randi_range(0, options.size() - 1)]
    free.erase(picked)
    pool.erase(picked)
    return picked

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
