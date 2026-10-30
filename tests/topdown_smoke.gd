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
    var synergy_scene = load("res://scenes/topdown_td_prototype.tscn")
    if synergy_scene != null:
        var synergy = synergy_scene.instantiate()
        root.add_child(synergy)
        synergy.slots[0]["tower"] = "bone"
        synergy.slots[1]["tower"] = "fire"
        var burning_foe := {"burn_time": 2.0}
        check(synergy.has_adjacent_tower(0, "fire"), "Adjacent fire tower activates bone synergy")
        check(synergy.tower_synergy_damage(0, burning_foe) == 2, "Bone gains damage against burning foe beside fire tower")
        check(synergy.tower_synergy_damage(0, {"burn_time": 0.0}) == 0, "No bonus without burning")
        synergy.slots[1]["tower"] = ""
        check(synergy.tower_synergy_damage(0, burning_foe) == 0, "No bonus without nearby fire tower")
        synergy.slots[0]["tower"] = "necro"
        synergy.slots[1]["tower"] = "bone"
        check(synergy.tower_synergy_damage(0, burning_foe) == 1, "Nearby bone tower supports necromancer")
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
        check("БОСС" in scouting.upcoming_wave_summary(), "Final wave scouting warns about boss")
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
        repairs.wave_number = 3
        check(not repairs.repair_altar(), "Cannot repair after final wave")
        repairs.queue_free()
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
        for lane in td.PATHS:
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
        var first_lane: Array = td.PATHS[0]
        var first_direction: Vector2 = (first_lane[1] - first_lane[0]).normalized()
        check((first_lane[3] - first_lane[2]).normalized().distance_to(first_direction) > 0.2, "Upper lane is not straight")
        var second_lane: Array = td.PATHS[1]
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
        var boss: Dictionary = {}
        for enemy in td.enemies:
            if enemy.get("role", "") == "boss":
                boss = enemy
        check(not boss.is_empty() and boss["hp"] == 55, "Final wave has a durable altar boss")
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
        check(td.boss_feedback_time == 0.0 and td.boss_feedback_text == "" and td.summoned_spirits.is_empty(), "Defense restart clears boss feedback and necro summons")
        check(td.defense_state == "playing" and td.wave_number == 0 and td.altar_hp == 100, "TD restart resets wave and altar")
        check(td.slots[0]["tower"] == "" and td.coins == 150, "TD restart clears towers and restores economy")
        td.wave_number = 3
        td.enemies.clear()
        td._process(0.0)
        check(td.defense_state == "won", "TD victory after final cleared wave")
        check(not td.start_wave(), "TD victory blocks further waves")
        td.restart_defense()
        td.altar_hp = 10
        td.enemies.append({"lane": 0, "pos": td.PATHS[0][td.PATHS[0].size() - 1], "waypoint": td.PATHS[0].size() - 1, "hp": 1, "delay": 0.0})
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
        check(hard_td.start_wave() and hard_td.enemies[0]["hp"] == 8 and float(hard_td.enemies[0]["speed"]) > 85.0, "Nightmare TD wave has tougher faster enemies")
        hard_td.wave_number = 2
        hard_td.enemies.clear()
        check(hard_td.start_wave() and hard_td.enemies.back()["role"] == "boss" and hard_td.enemies.back()["hp"] == 85, "Nightmare boss gains durability")
        hard_td.enemies.clear()
        hard_td.queue_free()
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
        check(layout_probe.DIFFICULTY_BUTTONS.size() == 3 and layout_probe.DAY_BUTTON.position.y > layout_probe.DIFFICULTY_BUTTONS[0].end.y, "Hub difficulty and phase controls have vertical separation")
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
        check(run.phase == "hub", "Run starts at phase selection hub")
        check(not run.set_difficulty(-1) and not run.set_difficulty(3), "Invalid difficulty rejected")
        check(run.set_difficulty(2) and run.difficulty == 2, "Nightmare difficulty selectable from hub")
        check(run.set_difficulty(0), "Normal difficulty selectable from hub")
        check(run.expected_phase() == "day" and not run.start_phase("night"), "Run requires day as first phase")
        check(run.start_phase("day") and run.phase == "day", "Run can start day defense")
        check(not run.set_difficulty(2), "Difficulty cannot be changed during a run")
        check(not run.start_phase("day"), "Cannot restart active phase to duplicate run starts")
        run.finish_phase(true)
        check(run.phase == "reward" and run.completed_phases == 1, "Winning a phase grants run reward")
        var fragments_once: int = run.meta.fragments
        run.finish_phase(true)
        check(run.meta.fragments == fragments_once and run.completed_phases == 1, "Finished phase cannot grant duplicate fragments")
        check(run.choose_run_reward("bone") and run.run_damage_bonus == 1, "Run relic persists damage bonus")
        check(run.expected_phase() == "night" and not run.start_phase("day"), "Run requires night after day")
        check(run.start_phase("night") and run.phase == "night", "Run can transition to night")
        check(run.active_game.attack_damage >= 2, "Night inherits run damage relic")
        run.finish_phase(true)
        check(run.phase == "reward" and run.expected_phase() == "day", "Winning night returns to reward then day")
        check(run.choose_run_reward("gold") and run.run_gold_bonus == 30, "Gold relic persists into next defense")
        check(run.start_phase("day") and run.active_game.coins >= 180, "Day inherits run gold relic")
        run.finish_phase(true)
        check(run.choose_run_reward("ember") and run.run_fire_bonus == 1, "Ember relic enables fire tower synergy")
        check(run.start_phase("night"), "Run continues into night after fire relic")
        run.finish_phase(true)
        check(run.choose_run_reward("bone") and run.run_bone_tower_bonus == 2, "Repeated Bone relic stacks bone tower synergy")
        check(run.start_phase("day") and run.active_game.fire_synergy_bonus == 1 and run.active_game.bone_synergy_bonus == 2, "Fire and stacked Bone synergies carry into defense")
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
        check(td.enemies.size() == 2 and td.enemies[0]["hp"] == 1 and td.enemies[1]["hp"] == 1, "Bone tower pierces aligned enemies and applies stacked damage")
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
        run.phase = "reward"
        check(run.choose_run_reward("necro") and run.run_necro_kill_bonus == 3, "Necro reward adds kill gold")
        check(run.start_phase("day") and run.active_game.necro_kill_bonus == 3, "Necro reward carries into tower defense")
        run.queue_free()
        var difficulty_run = run_scene.instantiate()
        root.add_child(difficulty_run)
        check(difficulty_run.set_difficulty(2) and difficulty_run.start_phase("day"), "Nightmare difficulty propagates to day")
        check(difficulty_run.active_game.difficulty == 2, "Day receives Nightmare setting")
        var difficulty_fragments: int = difficulty_run.meta.fragments
        difficulty_run.finish_phase(true)
        check(difficulty_run.meta.fragments == difficulty_fragments + 3, "Nightmare phase awards three fragments")
        check(difficulty_run.choose_run_reward("bone") and difficulty_run.start_phase("night"), "Nightmare run proceeds to night")
        check(difficulty_run.active_game.difficulty == 2, "Night also receives Nightmare setting")
        difficulty_run.reset_run()
        check(difficulty_run.difficulty == 0, "New run defaults to normal")
        difficulty_run.queue_free()
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
    print("TOPDOWN SMOKE RESULT: ", "PASS" if failures == 0 else str(failures) + " FAILURES")
    quit(0 if failures == 0 else 1)
