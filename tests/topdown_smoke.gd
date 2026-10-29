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
    var td_scene := load("res://scenes/topdown_td_prototype.tscn") as PackedScene
    check(td_scene != null, "Top-down TD scene loads")
    if td_scene != null:
        var td = td_scene.instantiate()
        root.add_child(td)
        check(td.slots.size() == 8, "TD has eight fixed construction slots")
        check(td.slot_at(Vector2(0, 0)) == -1, "No construction slot outside designated areas")
        check(td.choose_tower("bone"), "Select bone tower")
        check(not td.build_tower(-1), "Cannot build off slot")
        check(td.build_tower(0) and td.coins == 120, "Build bone tower at fixed slot")
        check(not td.build_tower(0), "Occupied slot rejects duplicate building")
        check(td.choose_tower("necro") and td.build_tower(1), "Different tower uses its own build slot")
        check(td.select_slot(0) and td.upgrade_selected(), "Click selected tower to upgrade")
        check(td.sell_selected() and td.slots[0]["tower"] == "", "Sold tower frees slot")
        check(td.choose_tower("fire") and td.build_tower(0), "Freed slot can be built again")
        td.coins = 0
        check(td.choose_tower("fire") and not td.build_tower(2), "Insufficient gold prevents building")
        check(td.WAVE_BUTTON.has_point(Vector2(100, 570)), "TD wave button has reachable mouse target")
        check(td.start_wave() and td.wave_number == 1 and td.enemies.size() == 3, "TD first wave spawns three enemies")
        check(not td.start_wave(), "TD prevents overlapping waves")
        check(td.enemies[0]["lane"] == 0 and td.enemies[1]["lane"] == 1, "TD enemies use two distinct paths")
        td.advance_enemies(20.0)
        td.advance_enemies(20.0)
        td.advance_enemies(20.0)
        check(td.enemies.is_empty() and td.altar_hp == 70 and td.enemies_escaped == 3, "TD escaped enemies reduce altar HP")
        check(td.start_wave() and td.wave_number == 2, "TD second wave starts")
        td.enemies.clear()
        check(td.start_wave() and td.wave_number == 3, "TD third wave starts")
        td.enemies.clear()
        check(not td.start_wave(), "TD stops at three waves")
        td.coins = 0
        td.enemies.clear()
        td.enemies.append({"lane": 0, "pos": td.slots[0]["pos"] + Vector2(20, 0), "waypoint": 1, "hp": 1, "delay": 0.0})
        var kills_before: int = td.enemies_defeated
        td.attack_with_towers(1.0)
        check(td.enemies.is_empty() and td.enemies_defeated == kills_before + 1, "TD tower automatically kills enemy within range")
        check(td.coins == 5, "TD defeated enemy grants gold")
        check(td.shot_trails.size() > 0, "TD tower attack creates visible shot feedback")
        td.enemies.append({"lane": 0, "pos": Vector2(1050, 330), "waypoint": 2, "hp": 5, "delay": 0.0})
        td.attack_with_towers(2.0)
        check(td.enemies.size() == 1 and td.enemies[0]["hp"] == 5, "TD tower ignores enemies beyond range")
        td.hero_pos = Vector2(400, 400)
        td.move_hero(Vector2(1, 0), 1.0)
        check(td.hero_pos.x > 400, "TD defender hero moves")
        td.hero_pos = Vector2(400, 350)
        td.enemies.clear()
        td.enemies.append({"lane": 0, "pos": Vector2(420, 350), "waypoint": 1, "hp": 2, "delay": 0.0})
        td.hero_attack_cooldown = 0.0
        var hero_kills_before: int = td.enemies_defeated
        check(td.hero_attack(Vector2(420, 350)), "TD hero attacks selected enemy")
        check(td.enemies.is_empty() and td.enemies_defeated == hero_kills_before + 1, "TD hero kills enemy and earns gold")
        check(not td.hero_attack(Vector2(420, 350)), "TD hero attack respects cooldown and empty targets")
        td.restart_defense()
        check(td.defense_state == "playing" and td.wave_number == 0 and td.altar_hp == 100, "TD restart resets wave and altar")
        check(td.slots[0]["tower"] == "" and td.coins == 150, "TD restart clears towers and restores economy")
        td.wave_number = 3
        td.enemies.clear()
        td._process(0.0)
        check(td.defense_state == "won", "TD victory after final cleared wave")
        check(not td.start_wave(), "TD victory blocks further waves")
        td.restart_defense()
        td.altar_hp = 10
        td.enemies.append({"lane": 0, "pos": Vector2(1070, 285), "waypoint": 2, "hp": 1, "delay": 0.0})
        td.advance_enemies(0.01)
        check(td.defense_state == "lost" and td.altar_hp == 0, "TD altar defeat ends defense")
        check(not td.start_wave(), "TD defeat blocks more waves")
        td.restart_defense()
        check(td.defense_state == "playing" and td.altar_hp == 100 and td.enemies.is_empty(), "TD restart after defeat succeeds")
        td.queue_free()
    var packed := load("res://scenes/topdown_night_prototype.tscn") as PackedScene
    check(packed != null, "Top-down entry scene loads")
    if packed == null:
        quit(1)
        return
    var game = packed.instantiate()
    root.add_child(game)
    check(game.room_index == 0 and game.enemies.size() == 2, "First room has two enemy archetypes")
    check(game.enemies[1]["ranged"], "Ranged enemy is present")
    check(not game.next_room(), "Room remains locked while enemies live")
    game.player_pos = Vector2(560.0, 240.0)
    for i in range(3):
        game.attack_cooldown = 0.0
        check(game.attack(Vector2(570.0, 240.0)), "Hero can attack first enemy")
    check(game.enemies.size() == 1, "First enemy defeated")
    game.player_pos = Vector2(710.0, 370.0)
    for i in range(3):
        game.attack_cooldown = 0.0
        check(game.attack(Vector2(730.0, 370.0)), "Hero can attack ranged enemy")
    check(game.reward_available and not game.door_available(), "Reward blocks exit until collected")
    check(not game.choose_relic("invalid"), "Invalid relic is rejected")
    check(game.choose_relic("bone"), "Bone relic can be chosen")
    check(game.attack_damage == 2 and game.relics == ["bone"], "Bone relic increases damage")
    check(not game.choose_relic("blood"), "Room reward cannot be taken twice")
    check(game.door_available() and game.next_room(), "Door unlocks to room two")
    check(game.room_index == 1 and game.hostile_shots.is_empty(), "New room resets projectiles")
    game.enemies.clear()
    game.reward_available = true
    check(game.choose_relic("ember"), "Ember can be chosen in later room")
    check(is_equal_approx(game.attack_speed_multiplier, 1.25), "Ember increases attack speed")
    check(game.next_room() and game.room_index == 2, "Final room reachable")
    game.enemies.clear()
    game.reward_available = true
    var hp_before: int = game.player_hp
    check(game.choose_relic("blood"), "Blood relic chosen")
    check(game.attack_damage == 4 and game.player_hp < hp_before, "Blood relic trades HP for damage")
    check(not game.next_room(), "Cannot go beyond final room")
    game.move_player(Vector2(-1, -1), 100.0)
    check(game.player_pos.x >= 64.0 and game.player_pos.y >= 84.0, "Player stays inside arena")
    game.restart_run()
    game.invulnerable_time = 0.0
    game.take_damage(999)
    check(game.run_state == "lost" and game.player_hp == 0, "Lethal damage ends run")
    check(not game.attack(Vector2(570.0, 240.0)) and not game.next_room(), "Cannot fight or progress after death")
    game.restart_run()
    check(game.run_state == "playing" and game.player_hp == 100 and game.room_index == 0, "Restart restores health and room")
    check(game.relics.is_empty() and game.rewards_taken == 0 and game.attack_damage == 1, "Restart clears run-only relic upgrades")
    game.room_index = 2
    game.enemies.clear()
    game.reward_available = true
    check(game.choose_relic("bone") and game.run_state == "won", "Final reward completes short prototype run")
    game.restart_run()
    check(game.run_state == "playing" and game.room_index == 0, "Restart after victory works")
    game.reward_available = true
    check(game.click_ui(Vector2(301, 470)) and game.relics == ["bone"], "Mouse selects first relic card")
    check(not game.click_ui(Vector2(301, 470)), "Mouse cannot claim same reward twice")
    game.take_damage(999)
    check(game.run_state == "lost", "Death opens restart panel")
    check(game.click_ui(Vector2(500, 330)), "Restart button accepts mouse click")
    check(game.run_state == "playing" and game.relics.is_empty(), "Mouse restart clears relics")
    game.queue_free()
    print("TOPDOWN SMOKE RESULT: ", "PASS" if failures == 0 else str(failures) + " FAILURES")
    quit(0 if failures == 0 else 1)
