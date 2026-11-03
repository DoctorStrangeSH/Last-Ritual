extends SceneTree

var failures := 0

func check(value: bool, description: String) -> void:
    if not value:
        failures += 1
        push_error("FAIL " + description)
    else:
        print("PASS " + description)

func upgrade_to_specialization(game, path: String) -> bool:
    for step in range(3):
        if not game.upgrade_selected():
            return false
    return game.specialization_open and int(game.slots[game.selected_slot]["level"]) == 3 and game.choose_specialization(path)

func _initialize() -> void:
    call_deferred("run_tests")

func run_tests() -> void:
    var scene: PackedScene = load("res://scenes/topdown_td_prototype.tscn")
    check(scene != null, "TD scene loads for multi-day persistence test")
    if scene == null:
        quit(1)
        return

    const RUN_SEED := 314159
    var first_day = scene.instantiate()
    root.add_child(first_day)
    first_day.set_fortress_map_seed(RUN_SEED)
    first_day.coins = 5000
    first_day.altar_hp = 63

    var tower_types: Array[String] = ["bone", "fire", "necro", "frost"]
    var specializations: Array[String] = ["siege", "swarm", "siege", "swarm"]
    var priorities: Array[String] = ["nearest", "support", "front", "nearest"]
    for slot_index in range(tower_types.size()):
        check(first_day.choose_tower(tower_types[slot_index]), "Select %s tower" % tower_types[slot_index])
        check(first_day.build_tower(slot_index), "Build %s tower on generated site" % tower_types[slot_index])
        check(first_day.select_slot(slot_index), "Select %s tower for specialization" % tower_types[slot_index])
        check(upgrade_to_specialization(first_day, specializations[slot_index]), "Specialize %s tower as %s" % [tower_types[slot_index], specializations[slot_index]])
        first_day.slots[slot_index]["target_priority"] = priorities[slot_index]

    var expected_positions: Array[Vector2] = []
    for slot in first_day.slots:
        expected_positions.append(slot["pos"])
    var snapshot: Dictionary = first_day.export_fortress_state()
    check(int(snapshot.get("map_seed", -1)) == RUN_SEED, "Fortress snapshot records the run seed")

    var day_scenes: Array = [first_day]
    for day_number in range(2, 6):
        var next_day = scene.instantiate()
        root.add_child(next_day)
        next_day.set_fortress_map_seed(RUN_SEED)
        check(next_day.import_fortress_state(snapshot), "Day %d imports previous fortress snapshot" % day_number)
        check(next_day.slots.size() == 8, "Day %d restores all stable build-site IDs" % day_number)
        for slot_index in range(tower_types.size()):
            var restored: Dictionary = next_day.slots[slot_index]
            check(restored["pos"] == expected_positions[slot_index], "Day %d keeps site %d position" % [day_number, slot_index])
            check(restored["tower"] == tower_types[slot_index], "Day %d keeps tower %s" % [day_number, tower_types[slot_index]])
            check(int(restored["level"]) == 3 and restored["specialization"] == specializations[slot_index], "Day %d keeps tower specialization" % day_number)
            check(restored["target_priority"] == priorities[slot_index], "Day %d keeps target priority" % day_number)
        check(next_day.coins == int(snapshot["coins"]) and next_day.altar_hp == int(snapshot["altar_hp"]), "Day %d keeps treasury and altar health" % day_number)
        snapshot = next_day.export_fortress_state()
        day_scenes.append(next_day)

    var wrong_seed_day = scene.instantiate()
    root.add_child(wrong_seed_day)
    wrong_seed_day.set_fortress_map_seed(RUN_SEED + 1)
    wrong_seed_day.coins = 777
    check(not wrong_seed_day.import_fortress_state(snapshot), "A different run seed rejects the previous fortress snapshot")
    check(wrong_seed_day.coins == 777 and wrong_seed_day.slots[0]["tower"] == "", "Rejected snapshot leaves the new fortress untouched")

    var legacy_snapshot: Dictionary = snapshot.duplicate(true)
    legacy_snapshot.erase("map_seed")
    for building in legacy_snapshot["buildings"]:
        building.erase("target_priority")
    var legacy_day = scene.instantiate()
    root.add_child(legacy_day)
    legacy_day.set_fortress_map_seed(RUN_SEED)
    check(legacy_day.import_fortress_state(legacy_snapshot), "Legacy snapshot without map_seed or target_priority remains loadable")
    check(legacy_day.slots[0]["tower"] == "bone" and legacy_day.slots[0]["target_priority"] == "nearest", "Legacy defaults preserve tower and nearest targeting")

    for day in day_scenes:
        day.queue_free()
    wrong_seed_day.queue_free()
    legacy_day.queue_free()

    print("TD FORTRESS PERSISTENCE RESULT: ", "PASS" if failures == 0 else str(failures) + " FAILURES")
    quit(0 if failures == 0 else 1)
