extends SceneTree
## Regression: later siege days scale enemy health (SIEGE_DAY_HP_GROWTH).
## Day 1 must stay exactly as before; every role must get tougher day by day.

const TD_SCENE = preload("res://scenes/topdown_td_prototype.tscn")
var failures := 0

func check(value: bool, description: String) -> void:
    if not value:
        failures += 1
        push_error("FAIL " + description)
    else:
        print("PASS " + description)

func _initialize() -> void:
    call_deferred("run")

## HP of every role spawned in `wave` of `day` (role -> max HP seen).
func wave_hp(day: int, wave: int, difficulty: int) -> Dictionary:
    var game = TD_SCENE.instantiate()
    root.add_child(game)
    game.set_process(false)
    game.difficulty = difficulty
    game.siege_day = day
    game.set_fortress_map_seed(3)
    game.wave_number = wave - 1
    game.interwave_choice = "skipped"
    var result := {}
    if game.start_wave():
        for enemy in game.enemies:
            var role := str(enemy.get("role", ""))
            result[role] = maxi(int(result.get(role, 0)), int(enemy["max_hp"]))
    game.get_parent().remove_child(game)
    game.free()
    return result

func run() -> void:
    var game = TD_SCENE.instantiate()
    root.add_child(game)
    check(game.SIEGE_DAY_HP_GROWTH > 0.0, "Day HP growth is positive")
    game.siege_day = 1
    check(game.siege_day_hp(10) == 10, "Day 1 health is unchanged")
    game.siege_day = 5
    check(game.siege_day_hp(10) == roundi(10.0 * (1.0 + 4.0 * game.SIEGE_DAY_HP_GROWTH)), "Day 5 applies four growth steps")
    check(game.siege_day_hp(0) == 1, "Scaled health never drops below 1")
    game.get_parent().remove_child(game)
    game.free()

    # Day 1, wave 6 on Normal keeps the original formulas (boss 55, captain absent).
    var day_one: Dictionary = wave_hp(1, 6, 0)
    check(int(day_one.get("boss", 0)) == 55, "Day 1 boss keeps 55 HP on Normal")
    # Day 1 wave 6 is brutes and runners only (siege_enemy_role).
    check(int(day_one.get("runner", 0)) == 8, "Day 1 wave 6 runner keeps 2 + wave HP")
    check(int(day_one.get("brute", 0)) == 13, "Day 1 wave 6 brute keeps 7 + wave HP")

    for wave in [2, 5, 6]:
        var previous := {}
        for day in range(1, 6):
            var hp: Dictionary = wave_hp(day, wave, 1)
            for role in hp.keys():
                if previous.has(role):
                    check(int(hp[role]) > int(previous[role]), "Wave %d %s is tougher on day %d than day %d" % [wave, role, day, day - 1])
            previous = hp
    var late: Dictionary = wave_hp(5, 6, 0)
    check(int(late.get("boss", 0)) > int(day_one.get("boss", 0)) * 2, "Day 5 boss has more than double day-1 health")
    print("TD DAY SCALING RESULT: ", "PASS" if failures == 0 else "FAIL")
    quit(1 if failures > 0 else 0)
