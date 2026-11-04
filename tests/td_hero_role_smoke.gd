extends SceneTree
## Day hero tuning: ordinary vs heavy strikes, cooldown, boss interrupt stays
## two strikes, and the damage counter used by the balance simulator.

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

func fresh():
    var game = TD_SCENE.instantiate()
    root.add_child(game)
    game.set_process(false)
    game.set_fortress_map_seed(3)
    return game

func enemy_near(game, role: String, hp: int) -> Dictionary:
    var enemy := {"pos": game.hero_pos + Vector2(60, 0), "hp": hp, "max_hp": hp, "role": role, "delay": 0.0, "lane": 0, "waypoint": 1, "speed": 0.0}
    game.enemies.append(enemy)
    return enemy

func run() -> void:
    var game = fresh()
    var grunt := enemy_near(game, "grunt", 10)
    check(game.hero_attack(grunt["pos"]) and int(grunt["hp"]) == 10 - game.HERO_DAMAGE, "Hero strikes ordinary enemies for HERO_DAMAGE")
    check(is_equal_approx(game.hero_attack_cooldown, game.HERO_COOLDOWN), "Hero strike cooldown is HERO_COOLDOWN")
    check(not game.hero_attack(grunt["pos"]), "Hero cannot strike again during the cooldown")
    game.hero_attack_cooldown = 0.0
    game.enemies.clear()
    var captain := enemy_near(game, "captain", 20)
    check(game.hero_attack(captain["pos"]) and int(captain["hp"]) == 20 - game.HERO_HEAVY_DAMAGE, "Captains take the heavy strike")
    check(game.hero_damage_dealt == game.HERO_DAMAGE + game.HERO_HEAVY_DAMAGE, "Damage counter sums real strikes")
    game.enemies.clear()
    game.hero_attack_cooldown = 0.0
    var weak := enemy_near(game, "grunt", 1)
    var before: int = game.hero_damage_dealt
    game.hero_attack(weak["pos"])
    check(game.hero_damage_dealt == before + 1, "Damage counter ignores overkill")
    game.get_parent().remove_child(game)
    game.free()

    # Boss interrupt: two strikes during the warning, whatever the tuning.
    game = fresh()
    var boss := enemy_near(game, "boss", 200)
    boss["boss_warning"] = true
    boss["boss_charge"] = 2.0
    game.hero_attack(boss["pos"])
    check(bool(boss["boss_warning"]), "One strike does not interrupt the boss")
    game.hero_attack_cooldown = 0.0
    game.hero_attack(boss["pos"])
    check(not bool(boss["boss_warning"]) and float(boss["boss_charge"]) == 0.0, "Two strikes interrupt the boss charge")
    check(int(boss["hp"]) == 200 - 2 * game.HERO_HEAVY_DAMAGE, "The boss takes heavy strikes")
    game.restart_defense()
    check(game.hero_damage_dealt == 0, "Damage counter resets with the defense")
    game.get_parent().remove_child(game)
    game.free()
    # The run's first morning adds the treasury bonus; later days do not.
    var run = load("res://scenes/run_loop.tscn").instantiate()
    run.meta.save_path = "user://last_ritual_meta_hero_role_smoke.json"
    root.add_child(run)
    check(run.start_run() and run.active_game.coins == 150 + run.active_game.FIRST_DAY_TREASURY_BONUS + run.meta.treasury_level * 10, "Day one starts with the first-morning treasury bonus")
    check(run.active_game.HERO_DAMAGE < run.active_game.HERO_HEAVY_DAMAGE, "Hero hits elites harder than ordinary enemies")
    run.active_game.coins = 40
    run.finish_phase(true)
    run.complete_transition()
    run.active_game.night_souls = 0
    run.finish_phase(true)
    run.choose_run_reward("necro")
    run.complete_transition()
    check(run.phase == "day" and run.active_game.coins == 40 + run.meta.treasury_level * 10, "Later days get no first-morning bonus")
    run.get_parent().remove_child(run)
    run.free()
    if FileAccess.file_exists("user://last_ritual_meta_hero_role_smoke.json"):
        DirAccess.remove_absolute(ProjectSettings.globalize_path("user://last_ritual_meta_hero_role_smoke.json"))
    print("TD HERO ROLE RESULT: ", "PASS" if failures == 0 else "FAIL")
    quit(1 if failures > 0 else 0)
