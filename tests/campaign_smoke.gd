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
    game.mana = 49
    game.souls = 8
    game.resolve_altar()
    check(game.phase == "ritual", "ritual requires mana")
    game.mana = 50
    game.resolve_altar()
    check(game.phase == "win", "final ritual")
    game.reset_all()
    check(game.current_day == 1 and game.towers.is_empty(), "restart resets")
    game.queue_free()
    print("Failures: ", failures)
    quit(1 if failures > 0 else 0)
