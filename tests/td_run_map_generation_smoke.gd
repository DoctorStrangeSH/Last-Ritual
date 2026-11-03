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
    var generator = load("res://scripts/td/td_run_map_generator.gd")
    check(generator != null, "Run map generator loads")
    if generator == null:
        quit(1)
        return

    var first: Dictionary = generator.generate_map(42)
    var repeated: Dictionary = generator.generate_map(42)
    check(first == repeated, "Same run seed reproduces paths and build sites exactly")
    check(generator.validate_map(first), "Generated map passes geometric validation")
    check(first["slots"].size() == 8, "Every run has eight build sites")
    check(first["paths"].size() in [2, 3], "Run map has two or three assault lanes")
    for lane_index in range(1, first["paths"].size()):
        var lane: Array = first["paths"][lane_index]
        var reference_lane: Array = first["paths"][0]
        for shared_index in [0, 1, 8, 9]:
            check(lane[shared_index] == reference_lane[shared_index], "Assault routes share entrance and exit geometry")
        for branch_index in range(2, 8):
            var branch_point: Vector2 = lane[branch_index]
            var reference_point: Vector2 = reference_lane[branch_index]
            check(absf(branch_point.y - reference_point.y) >= 38.0, "Forked corridors remain separated")

    var unique_signatures: Dictionary = {}
    for seed_value in range(256):
        var generated: Dictionary = generator.generate_map(seed_value)
        check(generator.validate_map(generated), "Seed %d map passes geometry checks" % seed_value)
        for row in range(2):
            for column in range(3):
                var left_site: Vector2 = generated["slots"][row * 4 + column]
                var right_site: Vector2 = generated["slots"][row * 4 + column + 1]
                check(left_site.distance_to(right_site) <= 190.0, "Seed %d preserves tower synergy adjacency" % seed_value)
        unique_signatures[str(generated)] = true
    check(unique_signatures.size() >= 250, "Different run seeds produce meaningfully different maps")

    var changed: Dictionary = generator.generate_map(43)
    check(first["paths"] != changed["paths"], "Adjacent run seeds can produce different route geometry")
    check(first["slots"] != changed["slots"], "Adjacent run seeds change build-site positions")

    var td_scene: PackedScene = load("res://scenes/topdown_td_prototype.tscn")
    if td_scene != null:
        var run_seed := 91273
        var first_day = td_scene.instantiate()
        root.add_child(first_day)
        first_day.set_fortress_map_seed(run_seed)
        check(first_day.paths == generator.generate_map(run_seed)["paths"], "TD scene applies generated route geometry")
        var slot_positions: Array = generator.generate_map(run_seed)["slots"]
        var sites_match: bool = first_day.slots.size() == slot_positions.size()
        for index in range(mini(first_day.slots.size(), slot_positions.size())):
            if first_day.slots[index]["pos"] != slot_positions[index]:
                sites_match = false
        check(sites_match, "TD scene applies generated build-site positions")

        check(first_day.choose_tower("bone") and first_day.build_tower(0), "Build a tower on a generated stable site")
        first_day.coins = 120
        first_day.select_slot(0)
        check(first_day.upgrade_selected(), "Generated-site tower can be upgraded")
        var snapshot: Dictionary = first_day.export_fortress_state()

        var next_day = td_scene.instantiate()
        root.add_child(next_day)
        next_day.set_fortress_map_seed(run_seed)
        check(next_day.import_fortress_state(snapshot), "Fortress state imports on the same generated run map")
        check(next_day.slots[0]["pos"] == first_day.slots[0]["pos"], "Build-site identity and position remain stable between days")
        check(next_day.slots[0]["tower"] == "bone" and int(next_day.slots[0]["level"]) == 2, "Tower and upgrade persist at the same generated site")

        var other_day = td_scene.instantiate()
        root.add_child(other_day)
        other_day.set_fortress_map_seed(run_seed)
        check(other_day.slots[0]["pos"] == next_day.slots[0]["pos"], "A later day scene resolves the same run seed to the same site")
        other_day.set_fortress_map_seed(run_seed + 1)
        check(other_day.slots[0]["pos"] != next_day.slots[0]["pos"], "A new run seed relocates build sites")

        first_day.queue_free()
        next_day.queue_free()
        other_day.queue_free()

    print("TD RUN MAP SMOKE RESULT: ", "PASS" if failures == 0 else str(failures) + " FAILURES")
    quit(0 if failures == 0 else 1)
