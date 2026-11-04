extends SceneTree
## Branch identity: Frost "Shatter" (bonus vs chilled, doubled for Frostbite)
## and Reaper "Harvest" (heavy single-soul bonus). Values: docs/BALANCE.md.

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

## Damage one tower deals to a lone grunt in one attack.
func one_hit(kind: String, specialization: String, chilled: bool) -> int:
    var game = TD_SCENE.instantiate()
    root.add_child(game)
    game.set_process(false)
    game.set_fortress_map_seed(3)
    game.slots[0]["tower"] = kind
    game.slots[0]["level"] = 3
    game.slots[0]["specialization"] = specialization
    var enemy := {"pos": Vector2(game.slots[0]["pos"]) + Vector2(40, 0), "hp": 500, "max_hp": 500, "role": "grunt", "delay": 0.0, "lane": 0, "waypoint": 1, "speed": 0.0}
    if chilled:
        enemy["frost_time"] = 1.5
        enemy["frost_strength"] = 0.25
    game.enemies.append(enemy)
    game.attack_with_towers(0.01)
    var dealt: int = 500 - int(enemy["hp"])
    game.get_parent().remove_child(game)
    game.free()
    return dealt

func run() -> void:
    var game = TD_SCENE.instantiate()
    check(game.FROST_SHATTER_PER_LEVEL > 0 and game.REAPER_BONUS > 0, "Shatter and Harvest are active")
    var shatter: int = game.FROST_SHATTER_PER_LEVEL
    var harvest: int = game.REAPER_BONUS
    game.free()
    check(one_hit("frost", "", true) == one_hit("frost", "", false) + shatter * 3, "Frost shatters chilled enemies (+per level)")
    check(one_hit("frost", "swarm", true) == one_hit("frost", "swarm", false) + shatter * 3, "Blizzard shatters like the base frost")
    check(one_hit("frost", "siege", true) == one_hit("frost", "siege", false) + shatter * 2 * 3, "Frostbite shatters twice as hard")
    check(one_hit("bone", "", true) == one_hit("bone", "", false), "Shatter belongs to frost towers only")
    check(one_hit("necro", "siege", false) == one_hit("necro", "", false) + 2 + harvest, "Reaper adds the Harvest bonus to its single soul")
    check(one_hit("necro", "swarm", false) < one_hit("necro", "siege", false), "A Legion soul hits lighter than the Reaper's")
    print("TD BRANCH IDENTITY RESULT: ", "PASS" if failures == 0 else "FAIL")
    quit(1 if failures > 0 else 0)
