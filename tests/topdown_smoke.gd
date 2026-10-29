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
        check(td.sfx != null and td.sfx.has_effect("interrupt") and td.sfx.has_effect("blast"), "TD prototype loads boss combat audio effects")
        check(not td.sfx.play_effect("unknown"), "Audio helper rejects unknown effects safely")
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
            check(td.boss_feedback_time > 0.0 and td.boss_feedback_text.begins_with("ALTAR HIT!"), "Altar blast shows temporary damage notice")
            boss["pos"] = Vector2(350, 285)
            td.hero_pos = Vector2(345, 360)
            td.tick_boss(3.2)
            var altar_before_interrupt: int = td.altar_hp
            td.hero_attack_cooldown = 0.0
            check(td.hero_attack(boss["pos"]) and boss["interrupt_hits"] == 1, "First hero strike pressures boss during telegraph")
            td.hero_attack_cooldown = 0.0
            check(td.hero_attack(boss["pos"]) and not boss["boss_warning"] and boss["boss_charge"] == 0.0, "Second hero strike interrupts boss blast")
            check(td.boss_feedback_time > 0.0 and td.boss_feedback_text == "ATTACK INTERRUPTED!", "Interrupted boss blast shows readable confirmation")
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
        td.enemies.append({"lane": 0, "pos": Vector2(1070, 285), "waypoint": 2, "hp": 1, "delay": 0.0})
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
        for i in range(5):
            restored.record_phase_clear()
        restored.record_result(true)
        check(restored.achievement_unlocked("survivor") and restored.achievement_unlocked("ritual_master"), "Six clears and win unlock milestones")
        check(restored.save_profile(), "Statistics persist in profile")
        var stats_copy = meta_script.new()
        stats_copy.save_path = profile.save_path
        check(stats_copy.load_profile() and stats_copy.runs_started == 1 and stats_copy.runs_won == 1 and stats_copy.runs_lost == 0 and stats_copy.phases_cleared == 6, "Run statistics restore from disk")
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
    var game = packed.instantiate()
    root.add_child(game)
    check(game.sfx != null and game.sfx.has_effect("hit") and game.sfx.has_effect("relic"), "Night prototype loads synthesized combat and reward audio")
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
