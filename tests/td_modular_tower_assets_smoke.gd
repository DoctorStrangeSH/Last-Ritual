extends SceneTree

var failures := 0

func check(value: bool, description: String) -> void:
	if not value:
		failures += 1
		push_error("FAIL " + description)
	else:
		print("PASS " + description)

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var contract = load("res://scripts/td/td_modular_tower_assets.gd")
	check(contract != null, "Modular tower asset contract loads")
	if contract != null:
		var vectors: Array[Vector2] = [
			Vector2(0, -1),
			Vector2(1, -1),
			Vector2(1, 0),
			Vector2(1, 1),
			Vector2(0, 1),
			Vector2(-1, 1),
			Vector2(-1, 0),
			Vector2(-1, -1)
		]
		for index in range(vectors.size()):
			check(contract.direction_index(Vector2.ZERO, vectors[index]) == index, "Eight-way aim resolves " + contract.direction_name(index))
		check(contract.direction_index(Vector2.ZERO, Vector2.ZERO) == 0, "Zero-length aim has a stable north fallback")
		check(contract.manifest_path("../invalid") == "", "Manifest resolver rejects path traversal")

		var manifest: Dictionary = contract.load_manifest("necro")
		check(not manifest.is_empty(), "Soul Altar manifest loads")
		var validation: Dictionary = contract.validate_manifest(manifest)
		check(bool(validation.get("valid", false)), "Soul Altar manifest satisfies schema v1")
		check(not contract.runtime_ready(manifest), "Pixel Art runtime stays disabled until the complete approved kit exists")

		var base_layers: Dictionary = contract.resolve_tower_layers(manifest, 1, "", Vector2.ZERO, Vector2.RIGHT)
		check(base_layers.get("base_path", "") == "res://assets/spire/towers/necro/base/level_1.png", "Base layer resolves by upgrade level")
		check(base_layers.get("weapon_frame", -1) == 2 and base_layers.get("weapon_direction", "") == "east", "Weapon layer resolves the eight-way aim frame")
		check(base_layers.get("pivot", Vector2.ZERO) == Vector2(64, 90), "All tower layers share the documented pivot")

		var reaper_layers: Dictionary = contract.resolve_tower_layers(manifest, 3, "siege", Vector2.ZERO, Vector2.UP)
		check(reaper_layers.get("branch", "") == "reaper" and reaper_layers.get("weapon_frame", -1) == 0, "Reaper uses its own upper weapon and north pose")
		var legion_layers: Dictionary = contract.resolve_tower_layers(manifest, 3, "swarm", Vector2.ZERO, Vector2.DOWN)
		check(legion_layers.get("branch", "") == "legion" and legion_layers.get("weapon_frame", -1) == 4, "Legion uses its own upper weapon and south pose")

		var base_projectile: Dictionary = contract.resolve_vfx(manifest, "projectiles", "")
		var reaper_projectile: Dictionary = contract.resolve_vfx(manifest, "projectiles", "siege")
		var legion_impact: Dictionary = contract.resolve_vfx(manifest, "impacts", "swarm")
		check(base_projectile.get("path", "").ends_with("projectiles/base/projectile_8f.png"), "Base projectile has an independent asset family")
		check(reaper_projectile.get("path", "").ends_with("projectiles/reaper/projectile_8f.png"), "Reaper projectile has an independent asset family")
		check(legion_impact.get("path", "").ends_with("impacts/legion/impact_8f.png") and not bool(legion_impact.get("loop", true)), "Legion impact is an independent one-shot animation")
		check(contract.resolve_tower_layers(manifest, 4, "", Vector2.ZERO, Vector2.RIGHT).is_empty(), "Invalid tower level is rejected")
		check(contract.resolve_tower_layers(manifest, 3, "unknown", Vector2.ZERO, Vector2.RIGHT).is_empty(), "Unknown specialization is rejected")
		check(contract.resolve_vfx(manifest, "unknown", "").is_empty(), "Unknown VFX category is rejected")

		var invalid_manifest: Dictionary = manifest.duplicate(true)
		invalid_manifest["schema_version"] = 999
		check(not bool(contract.validate_manifest(invalid_manifest).get("valid", true)), "Unsupported manifest versions are rejected")

	print("Modular tower asset contract failures: %d" % failures)
	quit(1 if failures > 0 else 0)
