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
		check(contract.runtime_ready(manifest), "Owner-approved modular Pixel Art kit enables runtime")
		var missing: Array[String] = contract.missing_runtime_art(manifest)
		check(missing.is_empty(), "All six production base and weapon PNGs plus existing VFX pass readiness")
		check(not missing.has("res://assets/spire/towers/necro/base/level_1.png"), "Production base L1 is present")
		check(not missing.has("res://assets/spire/towers/necro/weapon/reaper/weapon_8way.png"), "Production Reaper eight-way weapon is present")
		check(not missing.has("res://assets/spire/towers/necro/weapon/legion/weapon_8way.png"), "Production Legion eight-way weapon is present")
		check(not missing.has("res://assets/spire/towers/necro/approved_renders/vfx/legion_impact_8f.png"), "Committed Legion impact strip is no longer considered missing")
		check(contract.missing_runtime_art({}) == ["manifest:invalid"], "Invalid modular manifest yields explicit actionable error")

		var tower_visuals = load("res://scripts/td/td_tower_visuals.gd")
		check(tower_visuals.approved_necro_sprite_path(1, "") == "res://assets/spire/towers/necro/approved_renders/sprites/level_1.png", "Approved level 1 render is selected")
		check(tower_visuals.approved_necro_sprite_path(2, "") == "res://assets/spire/towers/necro/approved_renders/sprites/level_2.png", "Approved level 2 render is selected")
		check(tower_visuals.approved_necro_sprite_path(3, "") == "res://assets/spire/towers/necro/approved_renders/sprites/level_3.png", "Approved level 3 render is selected")
		check(tower_visuals.approved_necro_sprite_path(3, "siege").ends_with("/reaper.png"), "Approved Reaper render is selected for siege specialization")
		check(tower_visuals.approved_necro_sprite_path(3, "swarm") == "", "Missing approved Legion render never gets substituted")
		for approved_level in range(1, 4):
			var approved_path: String = tower_visuals.approved_necro_sprite_path(approved_level, "")
			check(tower_visuals.approved_necro_sprite_ready(approved_path), "Approved level %d PNG is RGBA 192x192 with clean transparent corners" % approved_level)
		check(tower_visuals.approved_necro_sprite_ready(tower_visuals.approved_necro_sprite_path(3, "siege")), "Approved Reaper PNG passes runtime image checks")
		var display_size: Vector2i = tower_visuals.approved_necro_display_size(Vector2i(192, 192), 120)
		check(display_size == Vector2i(120, 120), "Approved square tower art uses a crisp 120px display size")
		var wide_size: Vector2i = tower_visuals.approved_necro_display_size(Vector2i(192, 128), 120)
		check(wide_size == Vector2i(180, 120), "Approved tower display preserves non-square source aspect ratio")
		var display_rect: Rect2 = tower_visuals.approved_necro_display_rect(Vector2(280, 190), Vector2i(192, 192), 120)
		check(display_rect.position == Vector2(220, 70) and display_rect.size == Vector2(120, 120), "Approved tower art is centred and its feet stay on the pad anchor")
		check(tower_visuals.approved_necro_display_rect(Vector2.ZERO, Vector2i.ZERO).size == Vector2.ZERO, "Invalid art dimensions are rejected before drawing")

		for spec in ["siege", "swarm"]:
			for layer in ["projectiles", "weapon_impact"]:
				var authored: Dictionary = tower_visuals.necro_specialization_vfx(spec, layer)
				check(not authored.is_empty(), "Pixel Art VFX atlas exists for %s / %s" % [spec, layer])
				if not authored.is_empty():
					var tex: Texture2D = load(authored["path"])
					check(tex != null and tex.get_size() == Vector2(authored["cell"].x * 8, authored["cell"].y), "Pixel Art atlas has eight exact frames")
					check(tower_visuals.frame_region(tex, authored["cell"], 7).size == Vector2(authored["cell"]), "All eight frames are addressable")
		check(tower_visuals.necro_specialization_vfx("", "projectiles").is_empty(), "Base Soul Altar keeps existing VFX")
		check(tower_visuals.necro_specialization_vfx("invalid", "projectiles").is_empty(), "Unknown VFX specialization is rejected")

		var frost_manifest: Dictionary = contract.load_manifest("frost")
		check(not frost_manifest.is_empty(), "Frost Obelisk candidate manifest loads")
		var frost_validation: Dictionary = contract.validate_manifest(frost_manifest)
		check(bool(frost_validation.get("valid", false)), "Frost manifest supports tower-specific specialization branch names")
		check(not contract.runtime_ready(frost_manifest), "Unapproved Frost candidate remains disabled in live runtime")
		check(contract.missing_runtime_art(frost_manifest).is_empty(), "All Frost candidate layers and VFX satisfy the modular asset contract")
		var frost_base: Dictionary = contract.resolve_tower_layers(frost_manifest, 2, "", Vector2.ZERO, Vector2.RIGHT)
		check(frost_base.get("branch", "") == "base" and frost_base.get("weapon_frame", -1) == 2, "Frost base weapon resolves the east-facing pose")
		check(frost_base.get("base_path", "").ends_with("/candidate/base/level_2.png"), "Frost L2 base resolves from review-only candidate path")
		var frost_siege: Dictionary = contract.resolve_tower_layers(frost_manifest, 3, "siege", Vector2.ZERO, Vector2.UP)
		check(frost_siege.get("branch", "") == "frost_lance", "Frost siege specialization maps to the heavy Frost Lance branch")
		check(frost_siege.get("weapon_path", "").ends_with("/candidate/weapon/frost_lance/weapon_8way.png"), "Frost Lance eight-way atlas resolves without renaming gameplay IDs")
		var frost_swarm: Dictionary = contract.resolve_tower_layers(frost_manifest, 3, "swarm", Vector2.ZERO, Vector2.LEFT)
		check(frost_swarm.get("branch", "") == "blizzard", "Frost swarm specialization maps to the Blizzard branch")
		check(frost_swarm.get("weapon_direction", "") == "west", "Frost Blizzard weapon resolves the west-facing pose")
		var frost_vfx: Dictionary = contract.resolve_vfx(frost_manifest, "projectiles", "swarm")
		check(frost_vfx.get("path", "").ends_with("/candidate/vfx/blizzard_projectile_8f.png"), "Frost specialization VFX uses its manifest-specific branch")

		var td_scene = load("res://scenes/topdown_td_prototype.tscn")
		if td_scene != null:
			var td = td_scene.instantiate()
			root.add_child(td)
			check(td.modular_necro_enabled, "Approved modular kit is enabled in the TD renderer")
			check(td.modular_necro_manifest.get("id", "") == "necro", "TD scene loads the modular manifest")
			var approved_path: String = tower_visuals.approved_necro_sprite_path(1, "")
			var crisp_texture: Texture2D = td.cached_approved_necro_texture(approved_path)
			check(crisp_texture != null and crisp_texture.get_size() == Vector2(120, 120), "TD renderer creates a cached nearest-neighbour 120px approved sprite")
			td.queue_free()


		var base_layers: Dictionary = contract.resolve_tower_layers(manifest, 1, "", Vector2.ZERO, Vector2.RIGHT)
		check(base_layers.get("base_path", "") == "res://assets/spire/towers/necro/base/level_1.png", "Base layer resolves by upgrade level")
		check(base_layers.get("weapon_frame", -1) == 2 and base_layers.get("weapon_direction", "") == "east", "Weapon layer resolves the eight-way aim frame")
		check(base_layers.get("pivot", Vector2.ZERO) == Vector2(64, 90), "All tower layers share the documented pivot")
		var base_rect: Rect2 = contract.layer_display_rect(Vector2(280, 190), Vector2i(128, 128), Vector2(64, 118), 120.0)
		var weapon_rect: Rect2 = contract.layer_display_rect(Vector2(280, 190), Vector2i(128, 128), base_layers["pivot"], 120.0)
		check(base_rect.position == Vector2(220, 79.375), "Base layer aligns its ground anchor to the build pad")
		check(weapon_rect.position == Vector2(220, 105.625), "Weapon layer aligns its authored pivot independently of the base anchor")
		check(contract.layer_display_rect(Vector2.ZERO, Vector2i.ZERO, Vector2.ZERO).size == Vector2.ZERO, "Invalid modular layer dimensions are rejected")

		var reaper_layers: Dictionary = contract.resolve_tower_layers(manifest, 3, "siege", Vector2.ZERO, Vector2.UP)
		check(reaper_layers.get("branch", "") == "reaper" and reaper_layers.get("weapon_frame", -1) == 0, "Reaper uses its own upper weapon and north pose")
		var legion_layers: Dictionary = contract.resolve_tower_layers(manifest, 3, "swarm", Vector2.ZERO, Vector2.DOWN)
		check(legion_layers.get("branch", "") == "legion" and legion_layers.get("weapon_frame", -1) == 4, "Legion uses its own upper weapon and south pose")

		var base_projectile: Dictionary = contract.resolve_vfx(manifest, "projectiles", "")
		var reaper_projectile: Dictionary = contract.resolve_vfx(manifest, "projectiles", "siege")
		var legion_impact: Dictionary = contract.resolve_vfx(manifest, "impacts", "swarm")
		check(base_projectile.get("path", "").ends_with("vfx/soul_projectile_8f.png"), "Base projectile has an independent asset family")
		check(reaper_projectile.get("path", "").ends_with("approved_renders/vfx/reaper_projectile_8f.png"), "Reaper projectile has an independent asset family")
		check(legion_impact.get("path", "").ends_with("approved_renders/vfx/legion_impact_8f.png") and not bool(legion_impact.get("loop", true)), "Legion impact is an independent one-shot animation")
		# The six separate flight/impact atlases already exist in main; do not
		# require duplicate copies under future production folders.
		for category in ["projectiles", "impacts"]:
			for branch in ["base", "reaper", "legion"]:
				var entry: Dictionary = manifest[category][branch]
				var path: String = "res://assets/spire/towers/necro/" + str(entry["path"])
				var dims: Array = entry["frame_size"]
				check(contract._transparent_png_ready(path, Vector2i(int(dims[0]), int(dims[1])), 8), "Existing VFX passes modular readiness: %s / %s" % [category, branch])
		var remaining_art: Array[String] = contract.missing_runtime_art(manifest)
		check(remaining_art.is_empty(), "No required production Soul Altar art remains missing")
		for path in remaining_art:
			check(path.contains("/base/") or path.contains("/weapon/"), "Missing list excludes existing VFX: " + path)
		check(contract.resolve_tower_layers(manifest, 4, "", Vector2.ZERO, Vector2.RIGHT).is_empty(), "Invalid tower level is rejected")
		check(contract.resolve_tower_layers(manifest, 3, "unknown", Vector2.ZERO, Vector2.RIGHT).is_empty(), "Unknown specialization is rejected")
		check(contract.resolve_vfx(manifest, "unknown", "").is_empty(), "Unknown VFX category is rejected")

		var invalid_manifest: Dictionary = manifest.duplicate(true)
		invalid_manifest["schema_version"] = 999
		check(not bool(contract.validate_manifest(invalid_manifest).get("valid", true)), "Unsupported manifest versions are rejected")

	print("Modular tower asset contract failures: %d" % failures)
	quit(1 if failures > 0 else 0)
