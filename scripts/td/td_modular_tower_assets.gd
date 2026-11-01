extends RefCounted
## Shared manifest contract for modular top-down tower art.
## Runtime art stays disabled until every required Pixel Art asset is committed and approved.

const SCHEMA_VERSION := 1
const DIRECTION_ORDER := [
	"north",
	"north_east",
	"east",
	"south_east",
	"south",
	"south_west",
	"west",
	"north_west"
]
const SPECIALIZATION_BRANCH := {
	"siege": "reaper",
	"swarm": "legion"
}

static func manifest_path(tower_id: String) -> String:
	var clean_id := tower_id.strip_edges()
	if clean_id.is_empty() or clean_id.contains("/") or clean_id.contains("\\") or clean_id.contains(".."):
		return ""
	return "res://assets/spire/towers/%s/manifest.json" % clean_id

static func load_manifest(tower_id: String) -> Dictionary:
	var path := manifest_path(tower_id)
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

static func direction_index(origin: Vector2, target: Vector2) -> int:
	var direction := target - origin
	if direction.length_squared() <= 0.0001:
		return 0
	# Index 0 is north; indices advance clockwise in 45-degree steps.
	var clockwise_from_north := fposmod(direction.angle() + PI * 0.5, TAU)
	return posmod(int(floor(clockwise_from_north / (PI * 0.25) + 0.5)), 8)

static func direction_name(index: int) -> String:
	return str(DIRECTION_ORDER[posmod(index, DIRECTION_ORDER.size())])

static func specialization_key(specialization: String) -> String:
	if specialization.is_empty():
		return "base"
	return str(SPECIALIZATION_BRANCH.get(specialization, ""))

static func validate_manifest(manifest: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	if int(manifest.get("schema_version", 0)) != SCHEMA_VERSION:
		errors.append("Unsupported schema_version")
	if str(manifest.get("id", "")).is_empty():
		errors.append("Missing tower id")
	if str(manifest.get("display_name", "")).is_empty():
		errors.append("Missing display_name")

	var canvas: Dictionary = manifest.get("canvas", {})
	if int(canvas.get("width", 0)) <= 0 or int(canvas.get("height", 0)) <= 0:
		errors.append("Canvas dimensions must be positive")
	var pivot: Variant = canvas.get("pivot", [])
	if typeof(pivot) != TYPE_ARRAY or pivot.size() != 2:
		errors.append("Canvas pivot must contain x and y")

	var base: Dictionary = manifest.get("base", {})
	var levels: Dictionary = base.get("levels", {})
	for level in ["1", "2", "3"]:
		if not _safe_relative_path(str(levels.get(level, ""))):
			errors.append("Missing or unsafe base path for level " + level)

	var weapon: Dictionary = manifest.get("weapon", {})
	for branch in ["base", "reaper", "legion"]:
		var entry: Dictionary = weapon.get(branch, {})
		_validate_sheet(entry, "weapon/" + branch, 8, false, errors)
		if entry.get("direction_order", []) != DIRECTION_ORDER:
			errors.append("weapon/" + branch + " direction_order must be the canonical eight directions")

	var projectiles: Dictionary = manifest.get("projectiles", {})
	for branch in ["base", "reaper", "legion"]:
		var entry: Dictionary = projectiles.get(branch, {})
		_validate_sheet(entry, "projectiles/" + branch, 8, true, errors)
		if str(entry.get("forward_axis", "")) != "+X":
			errors.append("projectiles/" + branch + " must declare +X as its forward axis")

	var impacts: Dictionary = manifest.get("impacts", {})
	for branch in ["base", "reaper", "legion"]:
		var entry: Dictionary = impacts.get(branch, {})
		_validate_sheet(entry, "impacts/" + branch, 8, true, errors)

	var source: Dictionary = manifest.get("source", {})
	if not _safe_relative_path(str(source.get("editable_project", ""))):
		errors.append("Missing editable source project path")
	if not _safe_relative_path(str(source.get("provenance", ""))):
		errors.append("Missing source provenance path")

	return {"valid": errors.is_empty(), "errors": errors}

static func _validate_sheet(entry: Dictionary, label: String, expected_frames: int, require_fps: bool, errors: Array[String]) -> void:
	if not _safe_relative_path(str(entry.get("path", ""))):
		errors.append(label + " has a missing or unsafe path")
	var frame_size: Variant = entry.get("frame_size", [])
	if typeof(frame_size) != TYPE_ARRAY or frame_size.size() != 2:
		errors.append(label + " frame_size must contain width and height")
	elif int(frame_size[0]) <= 0 or int(frame_size[1]) <= 0:
		errors.append(label + " frame_size must be positive")
	if int(entry.get("frame_count", 0)) != expected_frames:
		errors.append(label + " must contain %d frames" % expected_frames)
	if require_fps and float(entry.get("fps", 0.0)) <= 0.0:
		errors.append(label + " fps must be positive")

static func _safe_relative_path(path: String) -> bool:
	return not path.is_empty() and not path.begins_with("/") and not path.contains("..") and not path.contains("\\")

static func resolve_tower_layers(manifest: Dictionary, level: int, specialization: String, origin: Vector2, target: Vector2) -> Dictionary:
	if level < 1 or level > 3 or not bool(validate_manifest(manifest).get("valid", false)):
		return {}
	var branch := specialization_key(specialization)
	if branch.is_empty():
		return {}
	var root := "res://assets/spire/towers/%s/" % str(manifest.get("id", ""))
	var base: Dictionary = manifest.get("base", {})
	var levels: Dictionary = base.get("levels", {})
	var weapon: Dictionary = manifest.get("weapon", {})
	var weapon_entry: Dictionary = weapon.get(branch, {})
	var weapon_size: Array = weapon_entry.get("frame_size", [128, 128])
	var canvas: Dictionary = manifest.get("canvas", {})
	var pivot: Array = canvas.get("pivot", [64, 90])
	var direction := direction_index(origin, target)
	return {
		"base_path": root + str(levels.get(str(level), "")),
		"weapon_path": root + str(weapon_entry.get("path", "")),
		"weapon_frame": direction,
		"weapon_direction": direction_name(direction),
		"weapon_frame_size": Vector2i(int(weapon_size[0]), int(weapon_size[1])),
		"pivot": Vector2(float(pivot[0]), float(pivot[1])),
		"branch": branch
	}

static func resolve_vfx(manifest: Dictionary, category: String, specialization: String) -> Dictionary:
	if not ["projectiles", "impacts"].has(category) or not bool(validate_manifest(manifest).get("valid", false)):
		return {}
	var branch := specialization_key(specialization)
	if branch.is_empty():
		return {}
	var root := "res://assets/spire/towers/%s/" % str(manifest.get("id", ""))
	var groups: Dictionary = manifest.get(category, {})
	var entry: Dictionary = groups.get(branch, {})
	var frame_size: Array = entry.get("frame_size", [0, 0])
	return {
		"path": root + str(entry.get("path", "")),
		"frame_size": Vector2i(int(frame_size[0]), int(frame_size[1])),
		"frame_count": int(entry.get("frame_count", 0)),
		"fps": float(entry.get("fps", 0.0)),
		"loop": bool(entry.get("loop", false)),
		"forward_axis": str(entry.get("forward_axis", ""))
	}

static func runtime_ready(manifest: Dictionary) -> bool:
	if not bool(validate_manifest(manifest).get("valid", false)) or not bool(manifest.get("runtime_enabled", false)):
		return false
	# Do not ship a static concept/sprite sheet with a painted backdrop in place
	# of individually authored production sprites. Validate all atlas geometry
	# and alpha corners before enabling the renderer.
	var root := "res://assets/spire/towers/%s/" % str(manifest.get("id", ""))
	var canvas: Dictionary = manifest.get("canvas", {})
	var expected_base := Vector2i(int(canvas.get("width", 0)), int(canvas.get("height", 0)))
	var base: Dictionary = manifest.get("base", {})
	var levels: Dictionary = base.get("levels", {})
	for level in ["1", "2", "3"]:
		if not _transparent_png_ready(root + str(levels[level]), expected_base, 1):
			return false
	for group_name in ["weapon", "projectiles", "impacts"]:
		var group: Dictionary = manifest.get(group_name, {})
		for branch in ["base", "reaper", "legion"]:
			var entry: Dictionary = group.get(branch, {})
			var dimensions: Array = entry.get("frame_size", [])
			if dimensions.size() != 2:
				return false
			var cell := Vector2i(int(dimensions[0]), int(dimensions[1]))
			if not _transparent_png_ready(root + str(entry.get("path", "")), cell, int(entry.get("frame_count", 0))):
				return false
	return true

static func _transparent_png_ready(path: String, cell_size: Vector2i, frames: int) -> bool:
	if cell_size.x <= 0 or cell_size.y <= 0 or frames <= 0:
		return false
	if not path.ends_with(".png") or not ResourceLoader.exists(path):
		return false
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		return false
	# Contract v1 uses a single horizontal strip, never the entire concept
	# board or a sheet with captions and arbitrary gutters.
	if texture.get_size() != Vector2(cell_size.x * frames, cell_size.y):
		return false
	var img := texture.get_image()
	return _alpha_frame_valid(img, cell_size, frames)

static func _alpha_frame_valid(img: Image, cell_size: Vector2i, frames: int) -> bool:
	if img == null or img.is_empty() or frames < 1 or cell_size.x < 1 or cell_size.y < 1:
		return false
	if img.get_size() != Vector2i(cell_size.x * frames, cell_size.y):
		return false
	if not img.detect_alpha() or img.get_used_rect().size == Vector2i.ZERO:
		return false
	# Every frame must have clean transparent corners, painted central art
	# and no completely opaque background. Corner tests alone cannot catch
	# all halos, so final owner QA remains mandatory.
	for index in range(frames):
		var origin := Vector2i(index * cell_size.x, 0)
		var corners := [
			origin, origin + Vector2i(cell_size.x - 1, 0),
			origin + Vector2i(0, cell_size.y - 1),
			origin + cell_size - Vector2i.ONE
		]
		for corner in corners:
			if img.get_pixelv(corner).a > 0.015:
				return false
		var opaque_count := 0
		for y in range(cell_size.y):
			for x in range(cell_size.x):
				if img.get_pixelv(origin + Vector2i(x, y)).a > 0.5:
					opaque_count += 1
		if opaque_count < 8 or opaque_count >= cell_size.x * cell_size.y * 9 / 10:
			return false
	return true
