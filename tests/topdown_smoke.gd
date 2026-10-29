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
    game.queue_free()
    print("TOPDOWN SMOKE RESULT: ", "PASS" if failures == 0 else str(failures) + " FAILURES")
    quit(0 if failures == 0 else 1)
