extends SceneTree
## Technical smoke test for the isolated modular motion preview.
var failures := 0

func check(ok: bool, description: String) -> void:
    if ok:
        print("PASS " + description)
    else:
        failures += 1
        push_error("FAIL " + description)


func _initialize() -> void:
    call_deferred("verify")


func verify() -> void:
    var packed := load("res://scenes/dev/soul_altar_modular_motion_preview.tscn") as PackedScene
    check(packed != null, "Isolated motion preview scene exists")
    if packed == null:
        quit(1)
        return

    var preview: Variant = packed.instantiate()
    root.add_child(preview)
    await process_frame

    check(preview.get("_base_texture") != null, "Candidate base texture loads")
    check(preview.get("_weapon_texture") != null, "Candidate eight-way weapon atlas loads")
    var manifest_value: Variant = preview.get("_manifest")
    check(typeof(manifest_value) == TYPE_DICTIONARY, "Candidate manifest loads as a dictionary")
    if typeof(manifest_value) != TYPE_DICTIONARY:
        preview.queue_free()
        quit(1)
        return
    var manifest: Dictionary = manifest_value
    check(not bool(manifest.get("runtime_enabled", true)), "Preview refuses to enable candidate runtime art")

    var origin: Vector2 = preview.get_tower_origin()
    var directions := [
        Vector2.UP, Vector2(1, -1), Vector2.RIGHT, Vector2(1, 1),
        Vector2.DOWN, Vector2(-1, 1), Vector2.LEFT, Vector2(-1, -1)
    ]
    for index in range(8):
        var target: Vector2 = origin + directions[index] * 100.0
        check(int(preview.preview_direction_for_target(target)) == index, "Moving target maps to direction frame %d" % index)

    var base_rect: Rect2 = preview.get_base_draw_rect()
    var weapon_rect: Rect2 = preview.get_weapon_draw_rect()
    check(base_rect.size == Vector2(320, 320), "Base draws at nearest-neighbour 2.5x scale")
    check(weapon_rect.size == Vector2(320, 320), "Weapon draws at the same 2.5x scale")
    var pivot_offset := weapon_rect.position - base_rect.position
    check(is_equal_approx(pivot_offset.x, 0.0) and is_equal_approx(pivot_offset.y, 70.0), "Weapon pivot aligns to ground anchor (28px source offset)")

    for level in range(1, 4):
        for branch in ["base", "reaper", "legion"]:
            check(bool(preview.select_review_asset(level, branch)), "Select level %d / %s review asset" % [level, branch])
            check(preview.get("_base_texture") != null, "Level %d base loads for %s" % [level, branch])
            check(preview.get("_weapon_texture") != null, "Eight-way %s weapon loads at level %d" % [branch, level])
    check(not bool(preview.select_review_asset(4, "base")), "Invalid review level is rejected")
    check(not bool(preview.select_review_asset(2, "unknown")), "Unknown review weapon is rejected")

    for index in range(8):
        preview.set_manual_direction(index)
        check(int(preview.get_current_direction_index()) == index, "Manual inspection selects exact direction %d" % index)
    preview.resume_auto_target()
    check(int(preview.get("_manual_direction")) == -1, "Automatic moving-target mode can be restored")

    check(not bool(preview.load_preview_assets("res://assets/spire/towers/necro/candidate/missing_manifest.json")), "Missing manifest fails safely")
    check(preview.get("_base_texture") == null and preview.get("_weapon_texture") == null, "Missing assets leave preview empty instead of using production fallback")
    check(not str(preview.get("_error_message")).is_empty(), "Missing assets produce an explicit preview warning")

    preview.queue_free()
    print("Soul Altar motion preview failures: %d" % failures)
    quit(1 if failures > 0 else 0)
