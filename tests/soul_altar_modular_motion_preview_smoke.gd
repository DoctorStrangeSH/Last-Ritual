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

    var preview := packed.instantiate()
    root.add_child(preview)
    await process_frame

    check(preview.get("_base_texture") != null, "Candidate base texture loads")
    check(preview.get("_weapon_texture") != null, "Candidate eight-way weapon atlas loads")
    var manifest: Dictionary = preview.get("_manifest")
    check(not bool(manifest.get("runtime_enabled", true)), "Preview refuses to enable candidate runtime art")

    var origin: Vector2 = preview.get("TOWER_ORIGIN")
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

    check(not bool(preview.load_preview_assets("res://assets/spire/towers/necro/candidate/missing_manifest.json")), "Missing manifest fails safely")
    check(preview.get("_base_texture") == null and preview.get("_weapon_texture") == null, "Missing assets leave preview empty instead of using production fallback")
    check(not str(preview.get("_error_message")).is_empty(), "Missing assets produce an explicit preview warning")

    preview.queue_free()
    print("Soul Altar motion preview failures: %d" % failures)
    quit(1 if failures > 0 else 0)
