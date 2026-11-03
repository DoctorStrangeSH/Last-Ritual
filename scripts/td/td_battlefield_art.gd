extends RefCounted
## Pixel-art battlefield for the day siege: ground, cobbled roads, build pads,
## Ritual Altar, gate, wall and seeded decorative props.
##
## Gated by assets/battlefield/manifest.json (runtime_enabled). While disabled the
## controller keeps its procedural drawing. Pure helpers here are unit-tested.

const MANIFEST_PATH := "res://assets/battlefield/manifest.json"
const FIELD := Rect2(28, 66, 1096, 464)
const PROP_COUNT := 8
const PROP_SIZE := 32

static func load_manifest(path: String = MANIFEST_PATH) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    return parsed if parsed is Dictionary else {}

## Every referenced texture must exist; the flag alone is not enough.
static func runtime_ready(manifest: Dictionary) -> bool:
    if not bool(manifest.get("runtime_enabled", false)):
        return false
    return missing_textures(manifest).is_empty()

static func missing_textures(manifest: Dictionary) -> Array[String]:
    var missing: Array[String] = []
    var root: String = str(manifest.get("root", ""))
    for key in ["ground", "road", "pad_empty", "pad_built", "altar", "props", "gate", "wall"]:
        var file: String = str((manifest.get("textures", {}) as Dictionary).get(key, ""))
        if file.is_empty() or not ResourceLoader.exists(root + file):
            missing.append(key)
    return missing

static func texture_path(manifest: Dictionary, key: String) -> String:
    return str(manifest.get("root", "")) + str((manifest.get("textures", {}) as Dictionary).get(key, ""))

## Quad polygons covering a polyline of the given width; UVs are world pixels,
## so a repeating texture tiles seamlessly across bends and segments.
static func road_quads(path: Array, width: float) -> Array:
    var quads: Array = []
    var half := width * 0.5
    for index in range(path.size() - 1):
        var a: Vector2 = path[index]
        var b: Vector2 = path[index + 1]
        if a.distance_to(b) < 0.5:
            continue
        var normal: Vector2 = (b - a).normalized().orthogonal() * half
        var points := PackedVector2Array([a + normal, b + normal, b - normal, a - normal])
        quads.append(points)
    return quads

## Round joints fill the gaps between quads at every bend.
static func joint_polygon(center: Vector2, radius: float, sides: int = 14) -> PackedVector2Array:
    var points := PackedVector2Array()
    for i in range(sides):
        var angle := float(i) / float(sides) * TAU
        points.append(center + Vector2(cos(angle), sin(angle)) * radius)
    return points

static func uvs_for(points: PackedVector2Array, tile: float) -> PackedVector2Array:
    var uvs := PackedVector2Array()
    for point in points:
        uvs.append(point / tile)
    return uvs

static func distance_to_path(point: Vector2, path: Array) -> float:
    var best := INF
    for index in range(path.size() - 1):
        best = minf(best, point.distance_to(Geometry2D.get_closest_point_to_segment(point, path[index], path[index + 1])))
    return best

## Seeded decorative props that never touch roads, pads, the altar, gates or UI.
## Returns [{pos: Vector2, frame: int}], deterministic for a map seed.
static func prop_layout(map_seed: int, paths: Array, slot_positions: Array, altar: Vector2, count: int = 14) -> Array:
    var rng := RandomNumberGenerator.new()
    rng.seed = (map_seed & 0x7fffffff) * 7919 + 31
    var placed: Array = []
    var attempts := 0
    while placed.size() < count and attempts < 600:
        attempts += 1
        var pos := Vector2(rng.randf_range(FIELD.position.x + 30.0, FIELD.end.x - 70.0), rng.randf_range(FIELD.position.y + 22.0, FIELD.end.y - 18.0))
        if not prop_position_clear(pos, paths, slot_positions, altar, placed):
            continue
        placed.append({"pos": pos, "frame": rng.randi_range(0, PROP_COUNT - 1)})
    return placed

static func prop_position_clear(pos: Vector2, paths: Array, slot_positions: Array, altar: Vector2, placed: Array) -> bool:
    for path in paths:
        if distance_to_path(pos, path) < 36.0:
            return false
    for slot_pos in slot_positions:
        # towers rise ~100 px above their pad; keep the whole silhouette clear
        if Rect2(Vector2(slot_pos) + Vector2(-58, -112), Vector2(116, 160)).has_point(pos):
            return false
    if pos.distance_to(altar) < 80.0 or pos.x < 90.0:
        return false
    # keep the prep-phase panels (scouting/repair) clean
    if Rect2(56, 462, 680, 72).has_point(pos):
        return false
    for other in placed:
        if pos.distance_to(other["pos"]) < 44.0:
            return false
    return true
