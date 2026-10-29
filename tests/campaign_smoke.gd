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
    game.dungeon_route = 1
    game.platforms = [Rect2(200.0, 420.0, 135.0, 16.0)]
    game.apply_dungeon_route()
    check(game.platforms[0].position == Vector2(222.0, 408.0), "alternate dungeon route changes platform layout")
    check(game.secret_cache_pos.x == 610.0, "secret cache placed for chosen route")
    game.reset_all()
    game.legacy_shards = 30
    game.buy_talent("hero")
    game.buy_talent("necro")
    check(game.legacy_hero_level == 1 and game.legacy_necro_level == 1, "permanent hero and necro talents purchased")
    check(game.legacy_shards == 22, "talents consume the appropriate shard costs")
    game.reset_all()
    check(game.legacy_hero_level == 1 and game.legacy_necro_level == 1, "talents persist across resets")
    game.legacy_hero_level = 0
    game.legacy_necro_level = 0
    game.legacy_shards = 0
    game.legacy_shards = 12
    game.legacy_damage_level = 0
    game.buy_legacy_damage()
    check(game.legacy_damage_level == 1 and game.legacy_shards == 8, "permanent tower damage upgrade purchase")
    game.difficulty = 3
    game.current_day = 5
    game.stones_collected = 5
    game.achievement_nightmare = false
    game.meta_paid_this_run = false
    game.award_run(true)
    check(game.achievement_nightmare and game.legacy_shards >= 28, "nightmare victory unlock and bonus reward")
    game.reset_all()
    game.difficulty = 1
    game.legacy_shards = 0
    game.legacy_damage_level = 0
    game.achievement_nightmare = false
    game.phase = "reward"
    game.current_day = 4
    game.choose_reward(2)
    check(game.legendary_boon == 2 and game.phase == "ritual", "fourth night offers legendary necromancer boon")
    game.reset_all()
    check(game.legendary_boon == -1, "legendary boon resets on new run")
    game.phase = "day"
    game.wave_count = 5
    game.spawn_timer = 0.0
    game.update_day(0.0)
    check(game.enemies.size() == 1 and bool(game.enemies[0].get("elite", false)), "sixth wave spawns an elite enemy")
    check(float(game.enemies[0]["hp"]) > 55.0, "elite enemy gets bonus health")
    game.reset_all()
    game.phase = "reward"
    game.mana = 100
    game.choose_reward(1)
    check(game.phase == "ritual" and game.mana == 135 and game.reward_mana_bonus == 1, "mana boon applies once and opens altar")
    game.choose_reward(1)
    check(game.mana == 135, "reward cannot be selected twice")
    game.phase = "reward"
    game.choose_reward(0)
    check(game.reward_bone_bonus == 1, "tower damage boon persists within run")
    game.phase = "reward"
    game.wall_hp = 45.0
    game.choose_reward(2)
    check(game.wall_hp == 80.0 and game.reward_ward_bonus == 1, "wall restoration boon")
    game.reset_all()
    check(game.reward_mana_bonus == 0 and game.reward_bone_bonus == 0 and game.reward_ward_bonus == 0, "boons reset between runs")
    game.legacy_shards = 8
    game.legacy_level = 0
    game.buy_legacy()
    check(game.legacy_level == 1 and game.legacy_shards == 6, "permanent legacy purchase")
    game.difficulty = 3
    game.start_run()
    check(game.mana == 82 and game.legacy_level == 1 and game.difficulty == 3, "new run receives permanent starting mana and preserves difficulty")
    game.current_day = 5
    game.stones_collected = 5
    game.award_run(true)
    var reward_shards: int = game.legacy_shards
    check(game.achievement_wins >= 1 and reward_shards > 6, "victory awards persistent progress")
    game.award_run(true)
    check(game.legacy_shards == reward_shards, "run rewards cannot be farmed twice")
    game.reset_all()
    game.difficulty = 1
    game.legacy_level = 0
    game.legacy_shards = 0

    game.spawn_damage_popup(Vector2(100.0, 200.0), 24.0, Color("a8e8f0"))
    check(game.damage_popups.size() == 1 and game.damage_popups[0]["text"] == "24", "floating damage feedback")
    game.spawn_damage_popup(Vector2(100.0, 200.0), 65.0, Color("ffe18a"), true)
    check(game.damage_popups.size() == 2 and game.damage_popups[1]["text"] == "CRIT! 65", "critical damage feedback")
    game.damage_popups.clear()
    game.enemies.append({"x": 240.0, "hp": 100.0, "max_hp": 100.0, "kind": "raider", "lane": 1, "slow_timer": 0.0, "slow_factor": 1.0})
    game.apply_tower_shot({"x": 150.0, "target": 240.0, "lane": 1, "damage": 22.0, "type": "bone", "level": 1, "critical": false}, 0)
    check(float(game.enemies[0].get("hit_flash", 0.0)) > 0.0, "enemy hit reaction starts")
    check(game.enemies[0].has("hit_flash_color") and float(game.enemies[0]["hp"]) < 100.0, "enemy hit reaction has color and damage")
    game.enemies.clear()
    game.phase = "day"
    game.current_day = 3
    game.wave_count = 5
    game.spawn_timer = 0.0
    game.update_day(0.0)
    check(game.enemies.size() == 1 and game.enemies[0]["kind"] == "saboteur", "sixth wave spawns saboteur")
    if game.enemies.size() > 0:
        game.enemies[0]["x"] = 400.0
        game.towers.append({"x": 420.0, "type": "bone", "lane": int(game.enemies[0].get("lane", 1)), "cooldown": 99.0, "hp": 120.0, "level": 1})
        game.update_day(0.1)
        check(float(game.towers[0].get("disabled", 0.0)) > 4.0, "saboteur disables nearby tower")
        check(bool(game.enemies[0].get("sabotaged", false)), "saboteur triggers only once")
    game.reset_all()
    game.phase = "day"
    game.mana = 500
    game.build_tower("bone", 400.0, 0)
    game.build_tower("fire", 400.0, 2)
    check(game.towers.size() == 2, "same X supports towers in different lanes")
    var old_mana: int = game.mana
    game.upgrade_tower(400.0, 0)
    check(int(game.towers[0]["level"]) == 2 and game.mana < old_mana, "tower upgrade costs mana and increases level")
    game.enemies.clear()
    game.enemies.append({"x": 400.0, "hp": 200.0, "max_hp": 200.0, "speed": 0.0, "damage": 60.0, "hit_cd": 10.0, "kind": "raider", "lane": 0, "sabotaged": false})
    game.spawn_timer = 100.0
    game.update_day(0.7)
    check(game.towers.size() == 2 and float(game.towers[0]["hp"]) < game.tower_max_hp(game.towers[0]), "enemy damages tower on its lane")
    check(float(game.towers[0].get("flash", 0.0)) > 0.0, "tower firing feedback is active")
    check(float(game.enemies[0]["x"]) == 400.0, "enemy stops to attack blocking tower")
    game.towers[0]["hp"] = 1.0
    game.update_day(0.1)
    check(game.towers.size() == 1 and int(game.towers[0]["lane"]) == 2, "destroyed tower removed only from attacked lane")
    game.selected_tower_index = 0
    var mana_before_sale: int = game.mana
    game.sell_selected_tower()
    check(game.towers.is_empty() and game.mana == mana_before_sale + 27, "selling ballista returns half of build cost")
    game.enemies.clear()
    game.enemies.append({"x": 400.0, "hp": 100.0, "max_hp": 100.0, "speed": 50.0, "damage": 5.0, "hit_cd": 10.0, "kind": "raider", "lane": 0, "sabotaged": false})
    game.enemies.append({"x": 450.0, "hp": 100.0, "max_hp": 100.0, "speed": 50.0, "damage": 5.0, "hit_cd": 10.0, "kind": "raider", "lane": 0, "sabotaged": false})
    game.enemies.append({"x": 420.0, "hp": 100.0, "max_hp": 100.0, "speed": 50.0, "damage": 5.0, "hit_cd": 10.0, "kind": "raider", "lane": 2, "sabotaged": false})
    game.apply_tower_shot({"type": "bone", "lane": 0, "level": 1, "damage": 22.0, "critical": false}, 0)
    check(float(game.enemies[0].get("slow_timer", 0.0)) >= 2.5 and float(game.enemies[0]["hp"]) < 100.0, "bone tower slows target on hit")
    var splash_before: float = float(game.enemies[1]["hp"])
    var other_lane_before: float = float(game.enemies[2]["hp"])
    game.apply_tower_shot({"type": "fire", "lane": 0, "level": 1, "damage": 65.0, "critical": false}, 0)
    check(float(game.enemies[1]["hp"]) < splash_before, "ballista splash damages nearby enemies on same lane")
    check(float(game.enemies[2]["hp"]) == other_lane_before, "ballista splash does not cross lanes")
    game.apply_tower_shot({"type": "fire", "lane": 2, "level": 1, "damage": 65.0, "critical": true}, 2)
    check(float(game.enemies[2]["hp"]) <= other_lane_before - 117.0, "critical ballista hit deals 1.8x damage")
    game.reset_all()
    game.phase = "day"
    game.mana = 500
    game.build_tower("necro", 425.0, 1)
    check(game.towers.size() == 1 and game.towers[0]["type"] == "necro", "necromancer tower builds in chosen lane")
    game.spawn_timer = 100.0
    game.update_day(0.0)
    check(game.skeletons.size() == 1 and int(game.skeletons[0]["lane"]) == 1, "necromancer summons skeleton on same lane")
    var skeleton_hp: float = float(game.skeletons[0]["hp"])
    game.enemies.clear()
    game.enemies.append({"x": 480.0, "hp": 300.0, "max_hp": 300.0, "speed": 40.0, "damage": 20.0, "hit_cd": 2.0, "kind": "raider", "lane": 1, "sabotaged": false})
    game.update_day(0.2)
    check(float(game.skeletons[0]["hp"]) < skeleton_hp, "skeleton absorbs enemy attack")
    game.begin_night()
    check(game.skeletons.is_empty(), "skeletons expire at nightfall")
    check(game.towers.is_empty(), "towers cleared at nightfall")
    # Reward drafting: exactly three unique offers from the five-kind pool.
    game.reset_all()
    game.roll_reward_offers()
    check(game.reward_offers.size() == 3, "reward draft offers three cards")
    var distinct: Dictionary = {}
    for offer in game.reward_offers:
        distinct[offer] = true
    check(distinct.size() == 3, "reward draft never duplicates a card")
    game.reward_offers.clear()
    for offer in [3, 4, 0]:
        game.reward_offers.append(offer)
    game.phase = "reward"
    game.current_day = 1
    game.stones_collected = 1
    game.souls = 0
    game.choose_reward(0)
    check(game.souls == 3 and game.phase == "ritual", "soul tribute resolves and returns to altar")
    game.reward_offers.clear()
    for offer in [4, 3, 0]:
        game.reward_offers.append(offer)
    game.phase = "reward"
    game.wall_hp = 10.0
    game.mana = 0
    game.choose_reward(0)
    check(game.mana == 65 and game.wall_hp == 1.0, "forbidden exchange keeps fortress alive")
    game.reset_all()
    check(not game.has_blood_economy_synergy() and game.kill_mana_reward() == 9, "synergy inactive without gifts")
    game.reward_bone_bonus = 1
    check(not game.has_blood_economy_synergy(), "single gift cannot activate synergy")
    game.reward_mana_bonus = 1
    check(game.has_blood_economy_synergy() and game.kill_mana_reward() == 17, "power and mana gifts unlock harvest bonus")
    check(game.kill_mana_reward(16) == 33, "synergy stacks with elite reward")
    game.reset_all()
    check(not game.has_blood_economy_synergy(), "synergy resets between runs")
    game.reset_all()
    check(not game.has_bone_bastion_synergy(), "bone bastion inactive without gifts")
    var base_skeleton_hp: float = game.summon_skeleton_hp(1)
    game.reward_bone_bonus = 1
    check(not game.has_bone_bastion_synergy(), "bone bastion requires ward gift")
    game.reward_ward_bonus = 1
    check(game.has_bone_bastion_synergy(), "bone bastion unlocks from two gifts")
    check(game.summon_skeleton_hp(1) == base_skeleton_hp + 40.0, "bone bastion boosts skeleton HP")
    game.reset_all()
    check(not game.has_bone_bastion_synergy(), "bone bastion resets with run")
    game.reset_all()
    game.phase = "night"
    game.mana = 100
    game.player = Vector2(300.0, 528.0)
    game.facing = 1.0
    game.mage["hp"] = 0.0
    game.boss_hp = 0.0
    game.night_enemies.clear()
    game.night_enemies.append({"x": 420.0, "hp": 100.0, "dir": 1.0})
    game.shadow_cleave()
    check(game.mana == 80 and game.cleave_cooldown == 6.0, "shadow cleave consumes mana and starts cooldown")
    check(game.cleave_flash_timer == 0.32 and game.cleave_flash_facing == 1.0, "shadow cleave starts directional visual feedback")
    check(float(game.night_enemies[0]["hp"]) == 52.0, "shadow cleave hits beyond basic range for double damage")
    game.shadow_cleave()
    check(game.mana == 80, "cleave cannot repeat while attack is cooling down")
    game.reset_all()
    check(game.cleave_cooldown == 0.0, "cleave cooldown resets between runs")
    game.reset_all()
    game.current_day = 2
    game.begin_night()
    check(str(game.night_enemies[0].get("kind", "")) == "charger", "night two introduces the Cursed Charger")
    game.player = Vector2(500.0, game.FLOOR - 22.0)
    var charger_test: Dictionary = game.night_enemies[0]
    charger_test["x"] = 350.0
    charger_test["charge_cd"] = 0.01
    charger_test["windup"] = 0.0
    charger_test["charging"] = 0.0
    game.night_enemies[0] = charger_test
    game.update_night(0.02)
    check(float(game.night_enemies[0].get("windup", 0.0)) > 0.6, "charger telegraphs before charging")
    charger_test = game.night_enemies[0]
    charger_test["windup"] = 0.01
    charger_test["charge_cd"] = 2.0
    charger_test["charge_dir"] = -1.0
    charger_test["charging"] = 0.0
    game.night_enemies[0] = charger_test
    var charger_x_before: float = float(game.night_enemies[0]["x"])
    game.update_night(0.02)
    check(float(game.night_enemies[0].get("charging", 0.0)) > 0.0, "charger starts lunge after telegraph")
    check(float(game.night_enemies[0]["x"]) < charger_x_before, "charger locks its attack direction at launch")
    game.reset_all()
    game.current_day = 3
    game.begin_night()
    check(str(game.night_enemies[1].get("kind", "")) == "hexer", "night three introduces the Cursed Hexer")
    game.player = Vector2(500.0, game.FLOOR - 22.0)
    game.grounded = true
    game.mage["hp"] = 0.0
    game.boss_hp = 0.0
    var hexer_test: Dictionary = game.night_enemies[1]
    hexer_test["x"] = 700.0
    hexer_test["shot_cd"] = 0.01
    hexer_test["windup"] = 0.0
    game.night_enemies[1] = hexer_test
    game.update_night(0.02)
    check(float(game.night_enemies[1].get("windup", 0.0)) > 0.7, "hexer telegraphs before firing")
    hexer_test = game.night_enemies[1]
    var locked_aim_x: float = float(hexer_test["aim_x"])
    game.player.x = 800.0
    hexer_test["windup"] = 0.01
    hexer_test["shot_cd"] = 1.0
    game.night_enemies[1] = hexer_test
    game.update_night(0.02)
    check(game.hex_bolts.size() == 1, "hexer fires a projectile after warning")
    check(float(game.hex_bolts[0]["velocity"].x) < 0.0 and locked_aim_x < 0.0, "hexer locks aim when telegraph starts")
    game.reset_all()
    game.phase = "night"
    game.stone_taken = true
    game.stones_collected = 1
    game.player = Vector2(50, 528)
    game.player_hp = 0.0
    game.hurt_cooldown = 0.0
    game.hurt(1.0)
    game.update_night(0.0)
    check(game.phase == "lose", "dead player cannot escape through portal")
    game.reset_all()
    game.phase = "ritual"
    game.stones_collected = 1
    game.mana = 110
    game.souls = 12
    game.towers.append({"x": 400.0, "type": "bone", "cooldown": 0.0})
    game.buy_upgrade("tower")
    game.buy_upgrade("ward")
    game.resolve_altar()
    check(game.current_day == 2 and game.phase == "day", "advance to day 2")
    check(game.towers.is_empty() and game.tower_power_level == 1, "towers reset but permanent upgrade persists")
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
    check(game.towers.is_empty(), "checkpoint towers reset after night")

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
