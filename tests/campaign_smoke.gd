extends SceneTree

var failures := 0

func _initialize() -> void:
    call_deferred("run_tests")

func check(ok: bool, name: String) -> void:
    if not ok:
        failures += 1
        push_error("FAIL " + name)
    else:
        print("PASS " + name)

func run_tests() -> void:
    var packed := load("res://scenes/main.tscn") as PackedScene
    if packed == null:
        quit(1)
        return
    var game := packed.instantiate()
    root.add_child(game)
    game.save_path = "user://campaign_smoke_test.json"
    game.reset_all()
    check(game.current_day == 1, "initial day")
    game.phase = "ritual"
    game.stones_collected = 1
    game.mana = 110
    game.souls = 12
    game.towers.append({"x": 400.0, "type": "bone", "cooldown": 0.0})
    game.buy_upgrade("tower")
    game.buy_upgrade("ward")
    game.resolve_altar()
    check(game.current_day == 2 and game.phase == "day", "advance to day 2")
    check(game.towers.size() == 1 and game.tower_power_level == 1, "persist towers")
    game.begin_night()
    check(game.trap_positions.size() == 3, "second night traps")
    game.phase = "ritual"
    game.stones_collected = 2
    game.resolve_altar()
    check(game.current_day == 3 and game.phase == "day", "advance to day 3")
    game.begin_night()
    check(game.boss_hp == 230.0, "third night boss")
    game.phase = "ritual"
    game.stones_collected = 3
    game.resolve_altar()
    check(game.phase == "day" and game.current_day == 4, "third stone advances to day 4")
    game.begin_night()
    check(game.boss_hp == 270.0 and game.trap_positions.size() == 4, "Blood Mines layout and boss")
    game.phase = "ritual"
    game.stones_collected = 4
    game.resolve_altar()
    check(game.phase == "day" and game.current_day == 5, "fourth stone advances to day five")
    game.begin_night()
    check(game.boss_hp == 340.0 and game.trap_positions.size() == 4, "fifth night boss and traps")
    game.phase = "ritual"
    game.stones_collected = 5
    game.mana = 49
    game.souls = 8
    game.resolve_altar()
    check(game.phase == "ritual", "ritual requires mana")
    game.mana = 50
    game.resolve_altar()
    check(game.phase == "final_siege", "ritual starts final siege")
    check(game.final_timer == 45.0, "final siege timer set")
    check(game.mana == 30, "final ritual grants emergency mana")
    game.final_timer = 0.0
    game.wall_hp = 0.0
    game._process(0.0)
    check(game.phase == "lose", "fallen walls prevent victory")
    game.phase = "final_siege"
    game.final_timer = 0.0
    game.wall_hp = 100.0
    game._process(0.0)
    check(game.phase == "win", "surviving final siege wins")
    game.reset_all()
    check(game.current_day == 1 and game.towers.is_empty(), "restart resets")
    game.phase = "ritual"
    game.current_day = 2
    game.stones_collected = 2
    game.mana = 93
    game.souls = 11
    game.wall_hp = 78.0
    game.towers.append({"x": 430.0, "type": "fire", "cooldown": 0.0})
    check(game.save_campaign(), "checkpoint save")
    game.reset_all()
    check(game.load_campaign(), "checkpoint load")
    check(game.phase == "ritual" and game.current_day == 2 and game.stones_collected == 2, "checkpoint phase and progress")
    check(game.mana == 93 and game.souls == 11 and game.wall_hp == 78.0, "checkpoint resources")
    check(game.towers.size() == 1 and game.towers[0]["type"] == "fire", "checkpoint tower")
    var corrupt := FileAccess.open("user://campaign_smoke_test.json", FileAccess.WRITE)
    corrupt.store_string("{not valid json")
    corrupt.close()
    check(not game.load_campaign(), "corrupt save is rejected")
    var invalid := {"version": 1, "day": 2, "stones": 2, "mana": 90, "souls": 10, "wall_hp": 90, "tower_power": 0, "wall_ward": 0, "towers": [{"x": 400.0, "type": "bone"}, {"x": 420.0, "type": "bone"}]}
    var bad_file := FileAccess.open("user://campaign_smoke_test.json", FileAccess.WRITE)
    bad_file.store_string(JSON.stringify(invalid))
    bad_file.close()
    check(not game.load_campaign(), "overlapping saved towers rejected")
    invalid["towers"] = []
    invalid["stones"] = 1.5
    bad_file = FileAccess.open("user://campaign_smoke_test.json", FileAccess.WRITE)
    bad_file.store_string(JSON.stringify(invalid))
    bad_file.close()
    check(not game.load_campaign(), "fractional stone count rejected")
    invalid["stones"] = 2
    invalid["towers"] = []
    var too_large := JSON.stringify(invalid) + " ".repeat(70000)
    bad_file = FileAccess.open("user://campaign_smoke_test.json", FileAccess.WRITE)
    bad_file.store_string(too_large)
    bad_file.close()
    check(not game.load_campaign(), "oversized save rejected")
    check(game.current_day == 2 and game.mana == 93, "rejected save preserves existing state")
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://campaign_smoke_test.json"))
    game.queue_free()
    print("Failures: ", failures)
    quit(1 if failures > 0 else 0)
