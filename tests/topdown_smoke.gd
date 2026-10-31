extends SceneTree

var failures := 0

func check(value: bool, description: String) -> void:
    if not value:
        failures += 1
        push_error("FAIL " + description)
    else:
        print("PASS " + description)

func left_click_event(point: Vector2) -> InputEventMouseButton:
    var event := InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_LEFT
    event.position = point
    event.pressed = true
    return event

func _initialize() -> void:
    call_deferred("run_tests")

func run_tests() -> void:
    var floor_generator = load("res://scripts/dungeon_floor_graph.gd")
    check(floor_generator != null, "Dungeon topology generator loads")
    if floor_generator != null:
        var first_floor: Dictionary = floor_generator.generate_floor(42)
        var same_floor: Dictionary = floor_generator.generate_floor(42)
        check(first_floor == same_floor, "Dungeon room graph is reproducible by seed")
        check(first_floor["rooms"].size() == 10, "Dungeon contains ten connected rooms")
        check(floor_generator.reachable(first_floor), "Dungeon rooms and boss are reachable")
        var found_roles := {}
        for room in first_floor["rooms"]:
            found_roles[room["kind"]] = true
            for adjacent in room["neighbors"]:
                var target = first_floor["rooms"][adjacent]
                check(target["neighbors"].has(room["id"]), "Dungeon doorway links are bidirectional")
                check((target["grid"] - room["grid"]).length_squared() == 1, "Dungeon doors connect adjacent grid cells")
        check(found_roles.has("ВХОД") and found_roles.has("БОСС") and found_roles.has("МАГАЗИН") and found_roles.has("СОКРОВИЩНИЦА"), "Dungeon guarantees essential room roles")
        for dungeon_seed in range(20):
            var generated: Dictionary = floor_generator.generate_floor(dungeon_seed)
            check(generated["rooms"].size() == 10 and floor_generator.reachable(generated), "Generated floor stays connected across seeds")
    var exploratory_scene = load("res://scenes/topdown_night_prototype.tscn")
    if exploratory_scene != null:
        var exploration = exploratory_scene.instantiate()
        root.add_child(exploration)
        exploration.enable_floor_exploration(42)
        check(exploration.exploration_enabled and exploration.floor_data["rooms"].size() == 10, "Night game enables ten-room exploration")
        check(not exploration.travel_through_door(Vector2i.RIGHT), "Doors stay blocked during active encounter")
        var starting_neighbors: Dictionary = exploration.door_neighbors()
        check(not starting_neighbors.is_empty(), "Spawn room has at least one accessible neighbor")
        var first_direction: Vector2i = starting_neighbors.keys()[0]
        exploration.enemies.clear()
        exploration.reward_available = false
        check(exploration.travel_through_door(first_direction), "Cleared room can enter adjacent generated room")
        check(exploration.room_index == int(starting_neighbors[first_direction]), "Room transitions follow generated graph")
        check(exploration.visited_rooms.size() == 2, "Exploration tracks discovered rooms")
        exploration.enemies.clear()
        exploration.reward_available = false
        check(exploration.travel_through_door(-first_direction), "Backtracking through opposite door returns to original room")
        check(exploration.room_index == 0 and exploration.enemies.is_empty(), "Previously cleared room stays cleared")
        exploration.queue_free()
    var special_scene = load("res://scenes/topdown_night_prototype.tscn")
    if special_scene != null:
        var special = special_scene.instantiate()
        root.add_child(special)
        special.enable_floor_exploration(42)
        var treasury_id := -1
        var shop_id := -1
        for room in special.floor_data["rooms"]:
            if room["kind"] == "СОКРОВИЩНИЦА":
                treasury_id = int(room["id"])
            elif room["kind"] == "МАГАЗИН":
                shop_id = int(room["id"])
        check(treasury_id >= 0 and shop_id >= 0, "Floor has playable treasury and shop")
        special.player_hp = 50
        special.night_souls = 0
        special.open_room(treasury_id)
        check(special.player_hp == 75 and special.night_souls == 3, "Treasury heals and grants souls")
        special.open_room(treasury_id)
        check(special.night_souls == 3, "Treasury reward is claimed only once")
        special.open_room(shop_id)
        check(special.shop_open and special.enemies.is_empty(), "Merchant room opens shop without battle")
        check(special.buy_shop_offer(0) and special.night_souls == 1, "Merchant exchanges souls for damage")
        check(special.leave_shop() and special.cleared_rooms.has(shop_id), "Leaving merchant clears room and unlocks doors")
        special.open_room(shop_id)
        check(not special.shop_open, "Merchant does not reset on revisit")
        special.queue_free()
    var boss_scene = load("res://scenes/topdown_night_prototype.tscn")
    if boss_scene != null:
        var boss_game = boss_scene.instantiate()
        root.add_child(boss_game)
        boss_game.enable_floor_exploration(73)
        var boss_id: int = int(boss_game.floor_data["boss"])
        boss_game.open_room(boss_id)
        var guardians := 0
        for foe in boss_game.enemies:
            if foe.get("role", "") == "boss":
                guardians += 1
                check(int(foe["hp"]) >= 30, "Ritual guardian has boss-scale health")
        check(guardians == 1 and boss_game.enemies.size() == 3, "Boss chamber spawns guardian with escort")
        boss_game.queue_free()
    var ritual_scene = load("res://scenes/topdown_night_prototype.tscn")
    if ritual_scene != null:
        var ritual_game = ritual_scene.instantiate()
        root.add_child(ritual_game)
        ritual_game.enable_floor_exploration(31)
        ritual_game.open_room(int(ritual_game.floor_data["boss"]))
        var guardian: Dictionary = {}
        for enemy in ritual_game.enemies:
            if enemy.get("role", "") == "boss":
                guardian = enemy
                break
        check(not guardian.is_empty(), "Ritual guardian exists for phase tests")
        if not guardian.is_empty():
            ritual_game.update_guardian_boss(2.0)
            check(float(guardian.get("ritual_warning", 0.0)) > 0.0, "Guardian telegraphs area attack")
            guardian["hp"] = 14
            guardian["ritual_warning"] = 0.0
            guardian["ritual_cooldown"] = 0.0
            ritual_game.update_guardian_boss(0.1)
            check(float(guardian["ritual_warning"]) <= 0.65, "Enraged guardian accelerates warning")
        ritual_game.queue_free()
    var event_scene = load("res://scenes/topdown_night_prototype.tscn")
    if event_scene != null:
        var events = event_scene.instantiate()
        root.add_child(events)
        events.enable_floor_exploration(42)
        var secret_id := -1
        var event_id := -1
        for room in events.floor_data["rooms"]:
            if room["kind"] == "ТАЙНИК":
                secret_id = int(room["id"])
            elif room["kind"] == "СОБЫТИЕ":
                event_id = int(room["id"])
        check(secret_id >= 0 and event_id >= 0, "Each floor includes a cache and event room")
        events.night_souls = 0
        var original_damage: int = events.attack_damage
        events.open_room(secret_id)
        check(events.night_souls == 2 and events.attack_damage == original_damage + 1, "Cache grants souls and damage")
        events.open_room(secret_id)
        check(events.night_souls == 2, "Cache cannot be farmed by revisits")
        events.open_room(event_id)
        check(events.shrine_open and not events.door_available(), "Shrine blocks travel until choice")
        events.player_hp = 50
        check(events.choose_shrine_blessing(0) and events.player_hp == 65, "Shrine heals upon choosing blessing")
        check(events.cleared_rooms.has(event_id) and not events.shrine_open, "Shrine completes after choice")
        events.open_room(event_id)
        check(not events.shrine_open, "Shrine cannot be claimed twice")
        events.queue_free()
    var hidden_scene = load("res://scenes/topdown_night_prototype.tscn")
    if hidden_scene != null:
        var hidden = hidden_scene.instantiate()
        root.add_child(hidden)
        hidden.enable_floor_exploration(42)
        var stash_id := -1
        for room in hidden.floor_data["rooms"]:
            if room["kind"] == "ТАЙНИК":
                stash_id = int(room["id"])
        check(stash_id >= 0, "Generated floor includes hidden stash")
        if stash_id >= 0:
            var neighbor_id: int = int(hidden.floor_data["rooms"][stash_id]["neighbors"][0])
            hidden.open_room(neighbor_id)
            hidden.enemies.clear()
            hidden.reward_available = false
            var delta: Vector2i = hidden.floor_data["rooms"][stash_id]["grid"] - hidden.floor_data["rooms"][neighbor_id]["grid"]
            check(not hidden.door_neighbors().has(delta), "Secret doorway stays invisible before discovery")
            check(hidden.reveal_adjacent_secret(), "Player can discover secret next door")
            check(hidden.door_neighbors().has(delta), "Discovered secret opens its doorway")
            check(not hidden.reveal_adjacent_secret(), "Secret cannot be rediscovered repeatedly")
        hidden.queue_free()
    var click_door_scene = load("res://scenes/topdown_night_prototype.tscn")
    if click_door_scene != null:
        var click_night = click_door_scene.instantiate()
        root.add_child(click_night)
        click_night.enable_floor_exploration(12)
        click_night.enemies.clear()
        click_night.reward_available = false
        var click_direction: Vector2i = click_night.door_neighbors().keys()[0]
        var click_point: Vector2 = click_night.DOOR_POINTS[click_direction]
        check(not click_night.click_open_door(click_point), "Door click requires nearby hero")
        click_night.player_pos = click_point + Vector2(-20, 0)
        check(click_night.click_open_door(click_point), "Left-click on nearby open door changes room")
        click_night.queue_free()
    var persistent_td_scene = load("res://scenes/topdown_td_prototype.tscn")
    if persistent_td_scene != null:
        var first_day = persistent_td_scene.instantiate()
        root.add_child(first_day)
        check(first_day.choose_tower("bone") and first_day.build_tower(0), "Build first permanent tower")
        first_day.coins = 100
        first_day.select_slot(0)
        check(first_day.upgrade_selected(), "Upgrade permanent tower")
        first_day.altar_hp = 79
        var saved_fortress: Dictionary = first_day.export_fortress_state()
        var next_day = persistent_td_scene.instantiate()
        root.add_child(next_day)
        check(next_day.import_fortress_state(saved_fortress), "Fortress state restores on next day")
        check(next_day.slots[0]["tower"] == "bone" and int(next_day.slots[0]["level"]) == 2, "Tower and upgrade persist")
        check(next_day.coins == 80 and next_day.altar_hp == 79, "Treasury and altar health persist")
        var bad_state := saved_fortress.duplicate(true)
        bad_state["buildings"][0]["tower"] = "invalid"
        check(not next_day.import_fortress_state(bad_state), "Invalid tower snapshot is rejected")
        first_day.queue_free()
        next_day.queue_free()
    var spec_scene = load("res://scenes/topdown_td_prototype.tscn")
    if spec_scene != null:
        var spec_game = spec_scene.instantiate()
        root.add_child(spec_game)
        spec_game.choose_tower("bone")
        spec_game.build_tower(0)
        spec_game.coins = 100
        spec_game.select_slot(0)
        check(spec_game.upgrade_selected(), "Tower reaches specialization threshold")
        check(spec_game.specialization_open, "Specialization choice opens at level two")
        var blocked_click := InputEventMouseButton.new()
        blocked_click.button_index = MOUSE_BUTTON_LEFT
        blocked_click.pressed = true
        blocked_click.position = Vector2(100, 570)
        spec_game._unhandled_input(blocked_click)
        check(spec_game.wave_number == 0 and spec_game.specialization_open, "Modal blocks clicks on underlying wave start")

        check(spec_game.choose_specialization("siege"), "Player can choose siege specialization")
        check(spec_game.slots[0]["specialization"] == "siege", "Specialization stored on tower")
        var spec_snapshot: Dictionary = spec_game.export_fortress_state()
        var spec_next = spec_scene.instantiate()
        root.add_child(spec_next)
        check(spec_next.import_fortress_state(spec_snapshot), "Specialization persists across day scenes")
        check(spec_next.slots[0]["specialization"] == "siege", "Restored tower keeps specialization")
        spec_game.queue_free()
        spec_next.queue_free()
    var school_scene = load("res://scenes/topdown_td_prototype.tscn")
    if school_scene != null:
        var school = school_scene.instantiate()
        root.add_child(school)
        school.choose_tower("fire")
        check(school.build_tower(0), "Build fire specialization tower")
        school.coins = 200
        school.select_slot(0)
        check(school.upgrade_selected() and school.choose_specialization("siege"), "Fire chooses Inferno")
        var burning := {"burn_time": 0.0, "hp": 20}
        school.apply_burn(burning)
        check(int(burning["burn_damage"]) >= 1, "Fire burn effect initializes")
        school.spawn_necro_spirit(Vector2(200, 200), true)
        check(school.summoned_spirits.size() == 1 and int(school.summoned_spirits[0]["damage"]) == 4, "Reaper creates empowered spirit")
        school.queue_free()
    # A three-second fire effect must land all six half-second ticks,
    # including the tick exactly when burn_time reaches zero.
    var fire_timing_scene = load("res://scenes/topdown_td_prototype.tscn") as PackedScene
    if fire_timing_scene != null:
        var fire_timing = fire_timing_scene.instantiate()
        root.add_child(fire_timing)
        var steady_foe := {"hp": 10, "pos": Vector2(400, 300), "delay": 0.0}
        fire_timing.enemies.append(steady_foe)
        fire_timing.apply_burn(steady_foe)
        for tick_index in range(6):
            fire_timing.tick_burning(0.5)
        check(steady_foe["hp"] == 4 and is_equal_approx(float(steady_foe["burn_time"]), 0.0), "Fire burn applies all six scheduled ticks including expiration")
        fire_timing.tick_burning(0.5)
        check(steady_foe["hp"] == 4, "Expired burn never deals damage twice")
        fire_timing.enemies.clear()
        var lagged_foe := {"hp": 10, "pos": Vector2(400, 300), "delay": 0.0}
        fire_timing.enemies.append(lagged_foe)
        fire_timing.apply_burn(lagged_foe)
        fire_timing.tick_burning(5.0)
        check(lagged_foe["hp"] == 4 and is_equal_approx(float(lagged_foe["burn_time"]), 0.0), "Large frame applies the same finite burn damage without extending duration")
        fire_timing.enemies.clear()
        var lethal_foe := {"hp": 3, "pos": Vector2(400, 300), "delay": 0.0}
        fire_timing.enemies.append(lethal_foe)
        fire_timing.apply_burn(lethal_foe)
        var coins_before_fire: int = fire_timing.coins
        var kills_before_fire: int = fire_timing.enemies_defeated
        fire_timing.tick_burning(5.0)
        fire_timing.tick_burning(5.0)
        check(fire_timing.enemies.is_empty() and fire_timing.coins == coins_before_fire + 5 and fire_timing.enemies_defeated == kills_before_fire + 1, "Lethal burn grants exactly one kill and one gold reward")
        fire_timing.queue_free()
    # Same 65-gold fire investment, distinct roles: Inferno wins against
    # one durable foe, while Sparks distributes ordinary burns to a group.
    var specialization_balance_scene = load("res://scenes/topdown_td_prototype.tscn") as PackedScene
    if specialization_balance_scene != null:
        var sparks = specialization_balance_scene.instantiate()
        root.add_child(sparks)
        check(sparks.choose_tower("fire") and sparks.build_tower(0), "Sparks benchmark purchases fire tower")
        check(sparks.upgrade_selected() and sparks.choose_specialization("swarm"), "Sparks benchmark invests in level two")
        check(sparks.coins == 85, "Fire level-two build costs 45 plus 20 gold")
        var sparks_foes: Array[Dictionary] = []
        for offset in [Vector2(20, 10), Vector2(50, 10), Vector2(80, 10), Vector2(110, 10)]:
            var foe: Dictionary = {"pos": sparks.slots[0]["pos"] + offset, "hp": 100, "delay": 0.0}
            sparks.enemies.append(foe)
            sparks_foes.append(foe)
        sparks.attack_with_towers(1.0)
        check(sparks_foes[0].has("burn_time") and sparks_foes[1].has("burn_time") and sparks_foes[2].has("burn_time"), "Sparks ignites three enemies with a single volley")
        check(not sparks_foes[3].has("burn_time"), "Sparks target cap stops at three enemies")
        sparks.tick_burning(3.0)
        check(sparks_foes[0]["hp"] == 93 and sparks_foes[1]["hp"] == 93 and sparks_foes[2]["hp"] == 93 and sparks_foes[3]["hp"] == 100, "Sparks deals ordinary burn damage across its three targets")
        check(sparks.coins == 85, "Burning without a kill grants no additional gold")
        sparks.queue_free()

        var inferno = specialization_balance_scene.instantiate()
        root.add_child(inferno)
        check(inferno.choose_tower("fire") and inferno.build_tower(0), "Inferno benchmark purchases fire tower")
        check(inferno.upgrade_selected() and inferno.choose_specialization("siege"), "Inferno benchmark uses equal gold investment")
        var sturdy_foe: Dictionary = {"pos": inferno.slots[0]["pos"] + Vector2(20, 10), "hp": 100, "delay": 0.0}
        inferno.enemies.append(sturdy_foe)
        inferno.attack_with_towers(1.0)
        inferno.tick_burning(3.0)
        check(inferno.coins == 85 and sturdy_foe["hp"] == 78, "Inferno spends the same gold but burns down a single armored target faster")
        inferno.queue_free()
    # Bone specialization benchmark: equal 50-gold investment, isolated tower,
    # one durable target. Ballista has stronger individual shots, while Swarm
    # gains additional shots over time. No hero, relic or synergy modifiers.
    if specialization_balance_scene != null:
        var ballista = specialization_balance_scene.instantiate()
        root.add_child(ballista)
        check(ballista.choose_tower("bone") and ballista.build_tower(0), "Ballista benchmark builds bone tower")
        check(ballista.upgrade_selected() and ballista.choose_specialization("siege"), "Ballista benchmark upgrades for 20 gold")
        check(ballista.coins == 100, "Ballista costs 50 gold total")
        var ballista_foe: Dictionary = {"pos": ballista.slots[0]["pos"] + Vector2(30, 0), "hp": 100, "delay": 0.0}
        ballista.enemies.append(ballista_foe)
        ballista.attack_with_towers(0.01)
        check(ballista_foe["hp"] == 94, "Ballista hits one durable target for six damage")
        ballista.attack_with_towers(0.45)
        check(ballista_foe["hp"] == 94, "Ballista has not reloaded after 0.45 seconds")
        ballista.queue_free()

        var bone_swarm = specialization_balance_scene.instantiate()
        root.add_child(bone_swarm)
        check(bone_swarm.choose_tower("bone") and bone_swarm.build_tower(0), "Bone swarm benchmark builds bone tower")
        check(bone_swarm.upgrade_selected() and bone_swarm.choose_specialization("swarm"), "Bone swarm benchmark upgrades for 20 gold")
        check(bone_swarm.coins == 100, "Bone swarm also costs 50 gold total")
        var swarm_foe: Dictionary = {"pos": bone_swarm.slots[0]["pos"] + Vector2(30, 0), "hp": 100, "delay": 0.0}
        bone_swarm.enemies.append(swarm_foe)
        bone_swarm.attack_with_towers(0.01)
        check(swarm_foe["hp"] == 97, "Bone swarm hits a durable target for three damage")
        bone_swarm.attack_with_towers(0.45)
        check(swarm_foe["hp"] == 94, "Bone swarm fires its second shot while Ballista reloads")
        check(bone_swarm.coins == 100 and ballista.coins == 100, "Neither bone benchmark awards gold without a kill")
        bone_swarm.queue_free()
    # Bone piercing benchmark: aligned targets can be hit, side targets cannot.
    # Small-HP runner proxy demonstrates Ballista's burst vs Swarm's cadence.
    if specialization_balance_scene != null:
        for bone_path in ["siege", "swarm"]:
            var piercing = specialization_balance_scene.instantiate()
            root.add_child(piercing)
            check(piercing.choose_tower("bone") and piercing.build_tower(0), "Piercing benchmark builds bone tower " + bone_path)
            check(piercing.upgrade_selected() and piercing.choose_specialization(bone_path), "Piercing benchmark chooses " + bone_path)
            var base: Vector2 = piercing.slots[0]["pos"]
            var front: Dictionary = {"pos": base + Vector2(20, 0), "hp": 100, "delay": 0.0, "role": "runner"}
            var behind_a: Dictionary = {"pos": base + Vector2(60, 0), "hp": 100, "delay": 0.0, "role": "brute"}
            var behind_b: Dictionary = {"pos": base + Vector2(100, 0), "hp": 100, "delay": 0.0, "role": "brute"}
            var side: Dictionary = {"pos": base + Vector2(60, 45), "hp": 100, "delay": 0.0, "role": "runner"}
            piercing.enemies.append_array([front, behind_a, behind_b, side])
            piercing.attack_with_towers(0.01)
            var expected_hit: int = 94 if bone_path == "siege" else 97
            check(front["hp"] == expected_hit and behind_a["hp"] == expected_hit and behind_b["hp"] == expected_hit, "Bone pierces three aligned targets: " + bone_path)
            check(side["hp"] == 100, "Bone does not pierce off-axis fourth target: " + bone_path)
            check(piercing.coins == 100, "Piercing without kills grants no gold: " + bone_path)
            piercing.queue_free()

        for bone_path in ["siege", "swarm"]:
            var runner_game = specialization_balance_scene.instantiate()
            root.add_child(runner_game)
            check(runner_game.choose_tower("bone") and runner_game.build_tower(0), "Runner benchmark builds tower: " + bone_path)
            check(runner_game.upgrade_selected() and runner_game.choose_specialization(bone_path), "Runner benchmark selects path: " + bone_path)
            var runner: Dictionary = {"pos": runner_game.slots[0]["pos"] + Vector2(30, 0), "hp": 5, "delay": 0.0, "role": "runner"}
            runner_game.enemies.append(runner)
            runner_game.attack_with_towers(0.01)
            check(runner_game.enemies.is_empty() == (bone_path == "siege"), "Ballista instantly stops 5-HP runner, Swarm needs another shot: " + bone_path)
            if bone_path == "swarm":
                runner_game.attack_with_towers(0.45)
                check(runner_game.enemies.is_empty(), "Swarm defeats 5-HP runner on second shot")
            check(runner_game.enemies_defeated == 1 and runner_game.coins == 105, "Runner kill pays exactly once: " + bone_path)
            runner_game.queue_free()
    # Necromancy benchmark: equal 80 gold investments, distinct spirit roles.
    # Reaper has empowered spirits, Legion reaches summons faster; both obey cap.
    if specialization_balance_scene != null:
        for necro_path in ["siege", "swarm"]:
            var necro_balance = specialization_balance_scene.instantiate()
            root.add_child(necro_balance)
            check(necro_balance.choose_tower("necro") and necro_balance.build_tower(0), "Necro benchmark builds tower: " + necro_path)
            check(necro_balance.upgrade_selected() and necro_balance.choose_specialization(necro_path), "Necro benchmark chooses path: " + necro_path)
            check(necro_balance.coins == 70, "Both necromancer paths cost 80 gold: " + necro_path)
            # Put three low-health enemies in range, one per forced shot.
            # Reset cooldown between shots to isolate kill-trigger thresholds.
            for kill_index in range(3):
                var sacrifice: Dictionary = {"pos": necro_balance.slots[0]["pos"] + Vector2(25, 0), "hp": 1, "delay": 0.0}
                necro_balance.enemies.append(sacrifice)
                necro_balance.tower_cooldowns[0] = 0.0
                necro_balance.attack_with_towers(0.01)
                var expected_spirits: int = (1 if kill_index >= 1 else 0) if necro_path == "swarm" else (1 if kill_index >= 2 else 0)
                check(necro_balance.summoned_spirits.size() == expected_spirits, "Necro summon cadence after kill %d: %s" % [kill_index + 1, necro_path])
            check(necro_balance.coins == 85 and necro_balance.enemies_defeated == 3, "Necro kills award gold once: " + necro_path)
            var summoned: Dictionary = necro_balance.summoned_spirits[0]
            check(int(summoned["damage"]) == (4 if necro_path == "siege" else 2), "Reaper spirit deals more damage than Legion: " + necro_path)
            check(is_equal_approx(float(summoned["life"]), 5.0 if necro_path == "siege" else 4.0), "Reaper spirit lasts longer: " + necro_path)
            necro_balance.spawn_necro_spirit(necro_balance.slots[0]["pos"], necro_path == "siege")
            necro_balance.spawn_necro_spirit(necro_balance.slots[0]["pos"], necro_path == "siege")
            check(necro_balance.summoned_spirits.size() == 2, "Necromancy spirit cap remains two: " + necro_path)
            necro_balance.queue_free()
    # Economy benchmark: same starting treasury, exact purchase/upgrade/sale
    # prices for each school. No wave rewards or meta bonuses in this scenario.
    if specialization_balance_scene != null:
        for economy_kind in ["bone", "fire", "necro"]:
            var economy = specialization_balance_scene.instantiate()
            root.add_child(economy)
            var base_cost: int = int(economy.COSTS[economy_kind])
            economy.coins = base_cost - 1
            check(economy.choose_tower(economy_kind), "Economy selects school " + economy_kind)
            check(not economy.build_tower(0) and economy.coins == base_cost - 1, "Insufficient treasury blocks purchase " + economy_kind)
            economy.coins = 150
            check(economy.build_tower(0) and economy.coins == 150 - base_cost, "School purchase charges exact price " + economy_kind)
            check(economy.upgrade_selected() and economy.coins == 130 - base_cost, "Level two upgrade costs 20 gold " + economy_kind)
            check(economy.choose_specialization("siege"), "Economy selects specialization " + economy_kind)
            check(economy.upgrade_selected() and economy.coins == 90 - base_cost, "Level three upgrade costs 40 gold " + economy_kind)
            check(not economy.upgrade_selected() and economy.coins == 90 - base_cost, "Level three is the upgrade cap " + economy_kind)
            check(economy.sell_selected() and economy.coins == 120 - base_cost, "Level three sale returns 30 gold " + economy_kind)
            check(economy.slots[0]["tower"] == "" and int(economy.slots[0]["level"]) == 0, "Sale clears slot " + economy_kind)
            economy.queue_free()
    # Stage 174: day-specific timing must be predictable without changing
    # beginner day-one timing or enemy economy and role counts.
    if specialization_balance_scene != null:
        var assault_timing = specialization_balance_scene.instantiate()
        root.add_child(assault_timing)
        check(is_equal_approx(assault_timing.siege_spawn_delay(2, 2, "runner"), 1.4), "Day one keeps original runner delay")
        assault_timing.siege_day = 2
        check(is_equal_approx(assault_timing.siege_spawn_delay(2, 2, "runner"), 0.7), "Day two runner pack arrives twice as quickly")
        check(is_equal_approx(assault_timing.siege_spawn_delay(2, 1, "brute"), 0.7), "Day two non-runners keep normal pacing")
        assault_timing.siege_day = 3
        check(is_equal_approx(assault_timing.siege_spawn_delay(2, 2, "brute"), 2.2), "Day three armored reinforcement is staggered")
        check(is_equal_approx(assault_timing.siege_spawn_delay(2, 1, "runner"), 0.7), "Day three runners keep baseline timing")
        check(assault_timing.start_wave(), "Day three timed assault starts")
        check(assault_timing.enemies[0]["role"] == "brute" and is_equal_approx(float(assault_timing.enemies[0]["delay"]), 0.8), "Delayed armored vanguard appears in actual wave")
        assault_timing.queue_free()
    # Pure rules can be tested without creating a full TD scene.
    var synergy_rules = load("res://scripts/td/td_synergy_rules.gd")
    check(synergy_rules.preview("bone", true, false) == {"flat": 0, "burning": 2}, "Module: fire supports bone")
    check(synergy_rules.preview("fire", false, true) == {"flat": 0, "burning": 1}, "Module: bone supports burning fire")
    check(synergy_rules.preview("necro", true, true) == {"flat": 1, "burning": 1}, "Module: necromancy combines both sources")
    check(synergy_rules.preview("necro", false, false) == {"flat": 0, "burning": 0}, "Module: no phantom synergy")
    var stats = load("res://scripts/td/td_tower_stats.gd")
    check(stats.COSTS == {"bone": 30, "fire": 45, "necro": 60, "frost": 50}, "Tower stats module preserves prices")
    check(stats.RANGES == {"bone": 135.0, "fire": 160.0, "necro": 125.0, "frost": 145.0}, "Tower stats module preserves independent attack radii")
    check(stats.DAMAGES == {"bone": 2, "fire": 1, "necro": 3, "frost": 1}, "Tower stats module preserves damage")
    check(stats.SPECIALIZATION_LABELS["fire"][1] == "ИСКРЫ: 3 ЦЕЛИ", "Tower stats module keeps specialization labels")
    if specialization_balance_scene != null:
        var range_game = specialization_balance_scene.instantiate()
        root.add_child(range_game)
        check(range_game.choose_tower("fire"), "Hover range selects fire for preview")
        range_game.hovered_slot = 0
        check(is_equal_approx(float(range_game.tower_range_preview().get("range", 0.0)), 160.0), "Empty build site previews selected fire range")
        range_game.hovered_slot = -1
        check(range_game.tower_range_preview().is_empty(), "No preview without hover or selection")
        check(range_game.build_tower(0), "Hover range places tower")
        range_game.hovered_slot = -1
        check(is_equal_approx(float(range_game.tower_range_preview().get("range", 0.0)), 160.0), "Selected tower keeps range visible")
        range_game.hovered_slot = 0
        range_game.help_visible = true
        check(range_game.tower_range_preview().is_empty(), "Help overlay hides attack radius")
        range_game.help_visible = false
        range_game.select_slot(0)
        range_game.hovered_slot = 1
        check(is_equal_approx(float(range_game.tower_range_preview().get("range", 0.0)), 160.0), "Selected tower range available when hovering empty site")
        range_game.queue_free()
    var td_layouts = load("res://scripts/td/td_path_layouts.gd")
    check(td_layouts.layout_count() >= 8, "TD path catalog offers eight distinct fortress maps")
    var two_lane_maps := 0
    var three_lane_maps := 0
    for seed_value in range(td_layouts.layout_count()):
        var paths: Array = td_layouts.layout_for_seed(seed_value)
        check(paths == td_layouts.layout_for_seed(seed_value), "TD path choice reproducible by seed")
        check(paths.size() >= 2 and paths.size() <= 3, "Each fortress map has two or three enemy lanes")
        if paths.size() == 2:
            two_lane_maps += 1
        else:
            three_lane_maps += 1
        for lane_id in range(paths.size()):
            var lane: Array = paths[lane_id]
            check(lane.size() >= 8, "TD route contains multiple bends")
            if lane_id < 2:
                check(lane[0] == td_layouts.LAYOUTS[0][lane_id][0] and lane[-1] == td_layouts.LAYOUTS[0][lane_id][-1], "TD route retains its original entry and altar")
            else:
                check(lane[0] == Vector2(65, 405) and lane[-1] == Vector2(1070, 405), "Third route has its own stable entrance and exit")
            for position in [Vector2(280, 190), Vector2(430, 190), Vector2(590, 190), Vector2(750, 190), Vector2(280, 440), Vector2(430, 440), Vector2(590, 440), Vector2(750, 440)]:
                var closest: float = INF
                for point_id in range(1, lane.size()):
                    var a: Vector2 = lane[point_id - 1]
                    var b: Vector2 = lane[point_id]
                    var t: float = clampf((position - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
                    closest = minf(closest, position.distance_to(a.lerp(b, t)))
                check(closest >= 50.0, "Every map preserves construction pad clearance")
        # Adjacent roads must not overlap in the playable field.
        for lane_a in range(paths.size()):
            for lane_b in range(lane_a + 1, paths.size()):
                var minimum_gap: float = INF
                for road_point in range(1, paths[lane_a].size()):
                    var from_point: Vector2 = paths[lane_a][road_point - 1]
                    var to_point: Vector2 = paths[lane_a][road_point]
                    for sample in range(11):
                        var probe: Vector2 = from_point.lerp(to_point, float(sample) / 10.0)
                        for check_segment in range(1, paths[lane_b].size()):
                            var c: Vector2 = paths[lane_b][check_segment - 1]
                            var d: Vector2 = paths[lane_b][check_segment]
                            var along: float = clampf((probe - c).dot(d - c) / (d - c).length_squared(), 0.0, 1.0)
                            minimum_gap = minf(minimum_gap, probe.distance_to(c.lerp(d, along)))
                check(minimum_gap >= 45.0, "Routes remain visually separate without lane overlap")
    check(two_lane_maps >= 5 and three_lane_maps >= 2, "Map catalog contains both traditional and triple-lane sieges")
    check(td_layouts.layout_for_seed(0) != td_layouts.layout_for_seed(1), "Different seeds can choose different fortress routes")
    # Balanced randomized wave lanes: seeded replays are reproducible, yet
    # successive waves can take different paths without leaving a lane empty.
    if specialization_balance_scene != null:
        var lane_variation = specialization_balance_scene.instantiate()
        root.add_child(lane_variation)
        for map_seed in [0, 6]:
            lane_variation.set_fortress_map_seed(map_seed)
            var lane_count: int = lane_variation.paths.size()
            var observed_patterns: Dictionary = {}
            for attack_wave in range(1, 7):
                var assignments: Array[int] = lane_variation.wave_lane_assignments(lane_count * 4, attack_wave)
                check(assignments == lane_variation.wave_lane_assignments(lane_count * 4, attack_wave), "Same seed and wave reproduce lane assignment")
                observed_patterns[str(assignments)] = true
                for group_start in range(0, assignments.size(), lane_count):
                    var group: Array[int] = assignments.slice(group_start, group_start + lane_count)
                    for lane_idx in range(lane_count):
                        check(group.has(lane_idx), "Each complete enemy group attacks all lanes")
            check(observed_patterns.size() >= 2, "Waves vary the lane attack order instead of fixed alternation")
        lane_variation.set_fortress_map_seed(6)
        lane_variation.siege_day = 4
        lane_variation.wave_number = 1
        var expected_lanes: Array[int] = lane_variation.wave_lane_assignments(int(lane_variation.wave_enemy_budget(2)["ordinary"]), 2)
        check(lane_variation.start_wave(), "Seeded multiroute wave launches")
        for enemy_index in range(expected_lanes.size()):
            check(int(lane_variation.enemies[enemy_index]["lane"]) == expected_lanes[enemy_index], "Real enemy spawn follows randomized lane itinerary")
        lane_variation.queue_free()
    # Per-run map is stable across phases, while a fresh run can choose a new seed.
    if specialization_balance_scene != null:
        var first_map = specialization_balance_scene.instantiate()
        root.add_child(first_map)
        first_map.set_fortress_map_seed(4)
        check(first_map.paths == first_map.TD_PATH_LAYOUTS.layout_for_seed(4), "TD uses selected seed layout")
        var map_snapshot: Dictionary = first_map.export_fortress_state()
        var second_map = specialization_balance_scene.instantiate()
        root.add_child(second_map)
        second_map.set_fortress_map_seed(4)
        check(second_map.import_fortress_state(map_snapshot), "TD restores fortress with matching map")
        check(second_map.paths == first_map.paths, "Same seed keeps layout between days")
        var other_map = specialization_balance_scene.instantiate()
        root.add_child(other_map)
        other_map.set_fortress_map_seed(5)
        check(not other_map.import_fortress_state(map_snapshot), "TD rejects state from another map")
        check(other_map.paths != first_map.paths, "Different map seed changes fortress roads")
        first_map.queue_free()
        second_map.queue_free()
        other_map.queue_free()
    if specialization_balance_scene != null:
        var council = specialization_balance_scene.instantiate()
        root.add_child(council)
        check(not council.choose_interwave_event("raid"), "War council unavailable before third wave")
        council.wave_number = 3
        check(council.can_choose_interwave_event(), "War council opens after third wave")
        check(not council.choose_interwave_event("invalid"), "Invalid war council choice is rejected")
        for reward_seed in range(32):
            council.set_fortress_map_seed(reward_seed)
            if council.council_offers().has("raid"):
                break
        check(council.choose_interwave_event("raid"), "Raid choice grants immediate gold")
        check(council.coins == 185 and council.next_wave_extra_hp == 3, "Raid reward incurs next-wave danger")
        check(not council.choose_interwave_event("safe"), "War council cannot be claimed twice")
        check(council.start_wave(), "Next siege wave starts after council choice")
        check(council.next_wave_extra_hp == 0 and int(council.enemies[0]["hp"]) == 9, "Risk applies only to the following wave")
        council.queue_free()
        var rest_council = specialization_balance_scene.instantiate()
        root.add_child(rest_council)
        rest_council.wave_number = 3
        rest_council.altar_hp = 60
        for reward_seed in range(32):
            rest_council.set_fortress_map_seed(reward_seed)
            if rest_council.council_offers().has("repair"):
                break
        check(rest_council.choose_interwave_event("repair") and rest_council.altar_hp == 80, "War council can heal the altar")
        rest_council.queue_free()
    # Stage 182: later waves have readable, deterministic tactical roles.
    if specialization_balance_scene != null:
        var formations = specialization_balance_scene.instantiate()
        root.add_child(formations)
        check(formations.siege_enemy_role(4, 0) == "runner" and formations.siege_enemy_role(4, 1) == "brute", "Wave four mixes swift vanguard and armored escort")
        check(formations.siege_enemy_role(5, 0) == "brute" and formations.siege_enemy_role(5, 1) == "runner", "Wave five emphasizes pressure from both enemy classes")
        check(formations.siege_enemy_role(6, 0) == "brute" and formations.siege_enemy_role(6, 1) == "runner", "Final wave escorts boss with mixed threats")
        formations.siege_day = 2
        check(formations.siege_enemy_role(4, 0) == "runner", "Swift-raid day retains runner signature")
        formations.siege_day = 3
        check(formations.siege_enemy_role(4, 0) == "brute", "Armored-siege day retains brute signature")
        formations.queue_free()
    if specialization_balance_scene != null:
        var commander_game = specialization_balance_scene.instantiate()
        root.add_child(commander_game)
        var footman := {"role": "grunt", "pos": Vector2(150, 300), "delay": 0.0}
        var commander := {"role": "captain", "pos": Vector2(180, 300), "delay": 0.0}
        commander_game.enemies.append(footman)
        check(is_equal_approx(commander_game.siege_captain_speed_multiplier(footman), 1.0), "Troops do not accelerate without commander")
        commander_game.enemies.append(commander)
        check(is_equal_approx(commander_game.siege_captain_speed_multiplier(footman), 1.2), "Nearby commander rallies footmen")
        check(is_equal_approx(commander_game.siege_captain_speed_multiplier(commander), 1.0), "Commander does not buff itself")
        commander["delay"] = 2.0
        check(is_equal_approx(commander_game.siege_captain_speed_multiplier(footman), 1.0), "Commander cannot rally before entering")
        commander["delay"] = 0.0
        commander["pos"] = Vector2(600, 300)
        check(is_equal_approx(commander_game.siege_captain_speed_multiplier(footman), 1.0), "Commander aura has limited range")
        commander_game.enemies.clear()
        commander_game.wave_number = 4
        check(commander_game.start_wave(), "Commander wave starts")
        var found_commander := false
        for foe in commander_game.enemies:
            if str(foe.get("role", "")) == "captain":
                found_commander = true
        check(found_commander, "Fifth wave fields a commander")
        check(commander_game.enemy_visual_profile("captain")["mark"] == "command", "Commander has distinct silhouette")
        commander_game.queue_free()
    # Stage 184: audit enemy-count progression on all siege days and difficulties.
    if specialization_balance_scene != null:
        var budget_game = specialization_balance_scene.instantiate()
        root.add_child(budget_game)
        check(budget_game.wave_enemy_budget(0).is_empty() and budget_game.wave_enemy_budget(7).is_empty(), "Siege budget rejects waves outside 1–6")
        for day_index in range(1, 6):
            budget_game.siege_day = day_index
            var previous_total := 0
            for wave_index in range(1, 7):
                var budget: Dictionary = budget_game.wave_enemy_budget(wave_index)
                check(int(budget["total"]) > previous_total, "Siege enemy count rises through day %d wave %d" % [day_index, wave_index])
                previous_total = int(budget["total"])
                budget_game.wave_number = wave_index - 1
                budget_game.enemies.clear()
                check(budget_game.start_wave(), "Budgeted wave starts on day %d wave %d" % [day_index, wave_index])
                check(budget_game.enemies.size() == int(budget["total"]), "Actual spawns match budget on day %d wave %d" % [day_index, wave_index])
        budget_game.wave_number = 0
        budget_game.siege_day = 4
        check("ДЕНЬ 4" in budget_game.upcoming_wave_summary(), "Fourth day has its own tactical forecast")
        check(budget_game.siege_enemy_role(2, 0) == "runner" and budget_game.siege_enemy_role(2, 1) == "brute", "Fourth day mixes flankers and armored troops")
        check(int(budget_game.wave_enemy_budget(3)["support"]) == 2, "Fourth day fields a second field medic from wave three")
        budget_game.siege_day = 5
        check("ДЕНЬ 5" in budget_game.upcoming_wave_summary(), "Final day has distinct forecast")
        check(budget_game.siege_enemy_role(2, 0) == "brute" and budget_game.siege_enemy_role(2, 2) == "runner", "Fifth day uses armored vanguard and fast breaches")
        check(int(budget_game.wave_enemy_budget(4)["captain"]) == 1, "Fifth day brings commander one wave earlier")
        budget_game.wave_number = 5
        budget_game.enemies.clear()
        check(budget_game.start_wave(), "Fifth-day boss wave starts")
        var day_five_boss_hp := 0
        for foe in budget_game.enemies:
            if str(foe.get("role", "")) == "boss":
                day_five_boss_hp = int(foe["hp"])
        check(day_five_boss_hp >= 100, "Fifth-day boss has final siege health")
        budget_game.queue_free()
    if specialization_balance_scene != null:
        var pacing = specialization_balance_scene.instantiate()
        root.add_child(pacing)
        check(is_equal_approx(pacing.siege_spawn_delay(1, 4, "grunt"), 2.8), "Opening wave retains readable spacing")
        check(is_equal_approx(pacing.siege_spawn_delay(3, 4, "grunt"), 2.48), "Middle waves accelerate moderately")
        check(is_equal_approx(pacing.siege_spawn_delay(6, 4, "grunt"), 2.2), "Final siege uses tighter enemy cadence")
        pacing.siege_day = 2
        check(is_equal_approx(pacing.siege_spawn_delay(6, 4, "runner"), 1.1), "Fast raider day retains its distinct pacing")
        pacing.siege_day = 3
        check(is_equal_approx(pacing.siege_spawn_delay(6, 4, "brute"), 3.0), "Armored siege retains staggered reinforcements")
        pacing.queue_free()
    if specialization_balance_scene != null:
        var income = specialization_balance_scene.instantiate()
        root.add_child(income)
        var forecast: Dictionary = income.siege_economy_forecast()
        check(int(forecast["enemies"]) == 40, "Day one six-wave siege fields 41 enemies")
        check(int(forecast["kill_gold"]) == 200, "All-kill gold forecast matches per-enemy income")
        check(int(forecast["maximum_gold"]) == 350, "Siege economy forecast includes starting treasury")
        income.siege_day = 2
        check(int(income.siege_economy_forecast()["enemies"]) == 46, "Later siege day adds six attackers")
        check(int(income.siege_economy_forecast()["maximum_gold"]) == 380, "Later siege income scales with attackers")
        income.queue_free()
    if specialization_balance_scene != null:
        var strategy_budget = specialization_balance_scene.instantiate()
        root.add_child(strategy_budget)
        check(strategy_budget.tower_build_budget("bone", 3) == 90, "Bone level three requires 90 total gold")
        check(strategy_budget.tower_build_budget("fire", 3) == 105, "Fire level three requires 105 total gold")
        check(strategy_budget.tower_build_budget("necro", 3) == 120, "Necro level three requires 120 total gold")
        check(strategy_budget.tower_build_budget("bone", 1) + strategy_budget.tower_build_budget("fire", 1) + strategy_budget.tower_build_budget("necro", 1) == 135, "Starting 150 gold permits all three tower schools")
        check(strategy_budget.tower_build_budget("bone", 2) + strategy_budget.tower_build_budget("fire", 2) + strategy_budget.tower_build_budget("necro", 2) == 195, "All three level-two towers require later income")
        check(strategy_budget.tower_build_budget("unknown", 2) == -1 and strategy_budget.tower_build_budget("bone", 4) == -1, "Invalid tower budgets rejected")
        strategy_budget.queue_free()
    if specialization_balance_scene != null:
        var siege_status = specialization_balance_scene.instantiate()
        root.add_child(siege_status)
        check("ПОДГОТОВКА: 1 / 6" in siege_status.siege_progress_label(), "Siege HUD identifies first preparation")
        check(siege_status.start_wave() and "ОБОРОНА: 1 / 6" in siege_status.siege_progress_label(), "Siege HUD identifies active first wave")
        siege_status.enemies.clear()
        check("ПОДГОТОВКА: 2 / 6" in siege_status.siege_progress_label(), "Siege HUD identifies next preparation")
        siege_status.wave_number = siege_status.SIEGE_WAVES
        check(siege_status.siege_progress_label() == "ПОСЛЕДНЯЯ ВОЛНА", "Siege HUD awaits final clear")
        siege_status.defense_state = "won"
        check(siege_status.siege_progress_label() == "ОСАДА ОТБИТА", "Siege HUD identifies victory")
        siege_status.defense_state = "lost"
        check(siege_status.siege_progress_label() == "ОБОРОНА ПРОВАЛЕНА", "Siege HUD identifies defeat")
        siege_status.queue_free()
    var shop_catalog = load("res://scripts/td/td_tower_stats.gd")
    check(shop_catalog.SHOP_ORDER == ["bone", "fire", "necro", "frost"], "Tower shop keeps current mouse ordering")
    check(shop_catalog.DISPLAY_NAMES.size() == shop_catalog.SHOP_ORDER.size(), "Tower shop labels cover all entries")
    for kind in shop_catalog.SHOP_ORDER:
        check(shop_catalog.COSTS.has(kind) and shop_catalog.RANGES.has(kind) and shop_catalog.DAMAGES.has(kind) and shop_catalog.DISPLAY_NAMES.has(kind), "Tower shop entry has complete base stats and name")
    var tower_damage_rules = load("res://scripts/td/td_tower_damage.gd")
    check(tower_damage_rules.direct_damage("bone", 2, "siege", 0, 0) == 6, "Damage module preserves ballista damage")
    check(tower_damage_rules.direct_damage("bone", 2, "swarm", 0, 0) == 3, "Damage module preserves bone swarm damage")
    check(tower_damage_rules.direct_damage("fire", 2, "siege", 2, 0) == 6, "Damage module preserves fire bonus")
    check(tower_damage_rules.direct_damage("necro", 2, "swarm", 0, 0) == 5, "Damage module preserves necro swarm damage")
    check(tower_damage_rules.direct_damage("unknown", 1, "", 0, 0) == 0, "Damage module rejects unknown tower types")
    var target_rules = load("res://scripts/td/td_targeting.gd")
    var probe_tower := {"tower": "bone", "pos": Vector2.ZERO, "target_priority": "nearest"}
    var near_foe := {"pos": Vector2(25, 0), "role": "grunt", "delay": 0.0}
    var healer_foe := {"pos": Vector2(85, 0), "role": "healer", "delay": 0.0}
    var delayed_foe := {"pos": Vector2(2, 0), "role": "grunt", "delay": 4.0}
    var probe_enemies := [near_foe, healer_foe, delayed_foe]
    check(target_rules.choose(probe_tower, probe_enemies, {"bone": 135.0}) == near_foe, "Target module retains nearest rule and ignores pending spawn")
    probe_tower["target_priority"] = "support"
    check(target_rules.choose(probe_tower, probe_enemies, {"bone": 135.0}) == healer_foe, "Target module prioritizes healer")
    probe_tower["target_priority"] = "front"
    check(target_rules.choose(probe_tower, probe_enemies, {"bone": 135.0}) == healer_foe, "Target module prioritizes enemy near gate")
    check(target_rules.choose(probe_tower, probe_enemies, {"bone": 30.0}) == near_foe, "Target module excludes out-of-range enemies")
    var burn_rules = load("res://scripts/td/td_burn_effect.gd")
    var burned_foe := {"hp": 9}
    burn_rules.apply(burned_foe, 1)
    check(int(burned_foe["burn_damage"]) == 2 and is_equal_approx(float(burned_foe["burn_time"]), 3.0), "Burn module initializes duration and synergy damage")
    check(not burn_rules.advance(burned_foe, 0.5) and int(burned_foe["hp"]) == 7, "Burn module applies first tick")
    check(not burn_rules.advance(burned_foe, 1.0) and int(burned_foe["hp"]) == 3, "Burn module handles multiple ticks per frame")
    check(burn_rules.advance(burned_foe, 1.5) and int(burned_foe["hp"]) <= 0, "Burn module resolves lethal expiration tick")
    var multihit = load("res://scripts/td/td_multihit.gd")
    var multihit_primary := {"pos": Vector2(40, 0), "delay": 0.0}
    var multihit_inline := {"pos": Vector2(85, 0), "delay": 0.0}
    var multihit_offline := {"pos": Vector2(90, 50), "delay": 0.0}
    var multihit_pending := {"pos": Vector2(100, 0), "delay": 2.0}
    var multihit_foes := [multihit_primary, multihit_inline, multihit_offline, multihit_pending]
    check(multihit.targets({"tower": "bone", "pos": Vector2.ZERO}, multihit_primary, multihit_foes, 135.0).size() == 2, "Bone pierce hits lined-up enemies but ignores side and pending enemies")
    check(multihit.targets({"tower": "fire", "pos": Vector2.ZERO, "specialization": "swarm"}, multihit_primary, multihit_foes, 135.0).size() == 3, "Sparks hit up to three active enemies")
    check(multihit.targets({"tower": "fire", "pos": Vector2.ZERO, "specialization": "siege"}, multihit_primary, multihit_foes, 135.0).size() == 1, "Inferno retains single-target attack")
    var spirit_rules = load("res://scripts/td/td_necro_spirits.gd")
    var normal_spirit: Dictionary = spirit_rules.create(Vector2.ZERO, false)
    var empowered_spirit: Dictionary = spirit_rules.create(Vector2.ZERO, true)
    check(normal_spirit["damage"] == 2 and is_equal_approx(float(normal_spirit["life"]), 4.0), "Base necro spirit retains lifespan and damage")
    check(empowered_spirit["damage"] == 4 and is_equal_approx(float(empowered_spirit["life"]), 5.0), "Empowered necro spirit retains lifespan and damage")
    var spirit_target := {"pos": Vector2(50, 0), "delay": 0.0}
    var spirit_pending := {"pos": Vector2(10, 0), "delay": 1.0}
    check(spirit_rules.select_target(normal_spirit, [spirit_pending, spirit_target]) == spirit_target, "Spirit ignores pending enemies")
    check(spirit_rules.select_target(normal_spirit, [{"pos": Vector2(180, 0), "delay": 0.0}]).is_empty(), "Spirit respects target radius")
    var frost_rules = load("res://scripts/td/td_frost_effect.gd")
    var frost_enemy := {"speed": 100.0}
    check(is_equal_approx(frost_rules.multiplier(frost_enemy), 1.0), "Fresh enemy has normal movement speed")
    frost_rules.apply(frost_enemy)
    check(is_equal_approx(frost_rules.multiplier(frost_enemy), 0.75), "Frost reduces movement to 75 percent")
    frost_rules.apply(frost_enemy, 1.0, 0.9)
    check(is_equal_approx(frost_rules.multiplier(frost_enemy), 0.45), "Slow cap prevents full immobilization")
    frost_rules.advance(frost_enemy, 2.0)
    check(is_equal_approx(frost_rules.multiplier(frost_enemy), 1.0), "Frost expires and restores speed")
    var frost_stats = load("res://scripts/td/td_tower_stats.gd")
    var frost_damage = load("res://scripts/td/td_tower_damage.gd")
    check(frost_stats.SHOP_ORDER.size() == 4 and frost_stats.SHOP_ORDER[3] == "frost", "Frost becomes fourth mouse-selected tower")
    check(frost_stats.COSTS["frost"] == 50 and frost_stats.RANGES["frost"] == 145.0, "Frost shop cost and range configured")
    check(frost_damage.direct_damage("frost", 1, "", 0, 0) == 1, "Frost direct damage is intentionally low")
    var frost_multihit = load("res://scripts/td/td_multihit.gd")
    var frost_primary := {"pos": Vector2(40, 0), "delay": 0.0}
    var frost_second := {"pos": Vector2(70, 0), "delay": 0.0}
    var frost_third := {"pos": Vector2(100, 0), "delay": 0.0}
    var frost_fourth := {"pos": Vector2(110, 0), "delay": 0.0}
    var frost_foes := [frost_primary, frost_second, frost_third, frost_fourth]
    check(frost_multihit.targets({"tower": "frost", "pos": Vector2.ZERO, "specialization": "siege"}, frost_primary, frost_foes, 145.0).size() == 1, "Frost specialization focuses one target")
    check(frost_multihit.targets({"tower": "frost", "pos": Vector2.ZERO, "specialization": "swarm"}, frost_primary, frost_foes, 145.0).size() == 3, "Blizzard slows up to three enemies")
    # Stage 199: all four school budgets and frost specialization behavior.
    if specialization_balance_scene != null:
        var four_school = specialization_balance_scene.instantiate()
        root.add_child(four_school)
        check(four_school.tower_build_budget("frost", 1) == 50, "Frost starts at 50 gold")
        check(four_school.tower_build_budget("frost", 2) == 70, "Frost upgrade requires 20 more gold")
        check(four_school.tower_build_budget("frost", 3) == 110, "Frost level three full investment is 110")
        check(four_school.tower_build_budget("bone", 1) + four_school.tower_build_budget("fire", 1) + four_school.tower_build_budget("necro", 1) + four_school.tower_build_budget("frost", 1) == 185, "Four-school starting defense costs more than 150 gold")
        check(four_school.choose_tower("frost") and four_school.build_tower(0), "Frost tower can be selected and built by shared controls")
        check(int(four_school.slots[0]["level"]) == 1 and str(four_school.slots[0]["tower"]) == "frost", "Frost occupies tower slot")
        four_school.queue_free()
    if specialization_balance_scene != null:
        var frost_synergy_game = specialization_balance_scene.instantiate()
        root.add_child(frost_synergy_game)
        frost_synergy_game.slots[0]["tower"] = "bone"
        frost_synergy_game.slots[1]["tower"] = "frost"
        var chilled_target := {"hp": 20, "frost_time": 1.5}
        var unchilled_target := {"hp": 20}
        check(frost_synergy_game.tower_synergy_damage(0, chilled_target) == frost_synergy_game.tower_synergy_damage(0, unchilled_target) + 1, "Bone tower gains one bonus against chilled enemies near frost tower")
        frost_synergy_game.slots[1]["tower"] = ""
        check(frost_synergy_game.tower_synergy_damage(0, chilled_target) == frost_synergy_game.tower_synergy_damage(0, unchilled_target), "Frost bone bonus ends without adjacent frost tower")
        frost_synergy_game.queue_free()
    if specialization_balance_scene != null:
        var thermal_game = specialization_balance_scene.instantiate()
        root.add_child(thermal_game)
        thermal_game.slots[0]["tower"] = "fire"
        thermal_game.slots[1]["tower"] = "frost"
        var thermal_chilled := {"hp": 20, "frost_time": 1.5}
        var thermal_plain := {"hp": 20}
        check(thermal_game.tower_synergy_damage(0, thermal_chilled) == thermal_game.tower_synergy_damage(0, thermal_plain) + 1, "Thermal shock adds one fire damage against chilled enemies near frost tower")
        thermal_game.slots[1]["tower"] = ""
        check(thermal_game.tower_synergy_damage(0, thermal_chilled) == thermal_game.tower_synergy_damage(0, thermal_plain), "Thermal shock requires neighboring frost tower")
        thermal_game.queue_free()
    if specialization_balance_scene != null:
        var indicator_game = specialization_balance_scene.instantiate()
        root.add_child(indicator_game)
        indicator_game.slots[0]["tower"] = "bone"
        check(indicator_game.frost_synergy_status(0) == "РЯДОМ НУЖНА ЛЕДЯНАЯ БАШНЯ", "Synergy panel explains missing frost neighbor")
        indicator_game.slots[1]["tower"] = "frost"
        check("ЛЁД + КОСТИ" in indicator_game.frost_synergy_status(0), "Bone synergy visible with frost neighbor")
        indicator_game.slots[0]["tower"] = "fire"
        check("ТЕРМОУДАР" in indicator_game.frost_synergy_status(0), "Fire synergy visible with frost neighbor")
        indicator_game.queue_free()
    # Stage 203: legacy adjacency remains visible alongside frost help.
    if specialization_balance_scene != null:
        var combo_panel = specialization_balance_scene.instantiate()
        root.add_child(combo_panel)
        combo_panel.slots[0]["tower"] = "bone"
        combo_panel.slots[1]["tower"] = "frost"
        combo_panel.slots[2]["tower"] = "fire"
        check(combo_panel.frost_synergy_status(0) != "", "Bone frost help remains available alongside ordinary synergy")
        var preserved_bonus: Dictionary = combo_panel.tower_synergy_preview(0)
        check(preserved_bonus.has("flat") and preserved_bonus.has("burning"), "Frost help does not replace legacy synergy data")
        combo_panel.queue_free()
    if specialization_balance_scene != null:
        var linked_spirit_game = specialization_balance_scene.instantiate()
        root.add_child(linked_spirit_game)
        linked_spirit_game.spawn_necro_spirit(Vector2.ZERO, false, true)
        check(linked_spirit_game.summoned_spirits.size() == 1 and bool(linked_spirit_game.summoned_spirits[0]["frost_link"]), "Necro frost link is carried by summoned spirit")
        linked_spirit_game.summoned_spirits.clear()
        linked_spirit_game.spawn_necro_spirit(Vector2.ZERO)
        check(not bool(linked_spirit_game.summoned_spirits[0]["frost_link"]), "Normal necro spirit does not inherit frost link")
        linked_spirit_game.queue_free()
    if specialization_balance_scene != null:
        var necro_help = specialization_balance_scene.instantiate()
        root.add_child(necro_help)
        necro_help.slots[0]["tower"] = "necro"
        check("ЛЁД РЯДОМ" in necro_help.frost_synergy_status(0), "Necro inspector explains missing frost tower")
        necro_help.slots[1]["tower"] = "frost"
        check("ДУХИ ПРОДЛЕВАЮТ ХОЛОД" in necro_help.frost_synergy_status(0), "Necro inspector confirms frozen spirit synergy")
        necro_help.queue_free()
    var frost_cap_rules = load("res://scripts/td/td_frost_effect.gd")
    var cap_target := {"frost_time": 0.4, "frost_strength": 0.25}
    for repeat_index in range(12):
        frost_cap_rules.apply(cap_target, 1.0, 0.9)
    check(is_equal_approx(frost_cap_rules.multiplier(cap_target), 0.45), "Repeated chills cannot fully immobilize an enemy")
    frost_cap_rules.advance(cap_target, 1.0)
    check(is_equal_approx(frost_cap_rules.multiplier(cap_target), 1.0), "Repeated chill expires without permanent slow")
    var elite_frost = load("res://scripts/td/td_frost_effect.gd")
    var boss_chill := {"role": "boss"}
    var captain_chill := {"role": "captain"}
    var grunt_chill := {"role": "grunt"}
    elite_frost.apply(boss_chill, 2.0, 0.9)
    elite_frost.apply(captain_chill, 2.0, 0.9)
    elite_frost.apply(grunt_chill, 2.0, 0.9)
    check(is_equal_approx(elite_frost.multiplier(boss_chill), 0.70), "Boss retains at least 70 percent movement under frost")
    check(is_equal_approx(elite_frost.multiplier(captain_chill), 0.60), "Captain retains at least 60 percent movement under frost")
    check(is_equal_approx(elite_frost.multiplier(grunt_chill), 0.45), "Normal enemy keeps original frost cap")
    elite_frost.advance(boss_chill, 2.0)
    check(is_equal_approx(elite_frost.multiplier(boss_chill), 1.0), "Boss frost resistance retains normal expiration")
    if specialization_balance_scene != null:
        var control_game = specialization_balance_scene.instantiate()
        root.add_child(control_game)
        var active_captain := {"role": "captain", "pos": Vector2.ZERO, "delay": 0.0, "hp": 24}
        var controlled_grunt := {"role": "grunt", "pos": Vector2(30, 0), "delay": 0.0}
        var controlled_boss := {"role": "boss", "pos": Vector2(40, 0), "delay": 0.0}
        control_game.enemies.clear()
        control_game.enemies.append(active_captain)
        control_game.enemies.append(controlled_grunt)
        control_game.enemies.append(controlled_boss)
        control_game.TD_FROST_EFFECT.apply(controlled_grunt, 2.0, 0.9)
        control_game.TD_FROST_EFFECT.apply(controlled_boss, 2.0, 0.9)
        check(is_equal_approx(control_game.enemy_movement_multiplier(controlled_grunt), 0.54), "Captain morale and frost combine predictably for common foes")
        check(is_equal_approx(control_game.enemy_movement_multiplier(controlled_boss), 0.84), "Boss keeps resistance even beside active captain")
        control_game.enemies.erase(active_captain)
        check(is_equal_approx(control_game.enemy_movement_multiplier(controlled_grunt), 0.45), "Defeating captain removes morale without clearing frost")
        control_game.TD_FROST_EFFECT.advance(controlled_grunt, 2.0)
        check(is_equal_approx(control_game.enemy_movement_multiplier(controlled_grunt), 1.0), "Chill expiration restores regular movement after captain defeat")
        control_game.queue_free()
    if specialization_balance_scene != null:
        var marker_game = specialization_balance_scene.instantiate()
        root.add_child(marker_game)
        var status_foe := {"role": "grunt", "pos": Vector2(20, 0), "delay": 0.0, "frost_time": 1.0, "burn_time": 1.0, "hp": 10}
        check(marker_game.enemy_status_markers(status_foe) == ["frost", "burn"], "Enemy markers combine chill and fire without duplicates")
        var aura_captain := {"role": "captain", "pos": Vector2.ZERO, "delay": 0.0}
        marker_game.enemies.append(aura_captain)
        check(marker_game.enemy_status_markers(status_foe) == ["frost", "burn", "command"], "Enemy indicators show commander aura alongside status effects")
        marker_game.enemies.clear()
        check(marker_game.enemy_status_markers(status_foe).size() == 2, "Commander indicator disappears after commander is defeated")
        marker_game.queue_free()
    if specialization_balance_scene != null:
        var display_state_game = specialization_balance_scene.instantiate()
        root.add_child(display_state_game)
        check(display_state_game.enemy_status_markers({"frost_time": 0.0, "burn_time": 0.0}).is_empty(), "Expired effects do not clutter marker row")
        check(display_state_game.enemy_status_markers({"frost_time": 1.0, "burn_time": 1.0}) == ["frost", "burn"], "Effect marker order stays stable when multiple statuses overlap")
        check(display_state_game.enemy_status_markers({"frost_time": 0.0, "burn_time": 1.0}) == ["burn"], "Removing frost immediately compacts marker row")
        display_state_game.queue_free()
    if specialization_balance_scene != null:
        var icon_layout = specialization_balance_scene.instantiate()
        root.add_child(icon_layout)
        var boss_icons := {"role": "boss", "pos": Vector2(400, 250)}
        var boss_marker: Vector2 = icon_layout.enemy_status_marker_position(boss_icons, 29.0, 1, 3)
        check(boss_marker.x >= 450.0 and is_equal_approx(boss_marker.y, 250.0), "Boss statuses stay right of warning ring and crown")
        var common_icons := {"role": "grunt", "pos": Vector2(400, 250)}
        var common_marker: Vector2 = icon_layout.enemy_status_marker_position(common_icons, 13.0, 1, 3)
        check(common_marker.y < 240.0 and is_equal_approx(common_marker.x, 400.0), "Ordinary status indicators remain above enemies")
        icon_layout.queue_free()
    if specialization_balance_scene != null:
        var edge_icons = specialization_balance_scene.instantiate()
        root.add_child(edge_icons)
        var right_boss := {"role": "boss", "pos": Vector2(1130, 260)}
        var right_marker: Vector2 = edge_icons.enemy_status_marker_position(right_boss, 29.0, 1, 3)
        check(right_marker.x < 1130.0, "Boss markers flip to the left at right screen edge")
        var top_enemy := {"role": "grunt", "pos": Vector2(100, 5)}
        var top_marker: Vector2 = edge_icons.enemy_status_marker_position(top_enemy, 13.0, 0, 2)
        check(top_marker.y > 5.0, "Normal status markers move below enemy near top screen edge")
        var corner_enemy := {"role": "grunt", "pos": Vector2(1, 1)}
        var corner_marker: Vector2 = edge_icons.enemy_status_marker_position(corner_enemy, 13.0, 0, 3)
        check(corner_marker.x >= 6.0 and corner_marker.y >= 6.0, "Status marker remains inside viewport at corner")
        edge_icons.queue_free()
    if specialization_balance_scene != null:
        var trail_styles = specialization_balance_scene.instantiate()
        root.add_child(trail_styles)
        check(trail_styles.shot_trail_style("bone")["impact"] == "shard", "Bone shots show a distinctive impact shard")
        check(trail_styles.shot_trail_style("fire")["impact"] == "ember", "Fire shots retain glowing ember hits")
        check(trail_styles.shot_trail_style("necro")["impact"] == "spirit", "Necro shots retain spirit glow")
        check(trail_styles.shot_trail_style("frost")["impact"] == "crystal", "Frost shots show ice crystals")
        check(trail_styles.shot_trail_style("bone")["width"] > trail_styles.shot_trail_style("frost")["width"], "Bone shots are visually heavier than frost")
        trail_styles.queue_free()
    if specialization_balance_scene != null:
        var trail_budget_game = specialization_balance_scene.instantiate()
        root.add_child(trail_budget_game)
        check(trail_budget_game.visible_shot_trail_start(0) == 0, "Empty attack effects need no draw budget")
        check(trail_budget_game.visible_shot_trail_start(10) == 0, "Small battles retain every hit effect")
        check(trail_budget_game.visible_shot_trail_start(80) == 52, "Large battles draw only the latest 28 shot traces")
        trail_budget_game.queue_free()
    if specialization_balance_scene != null:
        var lifecycle_game = specialization_balance_scene.instantiate()
        root.add_child(lifecycle_game)
        for index in range(100):
            lifecycle_game.shot_trails.append({"time": 0.18, "kind": "fire", "id": index})
        lifecycle_game.update_shot_trails(0.05)
        check(lifecycle_game.shot_trails.size() == 64, "Dense fights retain at most 64 temporary shot trails")
        check(int(lifecycle_game.shot_trails[0]["id"]) == 36 and int(lifecycle_game.shot_trails[-1]["id"]) == 99, "Newest traces are retained when trimming")
        lifecycle_game.update_shot_trails(0.2)
        check(lifecycle_game.shot_trails.is_empty(), "Expired shot trails are removed completely")
        lifecycle_game.queue_free()
    if specialization_balance_scene != null:
        var debug_game = specialization_balance_scene.instantiate()
        root.add_child(debug_game)
        check(not debug_game.performance_overlay_visible, "Performance overlay starts hidden")
        debug_game.shot_trails.clear()
        for index in range(35):
            debug_game.shot_trails.append({"time": 0.18, "kind": "fire"})
        var snapshot: Dictionary = debug_game.performance_snapshot()
        check(int(snapshot["trails_stored"]) == 35 and int(snapshot["trails_visible"]) == 28, "Performance overlay reports rendered and stored traces separately")
        check(int(snapshot["enemies"]) == debug_game.enemies.size() and int(snapshot["spirits"]) == debug_game.summoned_spirits.size(), "Performance overlay counts active enemies and spirits")
        debug_game.queue_free()
    var tooltip_data = load("res://scripts/td/td_tower_tooltips.gd")
    for kind in ["bone", "fire", "necro", "frost"]:
        var shop_details: Dictionary = tooltip_data.shop_info(kind)
        check(not shop_details.is_empty() and int(shop_details["cost"]) > 0 and int(shop_details["range"]) > 0, "Tower shop tooltip documents cost and radius: " + kind)
        check(str(shop_details["effect"]) != "" and str(shop_details["combo"]) != "", "Tower shop tooltip explains behavior and synergy: " + kind)
        var next_upgrade: Dictionary = tooltip_data.upgrade_info(kind, 1, "", 0, 0)
        check(int(next_upgrade["cost"]) == 20 and int(next_upgrade["next_damage"]) > int(next_upgrade["current_damage"]), "First upgrade preview has exact cost and damage: " + kind)
        check(bool(tooltip_data.upgrade_info(kind, 3, "siege", 0, 0)["maxed"]), "Level three tooltip reports maximum level: " + kind)
    if specialization_balance_scene != null:
        var hover_game = specialization_balance_scene.instantiate()
        root.add_child(hover_game)
        var shop_box: Rect2 = hover_game.tower_shop_rect(1)
        check(hover_game.tooltip_at(shop_box.get_center())["title"] == "ОГНЕННАЯ", "Hover position agrees with the displayed fire shop card")
        hover_game.slots[0]["tower"] = "bone"
        hover_game.slots[0]["level"] = 1
        hover_game.selected_slot = 0
        check(str(hover_game.tooltip_at(hover_game.UPGRADE_BUTTON.get_center())["mode"]) == "upgrade", "Upgrade tooltip follows relocated upgrade button")
        # Hover inspector is transient; selecting a tower must not pin a large HUD card.
        var tower_center: Vector2 = hover_game.slots[0]["pos"]
        var hover_info: Dictionary = hover_game.hovered_tower_info(tower_center)
        check(str(hover_info.get("kind", "")) == "bone", "Pointing at an occupied site opens its tower inspector")
        check(hover_game.hovered_tower_info(tower_center + Vector2(80, 0)).is_empty(), "Moving pointer away immediately hides tower inspector")
        check(hover_game.hovered_tower_info(hover_game.slots[1]["pos"]).is_empty(), "Empty building sites never show tower inspector")
        check(not hover_game.selected_tower_info().is_empty(), "Selected tower remains available for upgrade actions after hover leaves")
        var hover_rect: Rect2 = hover_game.tower_hover_panel_rect(Vector2(1110, 450))
        check(hover_rect.position.x >= 0.0 and hover_rect.end.x <= 1152.0 and hover_rect.position.y >= 0.0 and hover_rect.end.y < 545.0, "Hover inspector stays inside screen and above bottom shop")
        var shop_rect: Rect2 = hover_game.tower_tooltip_panel_rect(Vector2(1100, 600))
        check(shop_rect.position.x >= 0.0 and shop_rect.end.x <= 1152.0 and shop_rect.position.y >= 0.0 and shop_rect.end.y < 545.0, "Shop tooltip stays inside screen above bottom shop")
        hover_game.help_visible = true
        check(hover_game.hovered_tower_info(tower_center).is_empty(), "Help modal prevents tower hover inspector")
        hover_game.help_visible = false
        hover_game.specialization_open = true
        check(hover_game.hovered_tower_info(tower_center).is_empty(), "Specialization modal prevents tower hover inspector")
        hover_game.queue_free()
    for specialization_kind in ["bone", "fire", "necro", "frost"]:
        for path_name in ["siege", "swarm"]:
            var spec_tip: Dictionary = tooltip_data.specialization_info(specialization_kind, path_name, 2)
            check(not spec_tip.is_empty() and str(spec_tip["title"]) != "" and str(spec_tip["line1"]) != "" and str(spec_tip["line2"]) != "", "Specialization shows full description: " + specialization_kind + "/" + path_name)
            check(int(spec_tip["damage"]) > 0 and float(spec_tip["cooldown"]) > 0.0, "Specialization shows valid damage and cooldown: " + specialization_kind + "/" + path_name)
    if specialization_balance_scene != null:
        var specs_ui = specialization_balance_scene.instantiate()
        root.add_child(specs_ui)
        check(not specs_ui.SPECIALIZATION_BUTTONS[0].intersects(specs_ui.SPECIALIZATION_BUTTONS[1]), "Specialization action areas are separate")
        specs_ui.queue_free()
    if specialization_balance_scene != null:
        var fit_game = specialization_balance_scene.instantiate()
        root.add_child(fit_game)
        var left_card: Rect2 = fit_game.specialization_card_rect(0)
        var right_card: Rect2 = fit_game.specialization_card_rect(1)
        check(left_card.end.x < right_card.position.x, "Specialization comparison cards have non-overlapping text areas")
        for button_idx in range(2):
            var button: Rect2 = fit_game.SPECIALIZATION_BUTTONS[button_idx]
            check(fit_game.specialization_card_rect(button_idx).encloses(button), "Specialization button stays inside corresponding comparison card")
        fit_game.queue_free()
    if specialization_balance_scene != null:
        var selected_details = specialization_balance_scene.instantiate()
        root.add_child(selected_details)
        selected_details.slots[0]["tower"] = "frost"
        selected_details.slots[0]["level"] = 1
        selected_details.selected_slot = 0
        var info_before: Dictionary = selected_details.selected_tower_info()
        check(int(info_before["range"]) == 145 and is_equal_approx(float(info_before["attack_delay"]), 0.8), "Selected frost tower shows accurate range and normal attack interval")
        check(str(info_before["effect"]) != "", "Selected tower includes plain-language ability")
        selected_details.slots[0]["specialization"] = "swarm"
        var info_after: Dictionary = selected_details.selected_tower_info()
        check(is_equal_approx(float(info_after["attack_delay"]), 0.45), "Swarm tower inspector reflects faster attacks")
        selected_details.queue_free()
    var upgrade_tips = load("res://scripts/td/td_tower_tooltips.gd")
    for upgrade_kind in ["bone", "fire", "necro", "frost"]:
        var first: Dictionary = upgrade_tips.upgrade_info(upgrade_kind, 1, "", 0, 0)
        check(int(first["range"]) > 0 and is_equal_approx(float(first["attack_interval"]), 0.8), "Upgrade preview shows genuine range and interval: " + upgrade_kind)
        check("2 ПУТИ" in str(first["extra"]), "Level two upgrade explains specialization choice: " + upgrade_kind)
        var third: Dictionary = upgrade_tips.upgrade_info(upgrade_kind, 2, "swarm", 0, 0)
        check(is_equal_approx(float(third["attack_interval"]), 0.45) and "НЕ МЕНЯЮТСЯ" in str(third["extra"]), "Third-level preview preserves swarm attack cadence: " + upgrade_kind)
    var synergy_tooltips = load("res://scripts/td/td_tower_tooltips.gd")
    var bone_active: Array[String] = synergy_tooltips.synergy_lines("bone", true, false, true)
    check(bone_active.size() == 2 and bone_active[0].begins_with("АКТИВНО") and bone_active[1].begins_with("АКТИВНО"), "Bone tooltip marks active fire and frost combinations")
    var necro_inactive: Array[String] = synergy_tooltips.synergy_lines("necro", false, false, false)
    check(necro_inactive.size() == 3 and necro_inactive[0].begins_with("НУЖНЫ КОСТИ"), "Necro tooltip explains missing neighbours")
    check(synergy_tooltips.synergy_lines("frost", false, false, false).size() == 3, "Frost tooltip documents all three school pairings")
    check("3 врагов" in str(synergy_tooltips.shop_info("bone")["effect"]), "Bone tower tooltip truthfully describes up to three pierced enemies")
    # UI and real damage must share the same formula for every school/path/level.
    if specialization_balance_scene != null:
        var formula_game = specialization_balance_scene.instantiate()
        root.add_child(formula_game)
        formula_game.fire_synergy_bonus = 2
        formula_game.bone_synergy_bonus = 1
        for audit_kind in ["bone", "fire", "necro", "frost"]:
            for audit_level in range(1, 4):
                for audit_path in ["", "siege", "swarm"]:
                    if audit_level == 1 and audit_path != "":
                        continue
                    formula_game.slots[0]["tower"] = audit_kind
                    formula_game.slots[0]["level"] = audit_level
                    formula_game.slots[0]["specialization"] = audit_path
                    var ui_damage: int = int(formula_game.tower_info_for_slot(0)["damage"])
                    var combat_damage: int = formula_game.TD_TOWER_DAMAGE.direct_damage(audit_kind, audit_level, audit_path, 2, 1)
                    check(ui_damage == combat_damage, "Inspector damage matches combat for " + audit_kind + "/" + audit_path + " level " + str(audit_level))
        formula_game.queue_free()
    # Test damage actually applied during firing, not only preview helper values.
    if specialization_balance_scene != null:
        var combat_synergies: Array[Dictionary] = [
            {"tower": "bone", "partner": "fire", "status": "burn_time", "bonus": 2},
            {"tower": "fire", "partner": "bone", "status": "burn_time", "bonus": 1},
            {"tower": "necro", "partner": "bone", "status": "", "bonus": 1},
            {"tower": "necro", "partner": "fire", "status": "burn_time", "bonus": 1},
            {"tower": "bone", "partner": "frost", "status": "frost_time", "bonus": 1},
            {"tower": "fire", "partner": "frost", "status": "frost_time", "bonus": 1}
        ]
        for synergy_case in combat_synergies:
            var hit_game = specialization_balance_scene.instantiate()
            root.add_child(hit_game)
            hit_game.slots[0]["tower"] = str(synergy_case["tower"])
            hit_game.slots[0]["level"] = 1
            hit_game.slots[1]["tower"] = str(synergy_case["partner"])
            hit_game.slots[1]["level"] = 1
            # The partner contributes its proximity bonus, not an extra attack.
            hit_game.tower_cooldowns[1] = 99.0
            var tested_enemy: Dictionary = {"pos": hit_game.slots[0]["pos"] + Vector2(25, 0), "hp": 100, "delay": 0.0}
            if str(synergy_case["status"]) != "":
                tested_enemy[str(synergy_case["status"])] = 2.0
            hit_game.enemies.append(tested_enemy)
            var basic_hit: int = hit_game.TD_TOWER_DAMAGE.direct_damage(str(synergy_case["tower"]), 1, "", 0, 0)
            hit_game.attack_with_towers(0.01)
            check(int(tested_enemy["hp"]) == 100 - basic_hit - int(synergy_case["bonus"]), "Combat applies real pair bonus: " + str(synergy_case["tower"]) + "+" + str(synergy_case["partner"]))
            check(hit_game.tower_synergy_links(0).has(1) and hit_game.tower_synergy_links(1).has(0), "All combat synergies including frost draw reciprocal links")
            hit_game.slots[1]["tower"] = ""
            hit_game.tower_cooldowns[0] = 0.0
            hit_game.enemies.clear()
            var isolated_enemy: Dictionary = {"pos": hit_game.slots[0]["pos"] + Vector2(25, 0), "hp": 100, "delay": 0.0}
            if str(synergy_case["status"]) != "":
                isolated_enemy[str(synergy_case["status"])] = 2.0
            hit_game.enemies.append(isolated_enemy)
            hit_game.attack_with_towers(0.01)
            check(int(isolated_enemy["hp"]) == 100 - basic_hit, "Combat bonus vanishes when partner removed: " + str(synergy_case["tower"]) + "+" + str(synergy_case["partner"]))
            hit_game.queue_free()
    if specialization_balance_scene != null:
        var modal_tooltip_game = specialization_balance_scene.instantiate()
        root.add_child(modal_tooltip_game)
        check(modal_tooltip_game.tower_tooltips_available(), "Tower tooltips work in normal defense")
        modal_tooltip_game.wave_number = 3
        modal_tooltip_game.interwave_choice = ""
        modal_tooltip_game.enemies.clear()
        check(modal_tooltip_game.can_choose_interwave_event() and not modal_tooltip_game.tower_tooltips_available(), "Council hides shop and synergy hover panels")
        var coins_before_modal: int = modal_tooltip_game.coins
        modal_tooltip_game._unhandled_input(left_click_event(modal_tooltip_game.tower_shop_rect(0).get_center()))
        check(modal_tooltip_game.selected_type == "" and modal_tooltip_game.coins == coins_before_modal, "Council blocks shop interactions outside its own buttons")
        modal_tooltip_game.interwave_choice = "safe"
        check(modal_tooltip_game.tower_tooltips_available(), "Tower tooltips restore when council closes")
        modal_tooltip_game.queue_free()
    var synergy_scene = load("res://scenes/topdown_td_prototype.tscn")
    if synergy_scene != null:
        var synergy = synergy_scene.instantiate()
        root.add_child(synergy)
        synergy.slots[0]["tower"] = "bone"
        synergy.slots[1]["tower"] = "fire"
        var burning_foe := {"burn_time": 2.0}
        check(synergy.has_adjacent_tower(0, "fire"), "Adjacent fire tower activates bone synergy")
        check(synergy.tower_synergy_damage(0, burning_foe) == 2, "Bone gains damage against burning foe beside fire tower")
        check(synergy.tower_synergy_preview(0) == {"flat": 0, "burning": 2}, "Bone inspector identifies burning-only fire synergy")
        check(synergy.tower_synergy_damage(0, {"burn_time": 0.0}) == 0, "No bonus without burning")
        synergy.slots[1]["tower"] = ""
        check(synergy.tower_synergy_damage(0, burning_foe) == 0, "No bonus without nearby fire tower")
        synergy.slots[0]["tower"] = "fire"
        synergy.slots[1]["tower"] = "bone"
        check(synergy.tower_synergy_preview(0) == {"flat": 0, "burning": 1}, "Bone adjacency grants fire a conditional follow-up bonus")
        check(synergy.tower_synergy_damage(0, burning_foe) == 1, "Fire gets +1 direct damage on burning enemies near bone")
        check(synergy.tower_synergy_damage(0, {"burn_time": 0.0}) == 0, "Fire first hit stays unchanged before ignition")
        check(synergy.tower_synergy_links(0).has(1) and synergy.tower_synergy_links(1).has(0), "Fire-bone synergy link is reciprocal")
        synergy.slots[1]["tower"] = ""
        check(synergy.tower_synergy_preview(0) == {"flat": 0, "burning": 0}, "Fire loses bonus when bone moves away")
        synergy.slots[0]["tower"] = "necro"
        synergy.slots[1]["tower"] = "bone"
        check(synergy.tower_synergy_damage(0, burning_foe) == 1, "Nearby bone tower supports necromancer")
        var necro_preview: Dictionary = synergy.tower_synergy_preview(0)
        check(int(necro_preview["flat"]) == 1 and int(necro_preview["burning"]) == 0, "Necromancer inspector reports bone link as unconditional damage")

        synergy.slots[1]["tower"] = "fire"
        check(synergy.tower_synergy_links(0).has(1) and synergy.tower_synergy_links(1).has(0), "Nearby fire and necromancer towers show a reciprocal synergy link")
        check(synergy.tower_synergy_damage(0, burning_foe) == 1, "Necromancer gains one bonus damage against burning enemy near fire tower")
        necro_preview = synergy.tower_synergy_preview(0)
        check(int(necro_preview["flat"]) == 0 and int(necro_preview["burning"]) == 1, "Necromancer inspector distinguishes fire link as burning-only")
        synergy.selected_slot = 0
        var necro_info: Dictionary = synergy.selected_tower_info()
        check(int(necro_info["synergy_flat"]) == 0 and int(necro_info["synergy_burning"]) == 1, "Selected tower card uses the same bonuses as combat")

        check(synergy.tower_synergy_damage(0, {"burn_time": 0.0}) == 0, "Fire necromancy combo does not increase damage against normal targets")
        check(synergy.tower_synergy_preview(-1) == {"flat": 0, "burning": 0}, "Invalid slot never shows phantom synergy")
        synergy.slots[1]["tower"] = "bone"
        synergy.slots[2]["tower"] = "fire"
        check(synergy.tower_synergy_damage(0, burning_foe) == 1, "Distant fire tower does not provide extra burn bonus")
        synergy.slots[2]["tower"] = ""

        synergy.queue_free()
    var link_scene = load("res://scenes/topdown_td_prototype.tscn")
    if link_scene != null:
        var links_game = link_scene.instantiate()
        root.add_child(links_game)
        links_game.slots[0]["tower"] = "bone"
        links_game.slots[1]["tower"] = "fire"
        check(links_game.tower_synergy_links(0).has(1), "Selected bone tower highlights adjacent fire link")
        links_game.slots[1]["tower"] = "necro"
        check(links_game.tower_synergy_links(0).has(1), "Bone highlights nearby necromancer support")
        links_game.slots[1]["tower"] = ""
        check(links_game.tower_synergy_links(0).is_empty(), "No synergy link for empty neighbor")
        links_game.queue_free()
    var scouting_scene = load("res://scenes/topdown_td_prototype.tscn")
    if scouting_scene != null:
        var scouting = scouting_scene.instantiate()
        root.add_child(scouting)
        check("ПЕХОТА" in scouting.upcoming_wave_summary(), "First wave scouting warns about infantry")
        scouting.wave_number = 1
        check("БЕГУНЫ" in scouting.upcoming_wave_summary(), "Second wave scouting warns about runners")
        scouting.wave_number = 2
        check("НАТИСК" in scouting.upcoming_wave_summary(), "Third wave scouting warns about armored pressure")
        scouting.queue_free()
    var healer_scene = load("res://scenes/topdown_td_prototype.tscn")
    if healer_scene != null:
        var healer_game = healer_scene.instantiate()
        root.add_child(healer_game)
        healer_game.wave_number = 1
        check(healer_game.start_wave(), "Second wave with supporting healer starts")
        var supporting_healer: Dictionary = {}
        var damaged_ally: Dictionary = {}
        for foe in healer_game.enemies:
            if str(foe.get("role", "")) == "healer":
                supporting_healer = foe
            elif damaged_ally.is_empty():
                damaged_ally = foe
        check(not supporting_healer.is_empty(), "Second wave spawns a support healer")
        if not supporting_healer.is_empty() and not damaged_ally.is_empty():
            supporting_healer["delay"] = 0.0
            damaged_ally["delay"] = 0.0
            damaged_ally["pos"] = supporting_healer["pos"] + Vector2(40, 0)
            damaged_ally["hp"] = int(damaged_ally["max_hp"]) - 2
            var before_healing: int = int(damaged_ally["hp"])
            healer_game.tick_support_enemies(1.1)
            check(int(damaged_ally["hp"]) > before_healing, "Support healer restores injured ally")
            check(int(damaged_ally["hp"]) <= int(damaged_ally["max_hp"]), "Healer cannot exceed maximum HP")
        healer_game.queue_free()
    var priority_scene = load("res://scenes/topdown_td_prototype.tscn")
    if priority_scene != null:
        var priority_game = priority_scene.instantiate()
        root.add_child(priority_game)
        priority_game.choose_tower("bone")
        check(priority_game.build_tower(0), "Priority tower is built")
        priority_game.enemies.clear()
        var origin: Vector2 = priority_game.slots[0]["pos"]
        var grunt := {"pos": origin + Vector2(20, 0), "role": "grunt", "hp": 9, "delay": 0.0}
        var healer := {"pos": origin + Vector2(90, 0), "role": "healer", "hp": 9, "delay": 0.0}
        priority_game.enemies.append(grunt)
        priority_game.enemies.append(healer)
        check(priority_game.choose_tower_target(0) == grunt, "Nearest policy targets closest enemy")
        check(priority_game.cycle_target_priority(), "Tower target policy cycles with mouse button action")
        check(priority_game.choose_tower_target(0) == healer, "Support policy prioritizes healer in range")
        priority_game.cycle_target_priority()
        check(priority_game.choose_tower_target(0) == healer, "Front policy targets enemy closest to gates")
        healer["delay"] = 3.0
        check(priority_game.choose_tower_target(0) == grunt, "Unavailable support enemies are ignored")
        var priority_save: Dictionary = priority_game.export_fortress_state()
        var restored_priority = priority_scene.instantiate()
        root.add_child(restored_priority)
        check(restored_priority.import_fortress_state(priority_save), "Targeting priority survives day transition")
        check(restored_priority.slots[0]["target_priority"] == "front", "Selected target policy persists")
        priority_game.queue_free()
        restored_priority.queue_free()
    var repair_scene = load("res://scenes/topdown_td_prototype.tscn")
    if repair_scene != null:
        var repairs = repair_scene.instantiate()
        root.add_child(repairs)
        repairs.altar_hp = 65
        repairs.coins = 50
        check(repairs.repair_altar(), "Repair works between waves")
        check(repairs.altar_hp == 85 and repairs.coins == 25, "Repair spends 25 gold for 20 altar health")
        check(repairs.repair_altar(), "Second repair works when funds remain")
        check(repairs.altar_hp == 100 and repairs.coins == 0, "Repair health is capped at 100")
        check(not repairs.repair_altar(), "Cannot repair fully healed altar")
        repairs.altar_hp = 40
        repairs.coins = 100
        repairs.enemies.append({"role": "grunt"})
        check(not repairs.repair_altar(), "Cannot repair during active enemy wave")
        repairs.enemies.clear()
        repairs.wave_number = 6
        check(not repairs.repair_altar(), "Cannot repair after final wave")
        repairs.queue_free()
    var relocation_scene = load("res://scenes/topdown_td_prototype.tscn")
    if relocation_scene != null:
        var layout = relocation_scene.instantiate()
        root.add_child(layout)
        layout.choose_tower("fire")
        check(layout.build_tower(0), "Build tower for relocation")
        layout.coins = 100
        layout.select_slot(0)
        check(layout.upgrade_selected(), "Tower upgrades before relocation")
        check(layout.choose_specialization("siege"), "Tower chooses specialization before relocation")
        layout.cycle_target_priority()
        var coins_before: int = layout.coins
        check(layout.begin_tower_relocation(), "Relocation can begin between waves")
        check(layout.relocate_tower(0, 4), "Relocation moves tower to empty position")
        check(layout.slots[0]["tower"] == "" and layout.slots[4]["tower"] == "fire", "Source is empty, destination keeps tower")
        check(layout.slots[4]["level"] == 2 and layout.slots[4]["specialization"] == "siege", "Relocated tower keeps upgrades")
        check(layout.slots[4]["target_priority"] == "support" and layout.coins == coins_before, "Relocation keeps target priority and coins")
        check(not layout.relocate_tower(4, 4), "Relocation cannot move into occupied position")
        var transfer: Dictionary = layout.export_fortress_state()
        var following_day = relocation_scene.instantiate()
        root.add_child(following_day)
        check(following_day.import_fortress_state(transfer), "Relocated layout survives day transition")
        check(following_day.slots[4]["tower"] == "fire" and following_day.slots[0]["tower"] == "", "Tower stays in relocated slot")
        layout.enemies.append({"role": "grunt"})
        check(not layout.relocate_tower(4, 5), "Cannot move tower during attack")
        layout.queue_free()
        following_day.queue_free()
    var scenario_scene = load("res://scenes/topdown_td_prototype.tscn")
    if scenario_scene != null:
        var raid = scenario_scene.instantiate()
        root.add_child(raid)
        raid.siege_day = 2
        check("НАЛЁТ" in raid.upcoming_wave_summary(), "Second day warns of fast raid")
        check(raid.start_wave(), "Second day assault starts")
        check(raid.enemies.size() == 4, "Swift raid adds an attacker to first wave")
        var runner_count := 0
        for foe in raid.enemies:
            if foe["role"] == "runner":
                runner_count += 1
        check(runner_count >= 2, "Swift raid fields more runners")
        raid.queue_free()
        var siege = scenario_scene.instantiate()
        root.add_child(siege)
        siege.siege_day = 3
        check("ОСАДА" in siege.upcoming_wave_summary(), "Third day warns of armored siege")
        check(siege.start_wave(), "Third day siege starts")
        var brute_count := 0
        for foe in siege.enemies:
            if foe["role"] == "brute":
                brute_count += 1
        check(brute_count >= 2, "Armored siege fields more brutes")
        siege.queue_free()
    var inspector_scene = load("res://scenes/topdown_td_prototype.tscn")
    if inspector_scene != null:
        var inspector = inspector_scene.instantiate()
        root.add_child(inspector)
        check(inspector.selected_tower_info().is_empty(), "Tower detail card hidden without selected tower")
        inspector.choose_tower("bone")
        check(inspector.build_tower(0), "Build tower for detail card")
        var details: Dictionary = inspector.selected_tower_info()
        check(details["kind"] == "bone" and int(details["level"]) == 1, "Card shows tower type and level")
        check(int(details["upgrade_cost"]) == 20, "Card shows upgrade price")
        inspector.coins = 80
        inspector.upgrade_selected()
        inspector.choose_specialization("siege")
        details = inspector.selected_tower_info()
        check(details["specialization"] == "siege" and int(details["damage"]) > 0, "Card updates with specialization and damage")
        inspector.queue_free()
    var silhouettes_scene = load("res://scenes/topdown_td_prototype.tscn")
    if silhouettes_scene != null:
        var silhouettes = silhouettes_scene.instantiate()
        root.add_child(silhouettes)
        check(silhouettes.enemy_visual_profile("runner")["mark"] == "speed", "Runner has a distinct speed silhouette")
        check(silhouettes.enemy_visual_profile("brute")["mark"] == "armor", "Brute has a distinct armored silhouette")
        check(silhouettes.enemy_visual_profile("healer")["mark"] == "heal", "Healer has a readable cross marker")
        check(silhouettes.enemy_visual_profile("boss")["mark"] == "boss", "Boss silhouette is distinct")
        check(float(silhouettes.enemy_visual_profile("boss")["radius"]) > float(silhouettes.enemy_visual_profile("grunt")["radius"]), "Boss silhouette remains visually largest")
        silhouettes.queue_free()
    var visual_scene = load("res://scenes/topdown_td_prototype.tscn")
    if visual_scene != null:
        var visuals = visual_scene.instantiate()
        root.add_child(visuals)
        check(visuals.tower_visual_color("bone") != visuals.tower_visual_color("fire"), "Bone and fire tower attacks use distinguishable colors")
        check(visuals.tower_visual_color("fire") != visuals.tower_visual_color("necro"), "Fire and necro tower attacks use distinguishable colors")
        visuals.choose_tower("fire")
        check(visuals.build_tower(0), "Fire tower builds for visual trail test")
        visuals.enemies.append({"lane": 0, "pos": visuals.slots[0]["pos"] + Vector2(30, 0), "waypoint": 1, "hp": 100, "delay": 0.0})
        visuals.attack_with_towers(1.0)
        check(not visuals.shot_trails.is_empty() and visuals.shot_trails[0].get("kind", "") == "fire", "Tower projectile records correct visual kind")
        visuals.queue_free()
    var scenery_scene = load("res://scenes/topdown_td_prototype.tscn")
    if scenery_scene != null:
        var scenery = scenery_scene.instantiate()
        root.add_child(scenery)
        check(scenery.fortress_altar_center() == Vector2(1041, 314), "Altar artwork remains anchored at original objective location")
        check(scenery.fortress_altar_center().x > 900.0, "Altar artwork stays on defended east side")
        scenery.queue_free()
    # Different difficulties must demand different tower strategies, not just extra HP.
    var difficulty_scene = load("res://scenes/topdown_td_prototype.tscn")
    if difficulty_scene != null:
        var encounter_probe = difficulty_scene.instantiate()
        root.add_child(encounter_probe)
        encounter_probe.difficulty = 0
        check(encounter_probe.siege_enemy_role(1, 0) == "grunt" and encounter_probe.siege_enemy_role(1, 1) == "grunt", "Normal opening wave retains accessible grunts")
        encounter_probe.difficulty = 1
        check(encounter_probe.siege_enemy_role(1, 0) == "grunt" and encounter_probe.siege_enemy_role(1, 1) == "runner", "Hard opening wave introduces a fast enemy")
        encounter_probe.difficulty = 2
        check(encounter_probe.siege_enemy_role(1, 0) == "brute" and encounter_probe.siege_enemy_role(1, 1) == "runner", "Nightmare opening wave mixes armor and speed")
        check(encounter_probe.start_wave(), "Nightmare first wave can start")
        check(encounter_probe.enemies[0]["role"] == "brute" and encounter_probe.enemies[1]["role"] == "runner", "Spawned enemies follow selected difficulty composition")
        encounter_probe.difficulty = 0
        encounter_probe.siege_day = 2
        check(encounter_probe.siege_enemy_role(2, 0) == "runner", "Day two still features raiders on Normal")
        encounter_probe.siege_day = 3
        check(encounter_probe.siege_enemy_role(2, 0) == "brute", "Day three still features armor on Normal")
        encounter_probe.queue_free()
    # Tower economy transactions are allowed only during preparation.
    var economy_scene = load("res://scenes/topdown_td_prototype.tscn") as PackedScene
    if economy_scene != null:
        var economy_probe = economy_scene.instantiate()
        root.add_child(economy_probe)
        check(economy_probe.can_modify_towers(), "Tower purchases allowed before the first wave")
        economy_probe.choose_tower("bone")
        check(economy_probe.build_tower(0), "Economy probe buys initial tower")
        economy_probe.coins = 200
        economy_probe.select_slot(0)
        check(economy_probe.start_wave(), "Economy probe starts combat")
        var locked_coins: int = economy_probe.coins
        var locked_level: int = int(economy_probe.slots[0]["level"])
        economy_probe.choose_tower("necro")
        check(not economy_probe.can_modify_towers(), "Combat suspends all tower transactions")
        check(not economy_probe.build_tower(1), "Cannot purchase a tower while enemies are present")
        economy_probe.select_slot(0)
        check(not economy_probe.upgrade_selected() and not economy_probe.sell_selected(), "Cannot upgrade or sell a selected tower during combat")
        check(economy_probe.coins == locked_coins and economy_probe.slots[0]["level"] == locked_level and economy_probe.slots[0]["tower"] == "bone", "Rejected combat transactions preserve gold and towers")
        economy_probe.enemies.clear()
        check(economy_probe.can_modify_towers(), "Building resumes between waves")
        economy_probe.choose_tower("necro")
        check(economy_probe.build_tower(1), "Building is possible after wave cleared")
        economy_probe.select_slot(0)
        check(economy_probe.upgrade_selected(), "Upgrading is possible between waves")
        check(not economy_probe.can_modify_towers() and not economy_probe.sell_selected(), "Specialization choice cannot be skipped by selling or another upgrade")
        check(economy_probe.choose_specialization("siege") and economy_probe.can_modify_towers(), "Finishing specialization restores preparations")
        economy_probe.wave_number = 6
        check(not economy_probe.can_modify_towers() and not economy_probe.sell_selected(), "Completed final wave locks the economy")
        economy_probe.defense_state = "lost"
        economy_probe.wave_number = 1
        check(not economy_probe.can_modify_towers() and not economy_probe.upgrade_selected(), "Defeat locks tower economy")
        economy_probe.queue_free()
    var td_scene := load("res://scenes/topdown_td_prototype.tscn") as PackedScene
    check(td_scene != null, "Top-down TD scene loads")
    if td_scene != null:
        var td = td_scene.instantiate()
        root.add_child(td)
        check(td.sfx != null and td.sfx.has_effect("interrupt") and td.sfx.has_effect("blast"), "TD prototype loads boss combat audio effects")
        check(td.HELP_BUTTON.has_point(Vector2(1040, 35)) and not td.HELP_BUTTON.intersects(td.WAVE_BUTTON), "TD mouse help button stays separate from wave control")
        td._unhandled_input(left_click_event(td.HELP_BUTTON.get_center()))
        check(td.help_visible, "Mouse opens TD help overlay")
        td._unhandled_input(left_click_event(td.WAVE_BUTTON.get_center()))
        check(td.help_visible and td.wave_number == 0, "TD help blocks wave starts underneath")
        td._unhandled_input(left_click_event(td.HELP_CLOSE_BUTTON.get_center()))
        check(not td.help_visible, "Mouse Continue closes TD help")
        td.toggle_controls_help()
        var td_wave_before_help: int = td.wave_number
        td._process(1.0)
        check(td.help_visible and td.wave_number == td_wave_before_help, "TD controls help pauses the defense simulation")
        td.toggle_controls_help()
        check(not td.help_visible, "TD controls help closes cleanly")
        check(not td.sfx.play_effect("unknown"), "Audio helper rejects unknown effects safely")
        check(td.slots.size() == 8, "TD has eight fixed construction slots")
        for lane in td.paths:
            check(lane.size() >= 7, "Fortress route has multiple meaningful bends")
            for segment_index in range(1, lane.size()):
                check(lane[segment_index].distance_to(lane[segment_index - 1]) > 10.0, "Route has no duplicate adjacent waypoints")
            for slot in td.slots:
                var clearance := INF
                for segment_index in range(1, lane.size()):
                    var a: Vector2 = lane[segment_index - 1]
                    var b: Vector2 = lane[segment_index]
                    var t: float = clampf((slot["pos"] - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
                    clearance = minf(clearance, slot["pos"].distance_to(a.lerp(b, t)))
                check(clearance >= 42.0, "Tower slots stay outside road corridor")
        var first_lane: Array = td.paths[0]
        var first_direction: Vector2 = (first_lane[1] - first_lane[0]).normalized()
        check((first_lane[3] - first_lane[2]).normalized().distance_to(first_direction) > 0.2, "Upper lane is not straight")
        var second_lane: Array = td.paths[1]
        check((second_lane[3] - second_lane[2]).normalized().distance_to((second_lane[1] - second_lane[0]).normalized()) > 0.2, "Lower lane is not straight")
        td.enemies.append({"lane": 0, "pos": first_lane[0], "waypoint": 1, "hp": 999, "speed": 85.0, "delay": 0.0})
        td.advance_enemies(8.0)
        check(td.enemies[0]["waypoint"] > 3, "Movement consumes several waypoints per long frame")
        td.enemies.clear()

        check(td.slot_at(Vector2(0, 0)) == -1, "No construction slot outside designated areas")
        check(td.choose_tower("bone"), "Select bone tower")
        check(not td.build_tower(-1), "Cannot build off slot")
        check(td.build_tower(0) and td.coins == 120, "Build bone tower at fixed slot")
        check(not td.build_tower(0), "Occupied slot rejects duplicate building")
        check(td.choose_tower("necro") and td.build_tower(1), "Different tower uses its own build slot")
        check(td.select_slot(0) and td.upgrade_selected(), "Click selected tower to upgrade")
        check(td.choose_specialization("siege"), "Choose specialization before selling the upgraded tower")
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
        check(td.enemies[0]["role"] == "runner" and td.enemies[1]["role"] == "brute", "Second wave mixes runners and brutes")
        check(float(td.enemies[0]["speed"]) > float(td.enemies[1]["speed"]) and int(td.enemies[0]["hp"]) < int(td.enemies[1]["hp"]), "Runner is faster but weaker than brute")
        td.enemies.clear()
        check(td.start_wave() and td.wave_number == 3, "TD third wave starts")
        td.enemies.clear()
        for wave_index in range(4, 7):
            check(td.start_wave() and td.wave_number == wave_index, "TD extended siege wave %d starts" % wave_index)
            if wave_index < 6:
                td.enemies.clear()
        var boss: Dictionary = {}
        for enemy in td.enemies:
            if enemy.get("role", "") == "boss":
                boss = enemy
        check(not boss.is_empty() and boss["hp"] == 55, "Sixth wave has a durable altar boss")
        if not boss.is_empty():
            boss["delay"] = 0.0
            var altar_before_blast: int = td.altar_hp
            td.tick_boss(3.2)
            check(boss["boss_warning"] and td.altar_hp == altar_before_blast, "Boss telegraphs attack without immediate altar damage")
            td.tick_boss(0.9)
            check(not boss["boss_warning"] and td.altar_hp == altar_before_blast - 8, "Boss blast damages altar after warning")
            check(td.boss_feedback_time > 0.0 and td.boss_feedback_text.begins_with("АЛТАРЬ ПОВРЕЖДЁН!"), "Altar blast shows temporary damage notice")
            boss["pos"] = Vector2(350, 285)
            td.hero_pos = Vector2(345, 360)
            td.tick_boss(3.2)
            var altar_before_interrupt: int = td.altar_hp
            td.hero_attack_cooldown = 0.0
            check(td.hero_attack(boss["pos"]) and boss["interrupt_hits"] == 1, "First hero strike pressures boss during telegraph")
            td.hero_attack_cooldown = 0.0
            check(td.hero_attack(boss["pos"]) and not boss["boss_warning"] and boss["boss_charge"] == 0.0, "Second hero strike interrupts boss blast")
            check(td.boss_feedback_time > 0.0 and td.boss_feedback_text == "АТАКА ПРЕРВАНА!", "Interrupted boss blast shows readable confirmation")
            td.tick_boss(0.9)
            check(td.altar_hp == altar_before_interrupt, "Interrupted blast does not damage altar")
            td.tick_boss(2.2)
            check(boss["boss_warning"] and boss["interrupt_hits"] == 0, "Boss can charge again after interrupt")
        td.enemies.clear()
        check(not td.start_wave(), "TD stops at six waves")
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
        check(td.boss_feedback_time == 0.0 and td.boss_feedback_text == "" and td.summoned_spirits.is_empty(), "Defense restart clears boss feedback and necro summons")
        check(td.defense_state == "playing" and td.wave_number == 0 and td.altar_hp == 100, "TD restart resets wave and altar")
        check(td.slots[0]["tower"] == "" and td.coins == 150, "TD restart clears towers and restores economy")
        td.wave_number = 6
        td.enemies.clear()
        td._process(0.0)
        check(td.defense_state == "won", "TD victory after final cleared wave")
        check(not td.start_wave(), "TD victory blocks further waves")
        td.restart_defense()
        td.altar_hp = 10
        td.enemies.append({"lane": 0, "pos": td.paths[0][td.paths[0].size() - 1], "waypoint": td.paths[0].size() - 1, "hp": 1, "delay": 0.0})
        td.advance_enemies(0.01)
        check(td.defense_state == "lost" and td.altar_hp == 0, "TD altar defeat ends defense")
        check(not td.start_wave(), "TD defeat blocks more waves")
        td.restart_defense()
        check(td.defense_state == "playing" and td.altar_hp == 100 and td.enemies.is_empty(), "TD restart after defeat succeeds")
        td.queue_free()
    var meta_script = load("res://scripts/meta_progression.gd")
    check(meta_script != null, "Versioned meta progression script loads")
    if meta_script != null:
        var profile = meta_script.new()
        profile.save_path = "user://last_ritual_meta_smoke_test.json"
        if FileAccess.file_exists(profile.save_path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(profile.save_path))
        check(not profile.load_profile(), "Missing profile starts with defaults")
        check(profile.award(3) and profile.buy_upgrade("hero") and profile.buy_upgrade("treasury"), "Fragments purchase both permanent upgrades")
        check(profile.fragments == 1 and profile.hero_level == 1 and profile.treasury_level == 1, "Upgrade costs consume fragments")
        check(profile.save_profile(), "Versioned meta profile saves")
        var restored = meta_script.new()
        restored.save_path = profile.save_path
        check(restored.load_profile() and restored.fragments == 1 and restored.hero_level == 1 and restored.treasury_level == 1, "Meta upgrades persist across instances")
        check(not restored.buy_upgrade("hero") and not restored.buy_upgrade("invalid"), "Meta rejects unaffordable and unknown upgrades")
        check(not restored.achievement_unlocked("first_steps"), "Fresh profile starts with locked achievements")
        restored.record_start()
        restored.record_phase_clear()
        check(restored.achievement_unlocked("first_steps") and not restored.achievement_unlocked("survivor"), "First clear unlocks only the first achievement")
        check(restored.fragments == 3 and restored.claimed_achievement_rewards.has("first_steps"), "First achievement grants two fragments once")
        for i in range(5):
            restored.record_phase_clear()
        restored.record_result(true)
        check(restored.achievement_unlocked("survivor") and restored.achievement_unlocked("ritual_master"), "Six clears and win unlock milestones")
        check(restored.fragments == 13 and restored.claimed_achievement_rewards.size() == 3, "Achievement milestones grant 2, 4 and 6 fragments")
        check(restored.grant_achievement_rewards().is_empty() and restored.fragments == 13, "Achievement rewards cannot be claimed twice")
        check(restored.save_profile(), "Statistics persist in profile")
        var stats_copy = meta_script.new()
        stats_copy.save_path = profile.save_path
        check(stats_copy.load_profile() and stats_copy.runs_started == 1 and stats_copy.runs_won == 1 and stats_copy.runs_lost == 0 and stats_copy.phases_cleared == 6, "Run statistics restore from disk")
        check(stats_copy.fragments == 13 and stats_copy.claimed_achievement_rewards.size() == 3, "Achievement rewards persist across reloads")
        check(stats_copy.grant_achievement_rewards().is_empty(), "Reloaded achievement rewards remain claimed")
        stats_copy.record_start()
        stats_copy.record_result(false)
        check(stats_copy.runs_lost == 1, "Defeats are tracked separately")
        var legacy = meta_script.new()
        legacy.save_path = "user://last_ritual_legacy_smoke.json"
        var legacy_file := FileAccess.open(legacy.save_path, FileAccess.WRITE)
        if legacy_file != null:
            legacy_file.store_string(JSON.stringify({"version": 1, "fragments": 2, "hero_level": 1, "treasury_level": 0}))
            legacy_file.close()
        check(legacy.load_profile() and legacy.runs_started == 0 and legacy.phases_cleared == 0, "Old version-one saves load with zero statistics")
        DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy.save_path))
        var milestone_legacy = meta_script.new()
        milestone_legacy.save_path = "user://last_ritual_legacy_milestones_smoke.json"
        var milestone_file := FileAccess.open(milestone_legacy.save_path, FileAccess.WRITE)
        if milestone_file != null:
            milestone_file.store_string(JSON.stringify({"version": 1, "fragments": 2, "hero_level": 1, "treasury_level": 0, "runs_started": 1, "runs_won": 0, "runs_lost": 0, "phases_cleared": 6}))
            milestone_file.close()
        check(milestone_legacy.load_profile() and milestone_legacy.claimed_achievement_rewards.is_empty(), "Legacy saves without reward claims remain compatible")
        milestone_legacy.record_result(true)
        check(milestone_legacy.fragments == 14 and milestone_legacy.claimed_achievement_rewards.size() == 3, "Legacy milestones receive each one-time reward")
        check(milestone_legacy.save_profile(), "Legacy milestone rewards save successfully")
        var milestone_copy = meta_script.new()
        milestone_copy.save_path = milestone_legacy.save_path
        check(milestone_copy.load_profile() and milestone_copy.grant_achievement_rewards().is_empty() and milestone_copy.fragments == 14, "Legacy reward claims do not duplicate after reload")
        DirAccess.remove_absolute(ProjectSettings.globalize_path(milestone_legacy.save_path))
        restored.award(20)
        check(restored.buy_upgrade("hero") and restored.buy_upgrade("hero") and not restored.buy_upgrade("hero"), "Permanent upgrade obeys level cap")
        DirAccess.remove_absolute(ProjectSettings.globalize_path(profile.save_path))
    var hard_td_scene := load("res://scenes/topdown_td_prototype.tscn") as PackedScene
    if hard_td_scene != null:
        var hard_td = hard_td_scene.instantiate()
        root.add_child(hard_td)
        hard_td.difficulty = 2
        check(hard_td.start_wave() and hard_td.enemies[0]["role"] == "brute" and hard_td.enemies[0]["hp"] == 12 and float(hard_td.enemies[0]["speed"]) > 55.0 and hard_td.enemies[1]["role"] == "runner" and float(hard_td.enemies[1]["speed"]) > 135.0, "Nightmare TD opening wave has durable armor and fast runner")
        hard_td.wave_number = 5
        hard_td.enemies.clear()
        check(hard_td.start_wave() and hard_td.enemies.back()["role"] == "boss" and hard_td.enemies.back()["hp"] == 85, "Nightmare boss gains durability")
        hard_td.enemies.clear()
        hard_td.queue_free()
    # Crypt tactics change by preset, without spawning extra enemies or hiding threats.
    var tactics_scene = load("res://scenes/topdown_night_prototype.tscn") as PackedScene
    if tactics_scene != null:
        var tactics_probe = tactics_scene.instantiate()
        root.add_child(tactics_probe)
        tactics_probe.difficulty = 0
        tactics_probe.open_room(0, 0)
        check(tactics_probe.enemies.size() == 2 and tactics_probe.enemies[0]["role"] == "regular", "Normal crypt keeps one melee and one ranged enemy")
        tactics_probe.difficulty = 1
        tactics_probe.open_room(0, 0)
        check(tactics_probe.enemies.size() == 2 and tactics_probe.enemies[0]["role"] == "flanker" and tactics_probe.enemies[1]["ranged"], "Hard crypt introduces flanker while keeping ranged pressure")
        check(tactics_probe.enemies[0]["hp"] == 5 and float(tactics_probe.enemies[0]["speed"]) > 100.0, "Hard flanker receives existing difficulty scaling")
        tactics_probe.difficulty = 2
        tactics_probe.open_room(0, 0)
        check(tactics_probe.enemies.size() == 2 and tactics_probe.enemies[0]["role"] == "champion" and tactics_probe.enemies[1]["ranged"], "Nightmare crypt introduces armored champion and ranged unit")
        check(tactics_probe.enemies[0]["hp"] == 10, "Nightmare crypt armor has predictable durability")
        var encounter_snapshot: Array = tactics_probe.enemies.duplicate(true)
        tactics_probe.open_room(0, 0)
        check(tactics_probe.enemies == encounter_snapshot, "Crypt encounters stay deterministic across identical retries")
        tactics_probe.queue_free()
    var hard_night_scene := load("res://scenes/topdown_night_prototype.tscn") as PackedScene
    if hard_night_scene != null:
        var hard_night = hard_night_scene.instantiate()
        root.add_child(hard_night)
        hard_night.difficulty = 1
        hard_night.open_room(0)
        check(hard_night.enemies[0]["hp"] == 5 and float(hard_night.enemies[0]["speed"]) > 65.0, "Hard night enemies get boosted HP and movement")
        hard_night.queue_free()
    var run_scene := load("res://scenes/run_loop.tscn") as PackedScene
    if run_scene != null:
        check(run_scene != null, "Unified day-night run scene loads")
        var layout_probe = run_scene.instantiate()
        check(layout_probe.DIFFICULTY_BUTTONS.size() == 3 and layout_probe.START_RUN_BUTTON.position.y > layout_probe.DIFFICULTY_BUTTONS[0].end.y, "Difficulty and single start button have vertical separation")
        check(layout_probe.REWARD_BUTTONS.size() == 4 and layout_probe.REWARD_BUTTONS[0].position.x < layout_probe.REWARD_BUTTONS[3].position.x, "Relic reward cards are ordered from left to right")
        check(not layout_probe.REWARD_BUTTONS[0].intersects(layout_probe.REWARD_BUTTONS[1]) and not layout_probe.REWARD_BUTTONS[2].intersects(layout_probe.REWARD_BUTTONS[3]), "Reward cards are spaced without overlap")
        check(layout_probe.META_HERO_BUTTON.position.y >= 474 and layout_probe.META_TREASURY_BUTTON.position.y >= 474, "Permanent upgrades sit in lower hub panel")
        check(not layout_probe.META_HERO_BUTTON.intersects(layout_probe.META_TREASURY_BUTTON), "Permanent upgrade cards do not overlap")
        check(layout_probe.AUDIO_MUTE_BUTTON.intersects(Rect2(72, 32, 1008, 112)) and not layout_probe.AUDIO_MUTE_BUTTON.intersects(layout_probe.AUDIO_UP_BUTTON), "Audio controls fit in the header without overlap")
        root.add_child(layout_probe)
        var original_audio_volume: float = layout_probe.audio_volume
        var original_audio_muted: bool = layout_probe.audio_muted
        layout_probe.audio_settings_path = "user://last_ritual_audio_smoke.cfg"
        layout_probe.audio_volume = 0.4
        layout_probe.audio_muted = true
        check(layout_probe.save_audio_settings(), "Audio settings save to config")
        layout_probe.apply_audio_settings()
        var audio_reload = run_scene.instantiate()
        root.add_child(audio_reload)
        audio_reload.audio_settings_path = layout_probe.audio_settings_path
        audio_reload.load_audio_settings()
        check(is_equal_approx(audio_reload.audio_volume, 0.4) and audio_reload.audio_muted, "Audio volume and mute restore from config")
        check(audio_reload.adjust_audio_volume(0.1) and is_equal_approx(audio_reload.audio_volume, 0.5), "Audio volume adjusts in ten-percent steps")
        audio_reload.toggle_audio_mute()
        check(not audio_reload.audio_muted, "Mute button toggles audio back on")
        audio_reload.load_audio_settings()
        check(is_equal_approx(audio_reload.audio_volume, 0.5) and not audio_reload.audio_muted, "Changed audio settings persist")
        audio_reload.audio_volume = original_audio_volume
        audio_reload.audio_muted = original_audio_muted
        audio_reload.apply_audio_settings()
        DirAccess.remove_absolute(ProjectSettings.globalize_path("user://last_ritual_audio_smoke.cfg"))
        audio_reload.queue_free()
        layout_probe.queue_free()
    check(run_scene != null, "Unified day-night run scene loads")
    if run_scene != null:
        var run = run_scene.instantiate()
        root.add_child(run)
        check(run.phase == "hub", "Run opens a single new-run menu")
        check(not run.set_difficulty(-1) and not run.set_difficulty(3), "Invalid difficulty rejected")
        check(run.set_difficulty(2) and run.difficulty == 2, "Nightmare difficulty selectable from hub")
        check(run.set_difficulty(0), "Normal difficulty selectable from hub")
        check(run.expected_phase() == "day" and not run.start_phase("night"), "Run requires day as first phase")
        check(run.start_run() and run.phase == "day", "One button starts the first day")
        check(not run.set_difficulty(2), "Difficulty cannot be changed during a run")
        check(not run.start_phase("day"), "Cannot restart active phase to duplicate run starts")
        run.finish_phase(true)
        check(run.phase == "transition" and run.completed_phases == 1, "Winning day begins dusk transition")
        check(not run.start_phase("day"), "Cannot manually select day during dusk")
        run._process(run.TRANSITION_DURATION + 0.1)
        check(run.phase == "night", "Dusk timer opens night automatically without a button")
        check(run.active_game != null and run.expected_phase() == "night", "Night scene opens without menu selection")
        var fragments_once: int = run.meta.fragments
        run.finish_phase(true)
        check(run.phase == "reward" and run.completed_phases == 2, "Winning night opens reward choice")
        check(run.meta.fragments > fragments_once, "Night rewards fragments")
        check(run.choose_run_reward("bone") and run.run_damage_bonus == 1, "Night relic persists damage bonus")
        check(run.phase == "transition" and run.phase_count == 2, "Selecting relic begins dawn transition")
        check(run.complete_transition() and run.phase == "day", "Dawn opens next day without a button")
        check(run.active_game.siege_day == 2, "Automatic next day receives correct siege scenario")
        check(not run.set_difficulty(2) and not run.start_run(), "Cannot restart run or change difficulty in combat")
        run.finish_phase(true)
        check(run.phase == "transition" and run.complete_transition(), "Second dusk transition reaches the night")
        check(run.phase == "night" and run.active_game.attack_damage >= 2, "Second night inherits damage relic")
        run.finish_phase(true)
        check(run.phase == "reward" and run.expected_phase() == "day", "Night rewards precede the next day")
        check(run.choose_run_reward("ember") and run.run_fire_bonus == 1, "Ember reward enables fire tower bonus")
        check(run.phase == "transition" and run.complete_transition(), "Second dawn transition starts day three")
        check(run.phase == "day" and run.active_game.fire_synergy_bonus == 1 and run.active_game.bone_synergy_bonus == 1, "Next day inherits both relic effects")
        check(run.active_game.siege_day == 3, "Automatic third day uses armored scenario")
        var td = run.active_game
        td.coins = 100
        td.choose_tower("fire")
        td.build_tower(0)
        td.enemies.clear()
        td.enemies.append({"lane": 0, "pos": td.slots[0]["pos"] + Vector2(20, 0), "waypoint": 1, "hp": 5, "delay": 0.0})
        td.attack_with_towers(1.0)
        check(td.enemies[0]["hp"] == 3 and td.enemies[0].has("burn_time"), "Fire tower applies burn after direct hit")
        td.tick_burning(0.5)
        check(td.enemies[0]["hp"] == 1, "Ember burn deals periodic bonus damage")
        td.tick_burning(0.5)
        check(td.enemies.is_empty() and td.enemies_defeated > 0, "Burn can finish an enemy and count the kill")
        td.coins = 100
        td.choose_tower("bone")
        td.build_tower(1)
        td.enemies.clear()
        td.enemies.append({"lane": 0, "pos": td.slots[1]["pos"] + Vector2(20, 0), "waypoint": 1, "hp": 5, "delay": 0.0})
        td.enemies.append({"lane": 0, "pos": td.slots[1]["pos"] + Vector2(45, 10), "waypoint": 1, "hp": 5, "delay": 0.0})
        td.attack_with_towers(1.0)
        check(td.enemies.size() == 2 and td.enemies[0]["hp"] == 2 and td.enemies[1]["hp"] == 2, "Bone tower pierces aligned enemies and applies earned relic damage")
        td.restart_defense()
        td.necro_kill_bonus = 3
        td.choose_tower("necro")
        td.build_tower(2)
        var necro_coins_before: int = td.coins
        td.enemies.append({"lane": 0, "pos": td.slots[2]["pos"] + Vector2(20, 0), "waypoint": 1, "hp": 3, "delay": 0.0})
        td.attack_with_towers(1.0)
        check(td.enemies.is_empty() and td.coins == necro_coins_before + 8, "Necro tower kill grants base and relic bonus gold")
        td.enemies.append({"lane": 0, "pos": td.slots[2]["pos"] + Vector2(30, 0), "waypoint": 1, "hp": 5, "delay": 0.0})
        td.spawn_necro_spirit(td.slots[2]["pos"])
        td.tick_necro_spirits(0.1)
        check(td.enemies[0]["hp"] == 3 and td.summoned_spirits.size() == 1, "Necro spirit attacks a nearby enemy")
        td.spawn_necro_spirit(td.slots[2]["pos"])
        td.spawn_necro_spirit(td.slots[2]["pos"])
        check(td.summoned_spirits.size() == 2, "Necro spirits are capped at two active summons")
        td.tick_necro_spirits(4.1)
        check(td.summoned_spirits.is_empty(), "Necro spirits expire after their duration")
        run.finish_phase(false)
        check(run.phase == "defeat", "Losing a phase ends run")
        run.reset_run()
        check(run.phase == "hub" and run.phase_count == 0 and run.run_damage_bonus == 0, "New run resets run-only relics")
        check(run.start_run() and run.phase == "day", "New run starts with one button")
        run.finish_phase(true)
        check(run.phase == "transition" and run.complete_transition() and run.phase == "night", "After restart, day flows into night via dusk")
        run.finish_phase(true)
        check(run.choose_run_reward("necro") and run.run_necro_kill_bonus == 3, "Necromancer reward grants kill gold")
        check(run.phase == "transition" and run.complete_transition() and run.active_game.necro_kill_bonus == 3, "Necromancer reward carries through dawn")
        run.queue_free()
        var difficulty_run = run_scene.instantiate()
        root.add_child(difficulty_run)
        check(difficulty_run.set_difficulty(2) and difficulty_run.start_run(), "Nightmare difficulty propagates to first day")
        check(difficulty_run.active_game.difficulty == 2, "Day receives Nightmare setting")
        var difficulty_fragments: int = difficulty_run.meta.fragments
        difficulty_run.finish_phase(true)
        check(difficulty_run.meta.fragments == difficulty_fragments + 3, "Nightmare phase awards three fragments")
        check(difficulty_run.phase == "transition" and difficulty_run.complete_transition(), "Nightmare automatically advances to nighttime via dusk")
        check(difficulty_run.phase == "night" and difficulty_run.active_game != null, "Nightmare run automatically proceeds to night")
        check(difficulty_run.active_game.difficulty == 2, "Night also receives Nightmare setting")
        difficulty_run.reset_run()
        check(difficulty_run.difficulty == 0, "New run defaults to normal")
        difficulty_run.queue_free()
    var night_art_scene = load("res://scenes/topdown_night_prototype.tscn")
    if night_art_scene != null:
        var night_art = night_art_scene.instantiate()
        root.add_child(night_art)
        night_art.room_variant = 0
        var crypt_colors: Dictionary = night_art.crypt_room_palette()
        night_art.room_variant = 1
        var ambush_colors: Dictionary = night_art.crypt_room_palette()
        night_art.room_variant = 2
        var elite_colors: Dictionary = night_art.crypt_room_palette()
        check(crypt_colors["floor"] != ambush_colors["floor"], "Crypt and ambush rooms have distinct floor palettes")
        check(ambush_colors["floor"] != elite_colors["floor"], "Ambush and elite rooms have distinct floor palettes")
        check(night_art.DOOR_POINTS.size() == 4, "Night door markers preserve four directional positions")
        night_art.queue_free()
    var silhouette_scene = load("res://scenes/topdown_night_prototype.tscn")
    if silhouette_scene != null:
        var art_check = silhouette_scene.instantiate()
        root.add_child(art_check)
        check(art_check.night_enemy_visual_role({"role": "boss", "ranged": false}) == "boss", "Night boss has unique visual role")
        check(art_check.night_enemy_visual_role({"role": "champion", "ranged": false}) == "champion", "Night armored enemy has unique visual role")
        check(art_check.night_enemy_visual_role({"role": "flanker", "ranged": false}) == "flanker", "Night flanker has unique visual role")
        check(art_check.night_enemy_visual_role({"role": "regular", "ranged": true}) == "ranged", "Night ranged enemy shows bow")
        check(art_check.night_enemy_visual_role({"role": "regular", "ranged": false}) == "regular", "Night melee enemy shows distinct face")
        art_check.queue_free()
    var warning_scene = load("res://scenes/topdown_night_prototype.tscn")
    if warning_scene != null:
        var warning_probe = warning_scene.instantiate()
        root.add_child(warning_probe)
        check(warning_probe.current_room_progress() == "КОМНАТА 1 / 3", "Standalone night progress matches three-room mode")
        check(warning_probe.current_room_caption() == "СКЛЕП", "Standalone night room name is localized")
        check(is_equal_approx(warning_probe.attack_warning_progress(0.5, 1.0), 0.5), "Threat marker shows half charge")
        check(is_equal_approx(warning_probe.attack_warning_progress(0.0, 1.0), 1.0), "Threat marker fills at strike time")
        check(is_equal_approx(warning_probe.attack_warning_progress(2.0, 1.0), 0.0), "Threat marker clamps before start")
        warning_probe.enable_floor_exploration(1777)
        check(warning_probe.current_room_progress().begins_with("ОТКРЫТО 1 / "), "Exploration HUD counts discovered rooms instead of showing a false 3-room limit")
        check(warning_probe.current_room_caption() != "", "Exploration room type has a readable caption")
        warning_probe.queue_free()
    # A deterministic complete ten-phase run catches regressions in currency,
    # fortress persistence, nighttime income, victory and replay eligibility.
    if run_scene != null:
        var marathon = run_scene.instantiate()
        root.add_child(marathon)
        marathon.meta.save_path = "user://last_ritual_full_run_smoke.json"
        marathon.meta.fragments = 0
        marathon.meta.hero_level = 1
        marathon.meta.treasury_level = 2
        marathon.meta.runs_started = 0
        marathon.meta.runs_won = 0
        marathon.meta.runs_lost = 0
        marathon.meta.phases_cleared = 0
        marathon.meta.claimed_achievement_rewards.clear()
        check(marathon.set_difficulty(1) and marathon.start_run(), "Full run starts at Hard difficulty")
        check(marathon.active_game.coins == 170, "Day one receives treasury bonus once")
        var marathon_seed: int = marathon.fortress_map_seed
        var marathon_paths: Array = marathon.active_game.paths.duplicate(true)
        check(marathon.active_game.fortress_map_seed == marathon_seed, "Run seed matches first day")
        check(marathon.active_game.SIEGE_WAVES == 6, "Full run day uses six-wave siege")

        marathon.active_game.choose_tower("bone")
        check(marathon.active_game.build_tower(0), "First day buys permanent bone tower")
        var carried_coins: int = marathon.active_game.coins
        marathon.active_game.altar_hp = 68
        marathon.finish_phase(true)
        check(marathon.phase == "transition" and marathon.phase_count == 1, "Day one clears into dusk")
        check(int(marathon.fortress_state["coins"]) == carried_coins and int(marathon.fortress_state["altar_hp"]) == 68, "Fortress snapshot captures gold and altar HP")
        marathon.complete_transition()
        check(marathon.phase == "night" and marathon.active_game.difficulty == 1, "Hard difficulty persists into first night")
        marathon.active_game.night_souls = 4
        marathon.finish_phase(true)
        check(marathon.phase == "reward" and marathon.pending_night_coins == 20, "First night converts four souls to twenty defense coins")
        check(not marathon.choose_run_reward("invalid"), "Invalid relic cannot bypass reward selection")
        check(marathon.choose_run_reward("gold") and not marathon.choose_run_reward("gold"), "Relic reward cannot be collected twice")
        check(marathon.phase == "transition" and marathon.complete_transition(), "First dawn enters second day")
        check(marathon.active_game.siege_day == 2 and marathon.active_game.altar_hp == 68, "Day two restores fortress layout and altar HP")
        check(marathon.fortress_map_seed == marathon_seed and marathon.active_game.paths == marathon_paths, "Fortress map remains identical on second day")
        check(marathon.active_game.SIEGE_WAVES == 6, "Second day retains six-wave siege")

        check(marathon.active_game.slots[0]["tower"] == "bone", "Tower survives complete day night cycle")
        check(marathon.active_game.coins == carried_coins + 20 + 30 + 20, "Day two gets saved gold, souls, relic income and treasury exactly once")
        check(marathon.pending_night_coins == 0, "Night income cannot be applied again on the next day")
        marathon.finish_phase(true)
        check(marathon.phase == "transition" and marathon.complete_transition(), "Day two passes automatically into second night")
        marathon.active_game.night_souls = 2
        marathon.finish_phase(true)
        check(marathon.pending_night_coins == 10, "Second night generates new soul income only")
        check(marathon.choose_run_reward("bone") and marathon.complete_transition(), "Second relic passes through dawn")
        check(marathon.phase == "day" and marathon.active_game.siege_day == 3, "Third day uses armored siege")
        check(marathon.fortress_map_seed == marathon_seed and marathon.active_game.paths == marathon_paths, "Fortress map remains identical on third day")
        check(marathon.active_game.SIEGE_WAVES == 6, "Third day retains six-wave siege")

        check(marathon.active_game.slots[0]["tower"] == "bone" and marathon.active_game.bone_synergy_bonus == 1, "Tower and earned relic carry into third siege")
        marathon.finish_phase(true)
        check(marathon.phase == "transition" and marathon.complete_transition(), "Third day passes automatically into third night")
        check(marathon.active_game.attack_damage >= 3, "Third night inherits meta and run-only damage bonuses")
        marathon.finish_phase(true)
        check(marathon.phase == "reward" and marathon.completed_phases == 6, "Third night no longer ends the campaign early")
        check(marathon.choose_run_reward("ember") and marathon.complete_transition(), "Third relic leads to fourth day")
        check(marathon.phase == "day" and marathon.active_game.siege_day == 4, "Fourth day has distinct TD scenario")
        check(marathon.active_game.paths == marathon_paths and marathon.active_game.slots[0]["tower"] == "bone", "Fourth day preserves map and tower")
        check(int(marathon.active_game.wave_enemy_budget(3)["support"]) == 2, "Fourth day gains tactical double-healer wave")
        marathon.finish_phase(true)
        check(marathon.phase == "transition" and marathon.complete_transition(), "Fourth day automatically leads into fourth night")
        marathon.finish_phase(true)
        check(marathon.phase == "reward" and marathon.completed_phases == 8, "Fourth night grants the final inter-day reward")
        check(marathon.choose_run_reward("necro") and marathon.complete_transition(), "Fourth reward leads to fifth day")
        check(marathon.phase == "day" and marathon.active_game.siege_day == 5, "Fifth day is playable")
        check(marathon.active_game.paths == marathon_paths and marathon.active_game.slots[0]["tower"] == "bone", "Fifth day preserves map and towers")
        check(int(marathon.active_game.wave_enemy_budget(4)["captain"]) == 1, "Final day has an early commander")
        marathon.finish_phase(true)
        check(marathon.phase == "transition" and marathon.complete_transition(), "Fifth day automatically leads to fifth night")
        marathon.finish_phase(true)
        check(marathon.phase == "victory" and marathon.completed_phases == 10, "Fifth night finishes ten-phase campaign")
        check(marathon.meta.runs_started == 1 and marathon.meta.runs_won == 1 and marathon.meta.runs_lost == 0, "One completed run counts as exactly one victory")
        check(marathon.meta.phases_cleared == 10, "All ten campaign phases count exactly once")
        var final_fragments: int = marathon.meta.fragments
        marathon.finish_phase(true)
        check(marathon.meta.fragments == final_fragments and marathon.meta.runs_won == 1, "Victory cannot award fragments twice")
        marathon.reset_run()
        check(marathon.phase == "hub" and marathon.fortress_state.is_empty() and marathon.run_gold_bonus == 0, "Replay clears fortress and run relics but keeps meta progress")
        check(marathon.fortress_map_seed == 0, "Run reset clears map seed before next run")
        check(marathon.meta.runs_won == 1 and marathon.meta.hero_level == 1, "Permanent progression survives new run")
        marathon.queue_free()
        DirAccess.remove_absolute(ProjectSettings.globalize_path("user://last_ritual_full_run_smoke.json"))
    # Terminal-state regression: no duplicated loss, rewards, phases or stale timers.
    if run_scene != null:
        var loss_probe = run_scene.instantiate()
        root.add_child(loss_probe)
        loss_probe.meta.save_path = "user://last_ritual_defeat_smoke.json"
        loss_probe.meta.runs_started = 0
        loss_probe.meta.runs_lost = 0
        loss_probe.meta.runs_won = 0
        loss_probe.meta.phases_cleared = 0
        check(loss_probe.start_run(), "Defeat regression starts a run")
        loss_probe.finish_phase(false)
        check(loss_probe.phase == "defeat" and loss_probe.meta.runs_lost == 1, "First-day defeat records exactly one loss")
        var lost_fragments: int = loss_probe.meta.fragments
        loss_probe.finish_phase(false)
        loss_probe.finish_phase(true)
        check(loss_probe.meta.runs_lost == 1 and loss_probe.meta.fragments == lost_fragments, "Late scene callbacks do not double count loss or award a win")
        check(not loss_probe.choose_run_reward("gold") and not loss_probe.complete_transition(), "Cannot collect relics or advance after defeat")
        loss_probe.begin_transition()
        check(loss_probe.phase == "defeat", "Stray transition does not revive a defeated run")
        loss_probe.reset_run()
        check(loss_probe.phase == "hub" and loss_probe.transition_time == 0.0, "Restart clears defeat and transition timer")
        check(loss_probe.start_run(), "Restart after first-day loss works")
        loss_probe.finish_phase(true)
        check(loss_probe.phase == "transition" and loss_probe.complete_transition(), "Dusk resumes normally after defeat reset")
        loss_probe.active_game.night_souls = 4
        loss_probe.finish_phase(false)
        check(loss_probe.phase == "defeat" and loss_probe.pending_night_coins == 0, "Night defeat does not transfer unearned souls")
        check(loss_probe.meta.runs_lost == 2 and loss_probe.meta.runs_won == 0, "Day and night defeats count once each")
        var second_loss_fragments: int = loss_probe.meta.fragments
        loss_probe.finish_phase(true)
        loss_probe._process(loss_probe.TRANSITION_DURATION + 1.0)
        check(loss_probe.phase == "defeat" and loss_probe.meta.fragments == second_loss_fragments, "Old timers and victory signals cannot escape terminal state")
        loss_probe.queue_free()
        DirAccess.remove_absolute(ProjectSettings.globalize_path("user://last_ritual_defeat_smoke.json"))
    var packed := load("res://scenes/topdown_night_prototype.tscn") as PackedScene
    check(packed != null, "Top-down entry scene loads")
    if packed == null:
        quit(1)
        return
    var ranged_probe = packed.instantiate()
    root.add_child(ranged_probe)
    ranged_probe.enemies.clear()
    ranged_probe.player_pos = Vector2(500.0, 325.0)
    ranged_probe.enemies.append({"pos": Vector2(800.0, 325.0), "hp": 10, "speed": 0.0, "ranged": true})
    ranged_probe.ranged_fire_clock = 1.65
    ranged_probe._process(0.1)
    check(ranged_probe.hostile_shots.is_empty() and float(ranged_probe.enemies[0].get("ranged_warning", 0.0)) > 0.0, "Ranged enemy warns before projectile appears")
    check(ranged_probe.enemies[0]["attack_target"] == Vector2(500.0, 325.0), "Ranged warning locks the player's current position")
    ranged_probe.toggle_controls_help()
    var ranged_warning_frozen: float = ranged_probe.enemies[0]["ranged_warning"]
    ranged_probe._process(2.0)
    check(is_equal_approx(float(ranged_probe.enemies[0]["ranged_warning"]), ranged_warning_frozen) and ranged_probe.hostile_shots.is_empty(), "Help pause freezes ranged attack warning")
    ranged_probe.toggle_controls_help()
    ranged_probe.last_move_direction = Vector2.UP
    check(ranged_probe.dash(), "Dash moves player out of ranged aim line")
    ranged_probe._process(0.56)
    check(ranged_probe.hostile_shots.size() == 1 and ranged_probe.hostile_shots[0]["velocity"] == Vector2.LEFT * 180.0, "Ranged shot uses locked target after windup")
    ranged_probe._process(1.0)
    check(ranged_probe.player_hp == 100 and ranged_probe.hostile_shots.size() == 1, "Dodging an aimed ranged shot avoids damage without relying on invulnerability")
    ranged_probe.restart_run()
    check(ranged_probe.hostile_shots.is_empty() and is_zero_approx(ranged_probe.ranged_fire_clock) and is_zero_approx(float(ranged_probe.enemies[1].get("ranged_warning", 0.0))), "Room restart clears projectiles and warnings")
    ranged_probe.queue_free()

    var melee_probe = packed.instantiate()
    root.add_child(melee_probe)
    melee_probe.enemies.clear()
    melee_probe.player_pos = Vector2(160.0, 325.0)
    melee_probe.enemies.append({"pos": Vector2(210.0, 325.0), "hp": 10, "speed": 0.0, "ranged": false})
    melee_probe._process(0.1)
    check(melee_probe.player_hp == 100 and float(melee_probe.enemies[0].get("melee_warning", 0.0)) > 0.0, "Melee enemy telegraphs instead of dealing instant contact damage")
    check(melee_probe.enemies[0]["attack_target"] == Vector2(160.0, 325.0), "Melee warning locks the danger zone")
    melee_probe.last_move_direction = Vector2.UP
    check(melee_probe.dash(), "Dash moves out of melee warning zone")
    melee_probe.invulnerable_time = 0.0
    melee_probe._process(0.46)
    check(melee_probe.player_hp == 100 and float(melee_probe.enemies[0]["melee_recharge"]) > 0.0, "Melee telegraph misses player outside its warning circle")
    melee_probe.player_pos = Vector2(160.0, 325.0)
    melee_probe._process(1.2)
    check(float(melee_probe.enemies[0]["melee_warning"]) > 0.0, "Melee can warn again after recovery")
    melee_probe._process(0.46)
    check(melee_probe.player_hp == 90, "Staying in melee warning circle causes 10 damage after windup")
    melee_probe.queue_free()

    var dash_probe = packed.instantiate()
    root.add_child(dash_probe)
    var dash_start: Vector2 = dash_probe.player_pos
    dash_probe._unhandled_input(left_click_event(dash_probe.DASH_BUTTON.get_center()))
    check(dash_probe.player_pos == dash_start + Vector2(dash_probe.DASH_DISTANCE, 0) and is_equal_approx(dash_probe.dash_cooldown, dash_probe.DASH_COOLDOWN), "Mouse dash moves along last facing direction and starts cooldown")
    check(dash_probe.invulnerable_time >= dash_probe.DASH_INVULNERABILITY and dash_probe.dash_flash_time > 0.0, "Dash grants brief evasion and shows a trail")
    dash_probe.take_damage(10)
    check(dash_probe.player_hp == 100 and not dash_probe.dash(), "Dash prevents immediate damage and cannot be repeated before cooldown")
    dash_probe.enemies.clear()
    dash_probe._process(dash_probe.DASH_COOLDOWN)
    check(is_zero_approx(dash_probe.dash_cooldown) and is_zero_approx(dash_probe.invulnerable_time), "Dash cooldown and evasion expire during active play")
    dash_probe.toggle_controls_help()
    check(not dash_probe.dash() and is_zero_approx(dash_probe.dash_cooldown), "Pause help prevents dodging")
    dash_probe.toggle_controls_help()
    dash_probe.reward_available = true
    check(not dash_probe.dash(), "Relic choice blocks dash")
    dash_probe.reward_available = false
    var dash_space_event := InputEventKey.new()
    dash_space_event.keycode = KEY_SPACE
    dash_space_event.pressed = true
    dash_probe._unhandled_input(dash_space_event)
    check(dash_probe.dash_cooldown > 0.0, "Space key triggers dash")
    dash_probe.player_pos = dash_probe.ARENA.end - Vector2(16, 16)
    dash_probe.dash_cooldown = 0.0
    check(not dash_probe.dash(), "Dash at arena boundary cannot teleport outside or waste cooldown")
    dash_probe.restart_run()
    check(is_zero_approx(dash_probe.dash_cooldown) and dash_probe.last_move_direction == Vector2.RIGHT, "Restart clears dash cooldown and facing")
    dash_probe.queue_free()

    var cover_probe = packed.instantiate()
    root.add_child(cover_probe)
    check(cover_probe.obstacles.size() == 2 and cover_probe.ROOM_KINDS[cover_probe.room_variant] == "CRYPT", "Crypt has two recognizable cover pillars")
    var crypt_wall: Rect2 = cover_probe.obstacles[0]
    check(not crypt_wall.grow(cover_probe.HERO_RADIUS).has_point(cover_probe.player_pos), "Cover leaves the starting position clear")
    cover_probe.player_pos = Vector2(350.0, 370.0)
    cover_probe.move_player(Vector2.RIGHT, 1.0)
    check(cover_probe.player_pos.x < crypt_wall.position.x - 16.0 and is_equal_approx(cover_probe.player_pos.y, 370.0), "Hero cannot walk through a stone pillar")
    cover_probe.player_pos = Vector2(350.0, 370.0)
    cover_probe.last_move_direction = Vector2.RIGHT
    check(cover_probe.dash() and cover_probe.player_pos.x < crypt_wall.position.x - 16.0, "Dash stops safely at cover rather than teleporting through it")
    cover_probe.dash_cooldown = 0.0
    cover_probe.player_pos = Vector2(350.0, 370.0)
    cover_probe.enemies.clear()
    cover_probe.enemies.append({"pos": Vector2(500.0, 370.0), "hp": 3, "speed": 0.0, "ranged": false})
    cover_probe.attack_cooldown = 0.0
    check(not cover_probe.attack(Vector2(500.0, 370.0)), "Hero cannot damage an enemy through solid cover")
    cover_probe.enemies.clear()
    cover_probe.player_pos = Vector2(520.0, 370.0)
    cover_probe.invulnerable_time = 0.0
    cover_probe.hostile_shots.append({"pos": Vector2(350.0, 370.0), "velocity": Vector2.RIGHT * 180.0})
    cover_probe._process(1.0)
    check(cover_probe.hostile_shots.is_empty() and cover_probe.player_hp == 100, "Pillar catches a hostile shot before it reaches the hero")
    cover_probe.enemies.append({"pos": Vector2(350.0, 370.0), "hp": 3, "speed": 120.0, "ranged": false})
    cover_probe._process(0.5)
    check(cover_probe.enemies[0]["pos"].x < crypt_wall.position.x - cover_probe.ENEMY_RADIUS, "Melee pursuers cannot pass straight through pillars")
    cover_probe.open_room(1, 1)
    check(cover_probe.obstacles.size() == 2 and cover_probe.obstacles[0] != crypt_wall, "Next room replaces crypt cover with ambush layout")
    var ambush_cover: Array[Rect2] = cover_probe.obstacles.duplicate()
    cover_probe.open_room(1, 1)
    check(cover_probe.obstacles == ambush_cover and cover_probe.hostile_shots.is_empty(), "Room cover is deterministic and reentry clears shots")
    cover_probe.open_room(2, 2)
    check(cover_probe.obstacles.size() == 2 and not cover_probe.obstacles[0].has_point(Vector2(160, 325)), "Elite cover keeps hero spawn accessible")
    cover_probe.queue_free()

    var patterns = packed.instantiate()
    root.add_child(patterns)
    patterns.set_dungeon_seed(1)
    check(patterns.room_variant == 1 and patterns.enemies.size() == 3, "Ambush seed creates a three-enemy formation")
    check(patterns.enemies[0].get("role", "") == "flanker" and patterns.enemies[1].get("role", "") == "flanker" and patterns.enemies[2]["ranged"], "Ambush combines two quick flankers and one ranged foe")
    var seed_one_pos: Vector2 = patterns.enemies[0]["pos"]
    patterns.set_dungeon_seed(1)
    check(patterns.enemies[0]["pos"] == seed_one_pos, "Repeated ambush seed reproduces formation")
    patterns.set_dungeon_seed(4)
    check(patterns.room_variant == 1 and patterns.enemies[0]["pos"] != seed_one_pos, "Different ambush seeds mirror flanking lanes")
    patterns.set_dungeon_seed(2)
    check(patterns.room_variant == 2 and patterns.enemies.size() == 3 and patterns.enemies.back().get("role", "") == "champion", "Elite room includes an armored champion")
    check(patterns.ROOM_TACTICS.size() == patterns.ROOM_KINDS.size(), "Every encounter type has a visible tactical hint")
    patterns.player_pos = Vector2(850.0, 450.0)
    patterns.attack_damage = 3
    var champion_before: int = patterns.enemies.back()["hp"]
    check(patterns.attack(Vector2(850.0, 450.0)) and patterns.enemies.back()["hp"] == champion_before - 2, "Champion armor reduces effective relic damage by one")
    check(patterns.floating_combat_texts.back()["text"] == "-2", "Floating hit number shows damage after armor")
    patterns.attack_damage = 1
    patterns.attack_cooldown = 0.0
    check(patterns.attack(Vector2(850.0, 450.0)) and patterns.enemies.back()["hp"] == champion_before - 3, "Champion armor never reduces damage below one")
    patterns.difficulty = 2
    patterns.open_room(0, 2)
    check(patterns.enemies.back()["hp"] == 12 and float(patterns.enemies.back()["speed"]) > 75.0, "Nightmare champion scales in health and speed")
    patterns.player_pos = Vector2(160.0, 325.0)
    patterns.enemies.clear()
    patterns.enemies.append({"pos": Vector2(210.0, 325.0), "hp": 8, "speed": 0.0, "ranged": false, "role": "flanker"})
    patterns._process(0.05)
    check(is_equal_approx(float(patterns.enemies[0]["melee_warning"]), patterns.FLANKER_WARNING), "Flanker uses a shorter visible windup")
    patterns._process(0.4)
    check(patterns.player_hp == 92, "Flanker strike deals lighter eight-point damage")
    patterns.invulnerable_time = 0.0
    patterns.enemies.clear()
    patterns.enemies.append({"pos": Vector2(210.0, 325.0), "hp": 8, "speed": 0.0, "ranged": false, "role": "champion"})
    patterns._process(0.05)
    check(is_equal_approx(float(patterns.enemies[0]["melee_warning"]), patterns.CHAMPION_WARNING), "Champion telegraph lasts longer than flanker warning")
    patterns._process(0.72)
    check(patterns.player_hp == 78, "Champion's slower strike deals fourteen-point damage")
    patterns.queue_free()

    var game = packed.instantiate()
    root.add_child(game)
    check(game.sfx != null and game.sfx.has_effect("hit") and game.sfx.has_effect("relic"), "Night prototype loads synthesized combat and reward audio")
    check(game.HELP_BUTTON.has_point(Vector2(1040, 35)) and not game.HELP_BUTTON.intersects(game.RELIC_RECTS[0]), "Night mouse help button stays separate from relic choices")
    game._unhandled_input(left_click_event(game.HELP_BUTTON.get_center()))
    check(game.help_visible, "Mouse opens night help overlay")
    game.reward_available = true
    game._unhandled_input(left_click_event(game.RELIC_RECTS[0].get_center()))
    check(game.help_visible and game.rewards_taken == 0 and game.relics.is_empty(), "Night help blocks relic choices underneath")
    game.reward_available = false
    game._unhandled_input(left_click_event(game.HELP_CLOSE_BUTTON.get_center()))
    check(not game.help_visible, "Mouse Continue closes night help")
    game.toggle_controls_help()
    var night_pos_before_help: Vector2 = game.player_pos
    game._process(0.5)
    check(game.help_visible and game.player_pos == night_pos_before_help, "Night controls help pauses the dungeon simulation")
    game.toggle_controls_help()
    check(not game.help_visible, "Night controls help closes cleanly")
    check(game.room_index == 0 and game.enemies.size() == 2, "First room has two enemy archetypes")
    game.set_dungeon_seed(2)
    check(game.room_variant == 2 and game.enemies.size() == 3, "Elite seed adds a third enemy")
    var seeded_position: Vector2 = game.enemies[0]["pos"]
    game.set_dungeon_seed(2)
    check(game.enemies[0]["pos"] == seeded_position, "Same seed reproduces enemy formation")
    game.set_dungeon_seed(1)
    check(game.room_variant == 1 and game.enemies[0]["pos"] != seeded_position, "Different seed changes the room")
    game.set_dungeon_seed(0)
    check(game.enemies[1]["ranged"], "Ranged enemy is present")
    check(not game.next_room() and not game.choose_route(1), "Room routes remain locked while enemies live")
    game.player_pos = Vector2(560.0, 240.0)
    game.attack_cooldown = 0.0
    check(game.attack(Vector2(570.0, 240.0)), "Hero can attack first enemy")
    check(game.floating_combat_texts.size() == 1 and game.enemies[0].get("hit_flash", 0.0) > 0.0, "Successful hit spawns damage number and enemy hit flash")
    for i in range(2):
        game.attack_cooldown = 0.0
        check(game.attack(Vector2(570.0, 240.0)), "Hero can attack first enemy")
    check(game.enemies.size() == 1 and game.night_souls == 1, "First enemy defeated and awards a soul")
    check(game.death_bursts.size() == 1 and game.death_bursts[0]["time"] > 0.0, "Defeated enemy creates temporary death-ring effect")
    game.player_pos = Vector2(710.0, 370.0)
    for i in range(3):
        game.attack_cooldown = 0.0
        check(game.attack(Vector2(730.0, 370.0)), "Hero can attack ranged enemy")
    check(game.reward_available and game.night_souls == 2 and not game.door_available(), "Defeating room earns souls but reward blocks exit")
    check(not game.choose_relic("invalid"), "Invalid relic is rejected")
    check(game.choose_relic("bone"), "Bone relic can be chosen")
    check(game.reward_notice_time > 0.0 and game.reward_notice == "RELIC ACQUIRED: BONE", "Relic pickup shows named confirmation")
    check(game.attack_damage == 2 and game.relics == ["bone"], "Bone relic increases damage")
    check(not game.choose_relic("blood"), "Room reward cannot be taken twice")
    check(not game.choose_route(4), "Invalid route choice is rejected")
    check(game.door_available() and game.click_ui(game.ROUTE_RECTS[1].get_center()), "Mouse chooses alternate night route")
    check(game.room_variant == 2 and game.room_index == 1, "Alternate route changes the next room variant")
    check(game.route_boon == "RISK: -12 HP / +1 DAMAGE" and game.player_hp == 88 and game.attack_damage == 3, "Risk route trades 12 HP for damage and elite fight")
    var treasury_probe = packed.instantiate()
    root.add_child(treasury_probe)
    treasury_probe.enemies.clear()
    treasury_probe.player_hp = 64
    check(treasury_probe.choose_route(0) and treasury_probe.player_hp == 82 and treasury_probe.route_boon == "TREASURE: +18 HP", "Treasure route heals before next room")
    check(treasury_probe.enemies.size() >= 2, "Treasury route still leads to an encounter")
    treasury_probe.queue_free()
    var risk_probe = packed.instantiate()
    root.add_child(risk_probe)
    risk_probe.enemies.clear()
    risk_probe.player_hp = 12
    check(not risk_probe.choose_route(1) and risk_probe.room_index == 0, "Risk route cannot kill hero on entry")
    risk_probe.queue_free()
    var curse_probe = packed.instantiate()
    root.add_child(curse_probe)
    curse_probe.enemies.clear()
    check(curse_probe.click_ui(curse_probe.ROUTE_RECTS[2].get_center()), "Cursed altar event selectable by mouse")
    check(curse_probe.player_hp == 80 and is_equal_approx(curse_probe.attack_speed_multiplier, 1.35) and curse_probe.room_variant == 1, "Cursed altar trades health for attack speed and ambush encounter")
    curse_probe.restart_run()
    check(curse_probe.player_hp == 100 and is_equal_approx(curse_probe.attack_speed_multiplier, 1.0) and curse_probe.route_boon == "", "Restart clears cursed altar upgrades")
    curse_probe.enemies.clear()
    curse_probe.player_hp = 20
    check(not curse_probe.choose_route(2) and curse_probe.room_index == 0 and curse_probe.player_hp == 20, "Cursed altar sacrifice is blocked at low HP")
    curse_probe.queue_free()
    var merchant_probe = packed.instantiate()
    root.add_child(merchant_probe)
    merchant_probe.enemies.clear()
    check(merchant_probe.click_ui(merchant_probe.ROUTE_RECTS[3].get_center()) and merchant_probe.shop_open, "Mouse opens wandering merchant after clearing room")
    check(not merchant_probe.buy_shop_offer(0) and merchant_probe.attack_damage == 1, "Merchant rejects unaffordable purchase")
    merchant_probe.night_souls = 3
    check(merchant_probe.click_ui(merchant_probe.SHOP_RECTS[0].get_center()) and merchant_probe.night_souls == 1 and merchant_probe.attack_damage == 2, "Merchant sells damage for two souls")
    merchant_probe.player_hp = 60
    check(merchant_probe.click_ui(merchant_probe.SHOP_RECTS[1].get_center()) and merchant_probe.night_souls == 0 and merchant_probe.player_hp == 80, "Merchant sells healing for one soul")
    check(not merchant_probe.buy_shop_offer(0), "Spent souls cannot be reused")
    check(merchant_probe.click_ui(merchant_probe.SHOP_RECTS[2].get_center()) and merchant_probe.room_index == 1 and not merchant_probe.shop_open, "Leaving merchant advances to next encounter")
    merchant_probe.restart_run()
    check(merchant_probe.night_souls == 0 and merchant_probe.attack_damage == 1 and not merchant_probe.shop_open, "Restart resets souls, purchases and merchant state")
    merchant_probe.queue_free()
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
    check(game.attack_damage == 5 and game.player_hp < hp_before, "Blood relic stacks with risk-route damage")
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
    check(game.death_bursts.is_empty() and game.floating_combat_texts.is_empty() and game.reward_notice_time == 0.0, "Restart clears transient combat effects and relic notices")
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
    # Hover inspector is transient and cannot cover the HUD or the shop.
    var hover_scene = load("res://scenes/topdown_td_prototype.tscn") as PackedScene
    if hover_scene != null:
        var hover_game = hover_scene.instantiate()
        root.add_child(hover_game)
        check(hover_game.choose_tower("bone") and hover_game.build_tower(0), "Hover QA builds a tower")
        var tower_point: Vector2 = hover_game.slots[0]["pos"]
        check(not hover_game.hovered_tower_info(tower_point).is_empty(), "Hovering a built tower displays inspector data")
        check(hover_game.hovered_tower_info(Vector2(10, 10)).is_empty(), "Leaving tower removes hover inspector data")
        hover_game.notification(Node.NOTIFICATION_WM_MOUSE_EXIT)
        check(hover_game.hovered_tower_info(tower_point).is_empty() and hover_game.tooltip_at(hover_game.tower_shop_rect(0).get_center()).is_empty(), "Leaving game window hides all tower tooltip data")
        hover_game.notification(Node.NOTIFICATION_WM_MOUSE_ENTER)
        check(not hover_game.hovered_tower_info(tower_point).is_empty(), "Reentering game window restores tower hover")

        for probe in [Vector2(14, 120), Vector2(1100, 460), tower_point]:
            var panel: Rect2 = hover_game.tower_hover_panel_rect(probe)
            check(panel.position.x >= 12.0 and panel.end.x <= 1140.0 and panel.position.y >= 100.0 and panel.end.y <= 530.0, "Hover inspector stays between HUD and shop")
            check(panel.size.x <= 270.0 and panel.size.y <= 170.0, "Hover inspector remains compact")
        hover_game.queue_free()
    # Upgrade/sell buttons cannot occupy the same hitboxes as shop cards.
    var shop_ui_scene = load("res://scenes/topdown_td_prototype.tscn") as PackedScene
    if shop_ui_scene != null:
        var shop_ui = shop_ui_scene.instantiate()
        root.add_child(shop_ui)
        check(not shop_ui.UPGRADE_BUTTON.intersects(shop_ui.SELL_BUTTON), "Upgrade and sell controls do not overlap")
        for shop_index in range(shop_ui.TD_TOWER_STATS.SHOP_ORDER.size()):
            check(not shop_ui.UPGRADE_BUTTON.intersects(shop_ui.tower_shop_rect(shop_index)), "Upgrade button stays outside shop cards")
            check(not shop_ui.SELL_BUTTON.intersects(shop_ui.tower_shop_rect(shop_index)), "Sell button stays outside shop cards")
        check(not shop_ui.UPGRADE_BUTTON.intersects(shop_ui.MOVE_BUTTON), "Upgrade action stays outside relocation control")
        shop_ui.queue_free()
    # Roguelite catalog must be deterministic, unique and safe to inspect.
    var boons = load("res://scripts/td/td_abyss_boons.gd")
    var offers_a: Array[String] = boons.offers(913, 2)
    check(offers_a.size() == 3, "Abyss catalog generates three offers")
    check(offers_a == boons.offers(913, 2), "Abyss catalog is reproducible for the same run and day")
    var unique_offers: Dictionary = {}
    for id in offers_a:
        unique_offers[id] = true
        check(not boons.info(id).is_empty(), "Every generated offer has a description")
    check(unique_offers.size() == 3, "Abyss offers never repeat within a choice")
    check(boons.offers(913, 0).is_empty() and boons.offers(913, 6).is_empty(), "Abyss catalog rejects invalid days")
    check(boons.offers(913, 2, 99).size() == boons.BOONS.size(), "Abyss offers cannot exceed catalog")
    # First playable Abyss reward integrates into existing council without another modal.
    var boon_scene = load("res://scenes/topdown_td_prototype.tscn") as PackedScene
    if boon_scene != null:
        var boon_game = boon_scene.instantiate()
        root.add_child(boon_game)
        boon_game.wave_number = 3
        var gold_before: int = boon_game.coins
        for reward_seed in range(32):
            boon_game.set_fortress_map_seed(reward_seed)
            if boon_game.council_offers().has("safe"):
                break
        check(boon_game.choose_interwave_event("safe"), "Abyss reserve can be claimed via council")
        check(boon_game.coins == gold_before + 20 and boon_game.ritual_reserve_claimed, "Abyss reserve pays exactly 20 gold")
        check(not boon_game.choose_interwave_event("safe") and boon_game.coins == gold_before + 20, "Abyss reserve cannot be claimed twice")
        var saved_boon: Dictionary = boon_game.export_fortress_state()
        var boon_restored = boon_scene.instantiate()
        root.add_child(boon_restored)
        check(boon_restored.import_fortress_state(saved_boon) and boon_restored.ritual_reserve_claimed, "Abyss reserve state survives day transfer")
        saved_boon.erase("ritual_reserve_claimed")
        check(boon_restored.import_fortress_state(saved_boon) and not boon_restored.ritual_reserve_claimed, "Older fortress snapshots remain compatible")
        boon_game.restart_defense()
        check(not boon_game.ritual_reserve_claimed, "New defense resets council reward state")
        boon_game.queue_free()
        boon_restored.queue_free()
    # The first combat boon makes burn kills splash, without recursive explosion chains.
    var ember_mod = load("res://scripts/td/td_ember_heart.gd")
    var ember_foes: Array[Dictionary] = [
        {"pos": Vector2(100, 100), "hp": 2, "delay": 0.0},
        {"pos": Vector2(170, 100), "hp": 3, "delay": 0.0},
        {"pos": Vector2(120, 100), "hp": 1, "delay": 1.0},
        {"pos": Vector2(350, 100), "hp": 1, "delay": 0.0}
    ]
    var ember_kills: Array[Dictionary] = ember_mod.splash_targets(Vector2(100, 100), ember_foes)
    check(ember_kills.size() == 1 and ember_foes[0]["hp"] == 0, "Ember splash kills only in-range vulnerable targets")
    check(ember_foes[1]["hp"] == 1 and ember_foes[2]["hp"] == 1 and ember_foes[3]["hp"] == 1, "Ember splash ignores delayed and distant enemies")
    if boon_scene != null:
        var ember_game = boon_scene.instantiate()
        root.add_child(ember_game)
        ember_game.wave_number = 3
        for reward_seed in range(32):
            ember_game.set_fortress_map_seed(reward_seed)
            if ember_game.council_offers().has("raid"):
                break
        check(ember_game.choose_interwave_event("raid") and ember_game.ember_heart_claimed, "War council raid unlocks Ember Heart")
        var burning_foe: Dictionary = {"pos": Vector2(400, 300), "hp": 1, "delay": 0.0}
        var nearby_foe: Dictionary = {"pos": Vector2(430, 300), "hp": 2, "delay": 0.0}
        ember_game.enemies.clear()
        ember_game.enemies.append(burning_foe)
        ember_game.enemies.append(nearby_foe)
        ember_game.apply_burn(burning_foe)
        var initial_gold: int = ember_game.coins
        ember_game.tick_burning(0.5)
        check(ember_game.ember_bursts.size() == 1, "Burn kill creates a single Ember Heart ring")
        ember_game.update_ember_bursts(0.5)
        check(ember_game.ember_bursts.is_empty(), "Ember Heart visual expires after short duration")
        check(ember_game.enemies.is_empty() and ember_game.coins == initial_gold + 10, "Ember Heart splash awards two kills exactly once")
        var ember_snapshot: Dictionary = ember_game.export_fortress_state()
        var ember_next = boon_scene.instantiate()
        root.add_child(ember_next)
        ember_next.set_fortress_map_seed(ember_game.fortress_map_seed)
        check(ember_next.import_fortress_state(ember_snapshot) and ember_next.ember_heart_claimed, "Ember Heart survives day transition")
        ember_snapshot.erase("ember_heart_claimed")
        check(ember_next.import_fortress_state(ember_snapshot) and not ember_next.ember_heart_claimed, "Old fortress snapshots load without Ember Heart")
        ember_game.queue_free()
        ember_next.queue_free()
    if boon_scene != null:
        var burst_cap = boon_scene.instantiate()
        root.add_child(burst_cap)
        burst_cap.ember_heart_claimed = true
        for index in range(20):
            burst_cap.enemies.append({"pos": Vector2(100 + index * 3, 200), "hp": 1, "delay": 0.0, "burn_time": 0.5, "burn_tick": 0.5, "burn_damage": 1})
            burst_cap.tick_burning(0.5)
        check(burst_cap.ember_bursts.size() <= burst_cap.MAX_EMBER_BURSTS, "Ember VFX buffer is capped during dense combat")
        burst_cap.restart_defense()
        check(burst_cap.ember_bursts.is_empty(), "Ember VFX reset with defense")
        burst_cap.queue_free()
    if boon_scene != null:
        var council_rng_game = boon_scene.instantiate()
        root.add_child(council_rng_game)
        council_rng_game.set_fortress_map_seed(1234)
        council_rng_game.siege_day = 4
        var council_a: Array[String] = council_rng_game.council_offers()
        check(council_a == council_rng_game.council_offers(), "Council card order is stable for a run seed and day")
        var council_unique: Dictionary = {}
        for offer in council_a:
            council_unique[offer] = true
        check(council_unique.size() == 3 and ["raid", "repair", "safe", "blood"].has(council_a[0]), "Council offers three unique implemented rewards")
        council_rng_game.queue_free()
    if boon_scene != null:
        var frost_game = boon_scene.instantiate()
        root.add_child(frost_game)
        var chilled: Dictionary = {"frost_time": 2.0}
        var plain: Dictionary = {"frost_time": 0.0}
        var base_chilled: int = frost_game.tower_synergy_damage(0, chilled)
        frost_game.wave_number = 3
        frost_game.altar_hp = 65
        for reward_seed in range(32):
            frost_game.set_fortress_map_seed(reward_seed)
            if frost_game.council_offers().has("repair"):
                break
        check(frost_game.choose_interwave_event("repair"), "Council frost reward can be claimed")
        check(frost_game.altar_hp == 85 and frost_game.eternal_frost_claimed, "Eternal Frost keeps council healing")
        check(frost_game.tower_synergy_damage(0, chilled) == base_chilled + 1, "Eternal Frost adds one damage against chilled foes")
        check(frost_game.tower_synergy_damage(0, plain) == base_chilled, "Eternal Frost does not modify unchilled targets")
        var frost_state: Dictionary = frost_game.export_fortress_state()
        var frost_next = boon_scene.instantiate()
        root.add_child(frost_next)
        check(frost_next.import_fortress_state(frost_state) and frost_next.eternal_frost_claimed, "Eternal Frost persists to next defense")
        frost_state.erase("eternal_frost_claimed")
        check(frost_next.import_fortress_state(frost_state) and not frost_next.eternal_frost_claimed, "Old fortress snapshots do not activate Eternal Frost")
        frost_game.restart_defense()
        check(not frost_game.eternal_frost_claimed, "Restart clears Eternal Frost")
        frost_game.queue_free()
        frost_next.queue_free()
    if boon_scene != null:
        var blood_game = boon_scene.instantiate()
        root.add_child(blood_game)
        var base_damage: int = blood_game.tower_synergy_damage(0, {})
        blood_game.wave_number = 3
        blood_game.altar_hp = 10
        # Locate a deterministic run whose 3-of-4 offers contain Blood Pact.
        for map_seed in range(32):
            blood_game.set_fortress_map_seed(map_seed)
            if blood_game.council_offers().has("blood"):
                break
        check(blood_game.council_offers().has("blood"), "Blood Pact appears in seeded council offers")
        check(blood_game.choose_interwave_event("blood"), "Blood Pact may be selected from offered rewards")
        check(blood_game.altar_hp == 1 and blood_game.blood_pact_claimed, "Blood Pact consumes HP without killing altar")
        check(blood_game.tower_synergy_damage(0, {}) == base_damage + 1, "Blood Pact increases tower damage")
        check(not blood_game.choose_interwave_event("blood"), "Blood Pact cannot be chosen twice")
        var blood_state: Dictionary = blood_game.export_fortress_state()
        var blood_next = boon_scene.instantiate()
        root.add_child(blood_next)
        blood_next.set_fortress_map_seed(blood_game.fortress_map_seed)
        check(blood_next.import_fortress_state(blood_state) and blood_next.blood_pact_claimed, "Blood Pact persists across days")
        blood_state.erase("blood_pact_claimed")
        check(blood_next.import_fortress_state(blood_state) and not blood_next.blood_pact_claimed, "Old fortress snapshot loads without Blood Pact")
        blood_game.restart_defense()
        check(not blood_game.blood_pact_claimed, "Restart clears Blood Pact")
        blood_game.queue_free()
        blood_next.queue_free()
    # A pair of boons opens a conditional thermal combo, but never buffs plain targets.
    var combo_mod = load("res://scripts/td/td_ember_heart.gd")
    var cold_targets: Array[Dictionary] = [
        {"pos": Vector2(100, 100), "hp": 3, "frost_time": 2.0, "delay": 0.0},
        {"pos": Vector2(120, 100), "hp": 3, "frost_time": 0.0, "delay": 0.0},
        {"pos": Vector2(300, 100), "hp": 3, "frost_time": 2.0, "delay": 0.0}
    ]
    check(combo_mod.splash_targets(Vector2(100, 100), cold_targets, true).size() == 1, "Dual Ember and Frost boons can finish chilled enemies")
    check(cold_targets[0]["hp"] == 0 and cold_targets[1]["hp"] == 1 and cold_targets[2]["hp"] == 3, "Thermal combo gives only chilled nearby enemies one extra splash damage")
    var single_targets: Array[Dictionary] = [{"pos": Vector2(100, 100), "hp": 3, "frost_time": 3.0, "delay": 0.0}]
    check(combo_mod.splash_targets(Vector2(100, 100), single_targets).is_empty() and single_targets[0]["hp"] == 1, "Ember Heart without Frost boon keeps original damage")
    var armor = load("res://scripts/td/td_enemy_armor.gd")
    check(armor.tower_hit_damage("brute", "bone", 3, 4) == 3, "Late-day armored brute resists physical hits")
    check(armor.tower_hit_damage("brute", "fire", 3, 4) == 4, "Fire towers pierce heavy armor")
    check(armor.tower_hit_damage("brute", "bone", 2, 4) == 4, "Early siege brutes retain familiar difficulty")
    check(armor.tower_hit_damage("runner", "bone", 5, 4) == 4, "Runners do not acquire heavy armor")
    check(armor.tower_hit_damage("brute", "necro", 5, 1) == 1, "Heavy armor never nullifies a tower hit")
    if boon_scene != null:
        var armor_ui_game = boon_scene.instantiate()
        root.add_child(armor_ui_game)
        check(armor_ui_game.siege_day == 1, "Armor shield is not displayed during first day")
        armor_ui_game.siege_day = 3
        check(armor_ui_game.enemy_visual_profile("brute")["mark"] == "armor", "Armored brute keeps recognizable armor silhouette")
        armor_ui_game.queue_free()
    if boon_scene != null:
        var escort_game = boon_scene.instantiate()
        root.add_child(escort_game)
        escort_game.siege_day = 5
        # The captain joins the healer's lane in late-day escorted formations.
        var escort_budget: Dictionary = escort_game.wave_enemy_budget(5)
        check(int(escort_budget["captain"]) > 0 and int(escort_budget["support"]) > 0, "Final wave has both commander and support")
        escort_game.wave_number = 4
        check(escort_game.start_wave(), "Late siege escort formation starts")
        var escort_captain_lane := -1
        var escort_healer_lane := -2
        for unit in escort_game.enemies:
            if str(unit.get("role", "")) == "captain":
                escort_captain_lane = int(unit["lane"])
            if str(unit.get("role", "")) == "healer" and escort_healer_lane == -2:
                escort_healer_lane = int(unit["lane"])
        check(escort_captain_lane >= 0 and escort_captain_lane == escort_healer_lane, "Late siege commander escorts the healer route")
        escort_game.queue_free()
    if boon_scene != null:
        var scout_game = boon_scene.instantiate()
        root.add_child(scout_game)
        scout_game.siege_day = 5
        scout_game.wave_number = 4
        var forecast: Dictionary = scout_game.next_wave_scouting()
        var budget_check: Dictionary = scout_game.wave_enemy_budget(5)
        check(int(forecast["wave"]) == 5 and int(forecast["healer"]) == int(budget_check["support"]) and int(forecast["captain"]) == int(budget_check["captain"]), "Scouting matches actual special-unit budget")
        var counted_brutes := 0
        for enemy_index in range(int(budget_check["ordinary"])):
            if scout_game.siege_enemy_role(5, enemy_index) == "brute":
                counted_brutes += 1
        check(int(forecast["brute"]) == counted_brutes, "Scouting heavy count uses actual enemy role selector")
        scout_game.wave_number = scout_game.SIEGE_WAVES
        check(scout_game.next_wave_scouting().is_empty(), "No scouting after final wave")
        scout_game.queue_free()
    if boon_scene != null:
        var tip_game = boon_scene.instantiate()
        root.add_child(tip_game)
        tip_game.siege_day = 4
        check(tip_game.scouting_counter_tip({"boss": 1}).begins_with("БОСС"), "Boss scouting prioritizes the biggest threat")
        check(tip_game.scouting_counter_tip({"captain": 1, "brute": 4}).begins_with("КОМАНДИР"), "Commander takes precedence over armor")
        check(tip_game.scouting_counter_tip({"brute": 3}).begins_with("БРОНЯ"), "Late-day armor suggests fire towers")
        check(tip_game.scouting_counter_tip({"runner": 3}).begins_with("РАЗВЕДЧИКИ"), "Runners suggest frost towers")
        check(tip_game.scouting_counter_tip({}).is_empty(), "No advice after final wave")
        tip_game.queue_free()
    print("TOPDOWN SMOKE RESULT: ", "PASS" if failures == 0 else str(failures) + " FAILURES")
    quit(0 if failures == 0 else 1)
