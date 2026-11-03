extends RefCounted
## Deterministic per-run fortress map generator.
## Each run has two or three attack routes that split from a shared approach
## and merge into a shared final approach, plus eight stable build sites.
const MAP_VERSION := 2
const SLOT_COUNT := 8
const MIN_SLOT_PATH_CLEARANCE := 54.0
const MIN_SLOT_SPACING := 70.0
const BRANCH_INDEX := 2
const MERGE_INDEX := 8
const SHARED_PREFIX_POINTS := 2

static func generate_map(seed_value: int) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value

    var lane_count := 2 if posmod(seed_value, 2) == 0 else 3
    var lane_bases: Array = [250.0, 340.0]
    if lane_count == 3:
        lane_bases = [235.0, 295.0, 355.0]

    var bend_patterns: Array = [
        [0.0, 18.0, -8.0, -18.0, 9.0, 20.0, -12.0, -17.0, 10.0, 0.0],
        [0.0, -16.0, 12.0, 19.0, -10.0, -18.0, 14.0, 16.0, -12.0, 0.0],
        [0.0, 20.0, 12.0, -14.0, -20.0, -6.0, 18.0, 12.0, -16.0, 0.0]
    ]
    var bend_pattern: Array = bend_patterns[rng.randi_range(0, bend_patterns.size() - 1)]
    var bend_scale := rng.randf_range(0.88, 1.0)
    var x_positions: Array[float] = [65.0, 165.0, 270.0, 375.0, 480.0, 590.0, 700.0, 815.0, 930.0, 1070.0]
    for point_index in range(2, x_positions.size() - 2):
        x_positions[point_index] += rng.randf_range(-12.0, 12.0)

    # A shared entry trunk feeds independent route branches. They converge
    # again before the altar, so the player defends both the split and merge.
    var paths: Array = []
    for lane_index in range(lane_count):
        var path: Array[Vector2] = []
        var base_y := float(lane_bases[lane_index])
        for point_index in range(x_positions.size()):
            var y := 295.0
            if point_index >= BRANCH_INDEX and point_index < MERGE_INDEX:
                y = base_y + float(bend_pattern[point_index]) * bend_scale
            path.append(Vector2(x_positions[point_index], y))
        paths.append(path)

    var slot_x: Array[float] = [250.0, 425.0, 600.0, 775.0]
    var slots: Array[Vector2] = []
    for row in range(2):
        for column in range(4):
            var x := slot_x[column] + rng.randf_range(-24.0, 24.0)
            var y := 150.0 + rng.randf_range(-8.0, 8.0) if row == 0 else 438.0 + rng.randf_range(-4.0, 4.0)
            slots.append(Vector2(x, y))

    return {
        "version": MAP_VERSION,
        "seed": seed_value,
        "paths": paths,
        "slots": slots,
        "topology": {
            "route_count": lane_count,
            "branch_index": BRANCH_INDEX,
            "merge_index": MERGE_INDEX,
            "shared_prefix_points": SHARED_PREFIX_POINTS
        }
    }


static func point_segment_distance(point: Vector2, start: Vector2, finish: Vector2) -> float:
    var segment := finish - start
    if segment.length_squared() <= 0.0001:
        return point.distance_to(start)
    var ratio := clampf((point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
    return point.distance_to(start + segment * ratio)


static func validate_map(map_data: Dictionary) -> bool:
    var paths: Array = map_data.get("paths", [])
    var slots: Array = map_data.get("slots", [])
    var topology: Dictionary = map_data.get("topology", {})
    if paths.size() < 2 or paths.size() > 3 or slots.size() != SLOT_COUNT:
        return false
    if int(topology.get("route_count", -1)) != paths.size():
        return false
    if int(topology.get("branch_index", -1)) != BRANCH_INDEX or int(topology.get("merge_index", -1)) != MERGE_INDEX:
        return false

    var reference_path: Array = paths[0]
    if reference_path.size() != 10:
        return false
    for lane_index in range(paths.size()):
        var path: Array = paths[lane_index]
        if path.size() != reference_path.size():
            return false
        for point_index in range(path.size()):
            var point: Vector2 = path[point_index]
            if point.x < 50.0 or point.x > 1100.0 or point.y < 200.0 or point.y > 400.0:
                return false
            if point_index > 0:
                var previous_point: Vector2 = path[point_index - 1]
                if point.x <= previous_point.x:
                    return false
            if point_index < BRANCH_INDEX or point_index >= MERGE_INDEX:
                if point.distance_to(reference_path[point_index]) > 0.01:
                    return false
            elif lane_index > 0:
                var previous_lane_point: Vector2 = paths[lane_index - 1][point_index]
                if point.distance_to(previous_lane_point) < 38.0:
                    return false

    for lane_index in range(paths.size()):
        for other_lane in range(lane_index + 1, paths.size()):
            var first_path: Array = paths[lane_index]
            var second_path: Array = paths[other_lane]
            for point_index in range(BRANCH_INDEX, MERGE_INDEX):
                if Vector2(first_path[point_index]).distance_to(Vector2(second_path[point_index])) < 38.0:
                    return false

    for slot_index in range(slots.size()):
        var site: Vector2 = slots[slot_index]
        if site.x < 100.0 or site.x > 900.0 or site.y < 110.0 or site.y > 480.0:
            return false
        for other_index in range(slot_index):
            var other_site: Vector2 = slots[other_index]
            if site.distance_to(other_site) < MIN_SLOT_SPACING:
                return false
        for path in paths:
            for segment_index in range(path.size() - 1):
                var distance := point_segment_distance(site, path[segment_index], path[segment_index + 1])
                if distance < MIN_SLOT_PATH_CLEARANCE:
                    return false
    return true
