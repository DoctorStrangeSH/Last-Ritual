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
    if FileAccess.file_exists("user://meta_smoke_test.json"):
        DirAccess.remove_absolute(ProjectSettings.globalize_path("user://meta_smoke_test.json"))
    var game := packed.instantiate()
    game.meta_path = "user://meta_smoke_test.json"
    root.add_child(game)
    game.save_path = "user://campaign_smoke_test.json"
    game.reset_all()
    var expected_names := ["МОЩЬ БАШЕН", "ЗАПАС МАНЫ", "КРЕПОСТЬ", "ДАНЬ ДУШ", "ЗАПРЕТНЫЙ ОБМЕН"]
    var expected_details := ["+12% урона башен", "+35 маны сейчас", "+35 здоровья стен", "+3 души сейчас", "+65 маны, -15 HP стен"]
    var expected_notes := ["до конца забега", "+5 маны за врага", "восстановление стен", "на ритуал или улучшение", "риск ради силы"]
    for kind in range(5):
        check(game.reward_name(kind) == expected_names[kind] and game.reward_detail(kind) == expected_details[kind] and game.reward_note(kind) == expected_notes[kind], "reward catalog preserves offer %d" % kind)
    check(game.reward_name(99) == "НЕИЗВЕСТНЫЙ ДАР" and game.reward_detail(99) == "" and game.reward_note(99) == "", "reward catalog handles unknown kind")
    check(game.tower_ability_description("bone", 1) == "Замедление 2.5 с", "bone tower ability description preserved")
    check(game.tower_ability_description("bone", 3) == "Замедление 3.2 с", "upgraded bone tower description preserved")
    check(game.tower_ability_description("necro", 1) == "Скелет: 65 HP / 6 с", "necro tower ability description preserved")
    check(game.tower_ability_description("necro", 3) == "Скелет: 125 HP / 6 с", "upgraded necro tower description preserved")
    check(game.tower_ability_description("fire", 1) == "Крит 18% + взрыв", "fire tower ability description preserved")
    check(game.tower_ability_description("fire", 3) == "Крит 26% + взрыв", "upgraded fire tower description preserved")
    check(game.tower_sell_refund({"type": "bone", "level": 1}) == 15, "bone tower level one refund")
    check(game.tower_sell_refund({"type": "bone", "level": 2}) == 27, "bone tower level two refund")
    check(game.tower_sell_refund({"type": "fire", "level": 1}) == 27, "ballista level one refund")
    check(game.tower_sell_refund({"type": "fire", "level": 3}) == 65, "ballista level three refund")
    check(game.tower_sell_refund({"type": "necro", "level": 1}) == 32, "necromancer level one refund")
    check(game.tower_sell_refund({"type": "necro", "level": 3}) == 70, "necromancer level three refund")
    check(not game.shadow_relic, "relic absent at fresh run")
    game.phase = "night"
    game.mana = 100
    game.shadow_dash()
    check(game.dash_cooldown == 2.5, "dash cooldown without relic is unchanged")
    game.reset_all()
    game.shadow_relic = true
    game.phase = "night"
    game.mana = 100
    game.shadow_dash()
    check(game.dash_cooldown == 1.25, "Ashen Step relic halves dash cooldown")
    game.reset_all()
    check(not game.shadow_relic, "relic does not leak between runs")
    game.reset_all()
    game.current_day = 4
    game.begin_night()
    game.player = Vector2(95.0, game.FLOOR - 22.0)
    game.mage["hp"] = 0.0
    game.boss_hp = 0.0
    game.shadow_relic = true
    game.night_enemies[2]["hp"] = 0.0
    game.update_night(0.0)
    check(game.relic_choice_pending and not game.blood_mantle, "elite opens relic selection instead of auto-granting")
    var relic_pause_key := InputEventKey.new()
    relic_pause_key.keycode = KEY_P
    relic_pause_key.pressed = true
    game._unhandled_input(relic_pause_key)
    check(not game.paused and game.relic_choice_pending, "pause key cannot block active relic selection")
    var relic_heal_key := InputEventKey.new()
    relic_heal_key.keycode = KEY_H
    relic_heal_key.pressed = true
    var mana_during_choice: int = game.mana
    game._unhandled_input(relic_heal_key)
    check(game.mana == mana_during_choice, "night skill hotkeys ignored while choosing relic")
    game.choose_relic(0)
    check(game.relic_choice_pending, "already-owned relic cannot be chosen")
    game.choose_relic(1)
    check(game.blood_mantle and not game.relic_choice_pending, "player choice grants Blood Mantle")
    game.player_hp = 70.0
    game.night_enemies[0]["hp"] = 0.0
    game.update_night(0.0)
    check(game.player_hp == 76.0, "Blood Mantle restores six HP on regular kill")
    game.player_hp = 98.0
    check(game.night_enemies.size() == 1, "only one regular enemy remains after two deaths")
    game.night_enemies[0]["hp"] = 0.0
    game.update_night(0.0)
    check(game.player_hp == 100.0, "Blood Mantle healing caps at max HP")
    game.reset_all()
    check(not game.blood_mantle, "Blood Mantle resets on new run")
    check(not game.relic_choice_pending, "pending relic selection resets on new run")
    game.reset_all()
    game.phase = "night"
    game.mage = {"x": 1000.0, "hp": 0.0, "cooldown": 1.0}
    game.boss_hp = 0.0
    game.night_enemies.clear()
    game.night_enemies.append({"x": 140.0, "hp": 100.0, "dir": 1.0})
    game.player = Vector2(95.0, game.FLOOR - 22.0)
    game.facing = 1.0
    game.attack()
    check(is_equal_approx(float(game.night_enemies[0]["hp"]), 76.0), "base melee damage remains unchanged")
    game.reset_all()
    game.phase = "night"
    game.mage = {"x": 1000.0, "hp": 0.0, "cooldown": 1.0}
    game.boss_hp = 0.0
    game.night_enemies.clear()
    game.night_enemies.append({"x": 140.0, "hp": 100.0, "dir": 1.0})
    game.player = Vector2(95.0, game.FLOOR - 22.0)
    game.facing = 1.0
    game.relic_choice_pending = true
    game.choose_relic(2)
    check(game.rage_shard and not game.relic_choice_pending, "player may choose Rage Shard")
    game.attack()
    check(is_equal_approx(float(game.night_enemies[0]["hp"]), 70.0), "Rage Shard increases hero melee damage by 25 percent")
    game.reset_all()
    check(not game.rage_shard, "Rage Shard resets between runs")
    game.reset_all()
    game.boss_pos = Vector2(1015.0, game.FLOOR - 46.0)
    check(game.boss_strike_hits(Vector2(1015.0, game.FLOOR - 25.0)), "boss warning covers strike center")
    check(game.boss_strike_hits(Vector2(1099.0, game.FLOOR - 25.0)), "boss warning covers near edge")
    check(not game.boss_strike_hits(Vector2(1102.0, game.FLOOR - 25.0)), "boss attack misses outside horizontal warning")
    check(not game.boss_strike_hits(Vector2(1015.0, game.FLOOR - 110.0)), "boss attack misses above warning")
    game.reset_all()
    game.current_day = 1
    game.begin_night()
    game.mage["hp"] = 0.0
    game.night_enemies.clear()
    game.boss_hp = 120.0
    game.boss_windup = 0.01
    game.boss_strike_timer = 2.0
    game.player = Vector2(game.boss_pos.x, game.FLOOR - 22.0)
    var hp_before_boss_strike: float = game.player_hp
    game.update_night(0.02)
    check(game.player_hp == hp_before_boss_strike - 24.0, "boss windup expiration deals one telegraphed hit inside warning")
    game.hurt_cooldown = 0.0
    game.boss_windup = 0.01
    game.boss_strike_timer = 2.0
    game.player = Vector2(game.boss_pos.x - 120.0, game.FLOOR - 22.0)
    var hp_before_boss_dodge: float = game.player_hp
    game.update_night(0.02)
    check(game.player_hp == hp_before_boss_dodge, "moving outside boss warning dodges strike")
    game.reset_all()
    game.current_day = 1
    game.begin_night()
    game.mage["hp"] = 0.0
    game.night_enemies.clear()
    game.boss_hp = 0.0
    game.player = Vector2(1010.0, 465.0)
    game.update_night(0.0)
    check(game.stone_taken and game.stones_collected == 1, "defeated guardian grants one Abyss Stone")
    game.update_night(0.0)
    check(game.stones_collected == 1, "Abyss Stone cannot be collected twice")
    game.reset_all()
    game.reset_all()
    game.current_day = 3
    game.boss_pos = Vector2(700.0, game.FLOOR - 46.0)
    check(game.boss_strike_half_width() == 87.0 and is_equal_approx(game.boss_windup_duration(), 0.75), "early guardians retain existing strike geometry and timing")
    check(not game.boss_strike_hits(Vector2(800.0, game.FLOOR - 22.0)), "early guardian strike misses at 100 pixels")
    game.current_day = 4
    check(game.boss_strike_half_width() == 130.0 and is_equal_approx(game.boss_windup_duration(), 1.1), "late guardians telegraph wider, slower shockwave")
    check(game.boss_strike_hits(Vector2(800.0, game.FLOOR - 22.0)), "late shockwave reaches 100 pixels")
    check(not game.boss_strike_hits(Vector2(831.0, game.FLOOR - 22.0)), "late shockwave has dodgeable edge")
    game.reset_all()
    # Exercise every night and all three dungeon route variations.
    for night in range(1, 6):
        for route in range(3):
            game.reset_all()
            game.current_day = night
            game.begin_night()
            game.dungeon_route = route
            # Rebuild the base geometry before applying a different route on this night.
            if route != 0:
                game.reset_all()
                game.current_day = night
                game.begin_night()
                game.dungeon_route = route
                game.apply_dungeon_route()
            check(game.platforms.size() == 4, "night %d route %d has four platforms" % [night, route])
            check(game.secret_cache_pos.x >= 530.0 and game.secret_cache_pos.x <= 615.0, "night %d route %d keeps secret cache on map" % [night, route])
            for platform in game.platforms:
                check(platform.position.x > 0.0 and platform.end.x < game.W and platform.position.y > 250.0 and platform.end.y <= game.FLOOR, "night %d route %d platform stays in bounds" % [night, route])
            check(game.trap_positions.size() >= 2, "night %d route %d contains hazards" % [night, route])
    game.reset_all()
    # Every guardian must allow one stone pickup, with no duplicate on subsequent frames.
    for guardian_night in range(1, 6):
        game.reset_all()
        game.current_day = guardian_night
        game.stones_collected = guardian_night - 1
        game.begin_night()
        game.mage["hp"] = 0.0
        game.night_enemies.clear()
        game.boss_hp = 0.0
        game.player = Vector2(1010.0, 465.0)
        game.update_night(0.0)
        check(game.stone_taken and game.stones_collected == guardian_night, "night %d guardian grants exactly one stone" % guardian_night)
        game.update_night(0.0)
        check(game.stones_collected == guardian_night, "night %d cannot award a duplicate stone" % guardian_night)
    game.reset_all()
    game.reset_all()
    game.current_day = 1
    check(is_equal_approx(game.trap_cycle_duration(), 3.1) and is_equal_approx(game.trap_danger_start(), 2.1), "early night keeps existing trap rhythm")
    game.trap_clock = 2.0
    check(not game.trap_is_dangerous(), "early trap stays safe before 2.1 seconds")
    game.trap_clock = 2.2
    check(game.trap_is_dangerous(), "early trap activates after warning")
    game.current_day = 4
    check(is_equal_approx(game.trap_cycle_duration(), 2.7) and is_equal_approx(game.trap_warning_start(), 1.2), "late night traps cycle faster with visible warning")
    game.trap_clock = 1.7
    check(not game.trap_is_dangerous(), "late trap is safe in warning stage")
    game.trap_clock = 1.9
    check(game.trap_is_dangerous(), "late trap becomes dangerous after 1.8 seconds")
    game.trap_clock = 2.8
    check(not game.trap_is_dangerous(), "late trap danger resets on new cycle")
    game.reset_all()
    game.reset_all()
    game.current_day = 4
    game.begin_night()
    check(game.night_enemies.size() == 3 and is_equal_approx(float(game.night_enemies[2]["hp"]), 180.0), "fourth night retains regular elite strength")
    check(is_equal_approx(float(game.night_enemies[2]["strike_cd"]), 2.0), "fourth night retains regular elite delay")
    game.reset_all()
    game.current_day = 5
    game.begin_night()
    check(game.night_enemies.size() == 3 and is_equal_approx(float(game.night_enemies[2]["hp"]), 240.0), "fifth tomb elite has unique stronger variant")
    check(is_equal_approx(float(game.night_enemies[2]["strike_cd"]), 1.5), "fifth tomb elite reacts earlier")
    game.reset_all()
    game.reset_all()
    game.current_day = 1
    game.begin_night()
    check(game.night_controls_hint_visible(), "first night briefly shows mouse controls")
    game.trap_clock = 8.1
    check(not game.night_controls_hint_visible(), "night controls tutorial hides after eight seconds")
    game.trap_clock = 0.0
    game.stone_taken = true
    check(not game.night_controls_hint_visible(), "night control hint hides after stone pickup")
    game.reset_all()
    game.current_day = 2
    game.begin_night()
    check(not game.night_controls_hint_visible(), "later nights start with uncluttered HUD")
    game.reset_all()
    game.reset_all()
    game.cleave_cooldown = 6.0
    check(is_equal_approx(game.cleave_charge_ratio(), 0.0), "cleave HUD meter empty after skill use")
    game.cleave_cooldown = 3.0
    check(is_equal_approx(game.cleave_charge_ratio(), 0.5), "cleave HUD meter shows half cooldown")
    game.cleave_cooldown = 0.0
    check(is_equal_approx(game.cleave_charge_ratio(), 1.0), "cleave HUD meter full when ready")
    game.reset_all()
    game.reset_all()
    game.phase = "night"
    game.player_hp = 26.0
    check(not game.night_low_hp_warning_visible(), "critical HP warning hidden above threshold")
    game.player_hp = 25.0
    check(game.night_low_hp_warning_visible(), "critical HP warning shown at threshold")
    game.player_hp = 0.0
    check(not game.night_low_hp_warning_visible(), "critical HP warning hidden when defeated")
    game.phase = "day"
    game.player_hp = 20.0
    check(not game.night_low_hp_warning_visible(), "night HP warning hidden outside dungeon")
    game.reset_all()
    game.reset_all()
    game.phase = "night"
    game.player_hp = 25.0
    check(game.night_low_hp_warning_visible(), "compact night HUD preserves low HP warning")
    game.player_hp = 26.0
    check(not game.night_low_hp_warning_visible(), "night warning clears when HP recovers")
    game.current_day = 4
    game.trap_clock = 1.9
    check(game.trap_is_dangerous(), "night HUD hazard indicator uses active trap state")
    game.reset_all()
    check(game.reward_card_at(Vector2(150.0, 300.0)) == 0, "reward card hitbox selects first card")
    check(game.reward_card_at(Vector2(450.0, 300.0)) == 1, "reward card hitbox selects middle card")
    check(game.reward_card_at(Vector2(760.0, 300.0)) == 2, "reward card hitbox selects third card")
    check(game.reward_card_at(Vector2(425.0, 300.0)) == -1, "reward card gap is not clickable")
    check(game.reward_card_at(Vector2(150.0, 460.0)) == -1, "outside reward panel does not choose card")
    game.reset_all()
    game.towers.append({"x": 480.0, "type": "bone", "lane": 1, "level": 1, "hp": 120.0, "cooldown": 0.0})
    var tower_center_y: float = game.FLOOR + float(game.LANE_OFFSETS[1]) - 50.0
    check(game.tower_at_point(Vector2(480.0, tower_center_y)) == 0, "tower hover matches center of clickable sprite")
    check(game.tower_at_point(Vector2(515.0, tower_center_y)) == 0, "tower hover includes clickable sprite edge")
    check(game.tower_at_point(Vector2(516.0, tower_center_y)) == -1, "tower hover excludes outside edge")
    check(game.tower_at_point(Vector2(480.0, game.FLOOR + 30.0)) == -1, "tower hover excludes bottom HUD")
    game.reset_all()
    check(game.build_card_at(Vector2(20.0, 580.0)) == 0, "first build card highlights within its bounds")
    check(game.build_card_at(Vector2(200.0, 580.0)) == 1, "second build card highlights within its bounds")
    check(game.build_card_at(Vector2(380.0, 580.0)) == 2, "third build card highlights within its bounds")
    check(game.build_card_at(Vector2(188.0, 580.0)) == -1, "build card gap has no hover highlight")
    check(game.build_card_at(Vector2(20.0, 550.0)) == -1, "arena does not highlight palette")
    game.reset_all()
    check(not game.selected_tower_can_upgrade(), "upgrade button disabled without tower")
    game.towers.append({"x": 480.0, "type": "bone", "lane": 1, "level": 1, "hp": 120.0})
    game.selected_tower_index = 0
    game.mana = 24
    check(not game.selected_tower_can_upgrade(), "upgrade button disabled without enough mana")
    game.mana = 25
    check(game.selected_tower_can_upgrade(), "upgrade button active when affordable")
    game.towers[0]["level"] = 3
    check(not game.selected_tower_can_upgrade(), "upgrade button disabled at max level")
    game.reset_all()
    game.reset_all()
    check(not game.selected_tower_can_sell(), "sell button disabled with no selection")
    game.towers.append({"x": 480.0, "type": "bone", "lane": 1, "level": 1, "hp": 120.0})
    game.selected_tower_index = 0
    check(game.selected_tower_can_sell(), "sell button enabled for selected tower")
    game.selected_tower_index = 1
    check(not game.selected_tower_can_sell(), "sell button disabled when selection index out of bounds")
    game.reset_all()
    check(game.current_day == 1, "initial day")
    game.phase = "night"
    game.difficulty = 2
    game.spectral_patrol_clock = 3.0
    game.player = game.spectral_patrol_position()
    check(game.spectral_patrol_active() and game.spectral_patrol_hits_player(), "spectral patrol activates and detects collision")
    game.spectral_patrol_clock = 0.5
    check(not game.spectral_patrol_active() and not game.spectral_patrol_hits_player(), "spectral patrol has a safe interval")
    game.difficulty = 1
    game.current_day = 1
    game.spectral_patrol_clock = 3.0
    check(not game.spectral_patrol_enabled(), "spectral patrol disabled on early normal nights")
    game.reset_all()

    game.phase = "night"
    game.dungeon_route_chosen = true
    game.blood_shrine_used = false
    game.stone_taken = false
    game.player = Vector2(530.0, game.FLOOR - 26.0)
    game.player_hp = 80.0
    game.mana = 30
    game.souls = 0
    check(game.use_blood_shrine(), "blood shrine activation")
    check(game.player_hp == 55.0 and game.mana == 85 and game.souls == 2, "blood shrine trade")
    check(not game.use_blood_shrine() and game.mana == 85, "shrine can only be claimed once")
    game.reset_all()
    check(not game.blood_shrine_used, "shrine resets each run")
    game.reset_all()
    game.dungeon_omen = 1
    game.trap_positions = [375.0, 775.0]
    game.night_enemies.clear()
    game.night_enemies.append({"x": 360.0, "hp": 100.0, "dir": -1.0})
    game.apply_dungeon_omen()
    check(game.trap_positions.size() == 3 and is_equal_approx(float(game.night_enemies[0]["hp"]), 122.0), "cursed dungeon omen increases hazards and enemy HP")
    game.reset_all()
    game.dungeon_omen = 2
    game.night_enemies.clear()
    game.night_enemies.append({"x": 360.0, "hp": 100.0, "dir": -1.0})
    game.apply_dungeon_omen()
    check(game.omen_cache_bonus and is_equal_approx(float(game.night_enemies[0]["hp"]), 110.0), "treasure omen boosts optional cache and enemies")
    game.reset_all()
    game.dungeon_omen = 3
    game.night_enemies.clear()
    game.night_enemies.append({"x": 360.0, "hp": 100.0, "dir": -1.0})
    game.boss_hp = 200.0
    game.apply_dungeon_omen()
    check(game.dungeon_omen_name() == "Лунное затмение", "lunar eclipse omen has its own name")
    check(is_equal_approx(float(game.night_enemies[0]["hp"]), 130.0) and is_equal_approx(game.boss_hp, 250.0), "lunar eclipse scales regular enemy and boss HP")
    game.reset_all()

    game.begin_night()
    check(not game.dungeon_route_chosen and game.secret_cache_pos.x > 0.0, "night opens route choice and initializes cache")
    game.mana = 70
    game.choose_dungeon_route(0)
    check(game.dungeon_route_chosen and game.dungeon_route == 0 and game.mana == 90, "shadow route awards mana")
    game.choose_dungeon_route(2)
    check(game.dungeon_route == 0 and game.mana == 90, "route cannot be selected twice")
    game.begin_night()
    game.boss_hp = 200.0
    game.choose_dungeon_route(1)
    check(is_equal_approx(game.boss_hp, 170.0), "hunter route weakens boss")
    game.begin_night()
    game.souls = 0
    game.choose_dungeon_route(2)
    check(game.souls == 2 and game.dungeon_route == 2, "relic route awards souls")
    game.reset_all()
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
    game.attack_cooldown = 0.31
    game.hurt_cooldown = 0.92
    game.swing_timer = 0.12
    game.dash_cooldown = 1.8
    game.dash_trail = 0.3
    game.cleave_cooldown = 4.1
    game.cleave_flash_timer = 0.2
    game.empowered_strike = true
    game.begin_night()
    check(game.attack_cooldown == 0.0 and game.hurt_cooldown == 0.0 and game.swing_timer == 0.0, "night begins without stale attack and damage cooldowns")
    check(game.dash_cooldown == 0.0 and game.dash_trail == 0.0, "night begins without stale dash effects")
    check(game.cleave_cooldown == 0.0 and game.cleave_flash_timer == 0.0 and not game.empowered_strike, "night begins without stale cleave effects")
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
    check(game.night_enemies.size() == 3 and str(game.night_enemies[2].get("kind", "")) == "elite_warden", "third night adds optional elite warden")
    game.player = Vector2(610.0, game.FLOOR - 22.0)
    game.mage["hp"] = 0.0
    game.boss_hp = 0.0
    var elite_test: Dictionary = game.night_enemies[2]
    elite_test["strike_cd"] = 0.0
    game.night_enemies[2] = elite_test
    game.update_night(0.02)
    check(float(game.night_enemies[2].get("windup", 0.0)) > 0.9, "elite warden telegraphs area attack")
    game.player.x = 900.0
    elite_test = game.night_enemies[2]
    elite_test["windup"] = 0.01
    game.night_enemies[2] = elite_test
    var hp_before_elite_dodge: float = game.player_hp
    game.update_night(0.02)
    check(game.player_hp == hp_before_elite_dodge, "elite warden area attack can be dodged")
    elite_test = game.night_enemies[2]
    elite_test["hp"] = 0.0
    game.night_enemies[2] = elite_test
    var mana_before_elite: int = game.mana
    var souls_before_elite: int = game.souls
    game.update_night(0.0)
    check(game.mana == mana_before_elite + 45 and game.souls == souls_before_elite + 5, "optional elite pays unique reward")
    check(game.relic_choice_pending and not game.shadow_relic, "first elite offers relic choice")
    game.choose_relic(0)
    check(game.shadow_relic and not game.relic_choice_pending, "first elite grants selected Ashen Step relic")
    game.update_night(0.0)
    check(game.mana == mana_before_elite + 45 and game.souls == souls_before_elite + 5, "elite reward cannot be collected twice")
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
    check(game.hex_bolts.is_empty(), "full reset clears cursed bolts")
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
    game.shadow_relic = true
    game.blood_mantle = true
    game.rage_shard = true
    check(game.save_campaign(), "checkpoint save")
    game.reset_all()
    check(game.load_campaign(), "checkpoint load")
    check(game.phase == "ritual" and game.current_day == 2 and game.stones_collected == 2, "checkpoint phase and progress")
    check(game.shadow_relic, "checkpoint restores run-long relic")
    check(game.blood_mantle, "checkpoint restores Blood Mantle")
    check(game.rage_shard, "checkpoint restores Rage Shard")
    check(game.mana == 93 and game.souls == 11 and game.wall_hp == 78.0, "checkpoint resources")
    check(game.towers.is_empty(), "checkpoint towers reset after night")

    var corrupt := FileAccess.open("user://campaign_smoke_test.json", FileAccess.WRITE)
    corrupt.store_string("{not valid json")
    corrupt.close()
    check(not game.load_campaign(), "corrupt save is rejected")
    var invalid_relic := {"version": 1, "day": 2, "stones": 2, "mana": 90, "souls": 10, "wall_hp": 90, "tower_power": 0, "wall_ward": 0, "towers": [], "shadow_relic": "yes"}
    var relic_file := FileAccess.open("user://campaign_smoke_test.json", FileAccess.WRITE)
    relic_file.store_string(JSON.stringify(invalid_relic))
    relic_file.close()
    check(not game.load_campaign(), "invalid relic save type is rejected")
    invalid_relic["shadow_relic"] = true
    invalid_relic["blood_mantle"] = "yes"
    relic_file = FileAccess.open("user://campaign_smoke_test.json", FileAccess.WRITE)
    relic_file.store_string(JSON.stringify(invalid_relic))
    relic_file.close()
    check(not game.load_campaign(), "invalid Blood Mantle save type rejected")
    invalid_relic["blood_mantle"] = true
    invalid_relic["rage_shard"] = "yes"
    relic_file = FileAccess.open("user://campaign_smoke_test.json", FileAccess.WRITE)
    relic_file.store_string(JSON.stringify(invalid_relic))
    relic_file.close()
    check(not game.load_campaign(), "invalid Rage Shard save type rejected")
    check(game.shadow_relic and game.mana == 93, "invalid relic save preserves prior checkpoint")
    var invalid := {"version": 1, "day": 2, "stones": 2, "mana": 90, "souls": 10, "wall_hp": 90, "tower_power": 0, "wall_ward": 0, "towers": [{"x": 400.0, "type": "bone"}, {"x": 420.0, "type": "bone"}]}
    var bad_file := FileAccess.open("user://campaign_smoke_test.json", FileAccess.WRITE)
    bad_file.store_string(JSON.stringify(invalid))
    bad_file.close()
    check(not game.load_campaign(), "overlapping saved towers rejected")
    invalid["towers"] = [{"x": 400.0, "type": "bone", "lane": 1.5}]
    bad_file = FileAccess.open("user://campaign_smoke_test.json", FileAccess.WRITE)
    bad_file.store_string(JSON.stringify(invalid))
    bad_file.close()
    check(not game.load_campaign(), "fractional saved tower lane rejected")
    invalid["towers"] = [{"x": 400.0, "type": "bone", "level": "2"}]
    bad_file = FileAccess.open("user://campaign_smoke_test.json", FileAccess.WRITE)
    bad_file.store_string(JSON.stringify(invalid))
    bad_file.close()
    check(not game.load_campaign(), "non-numeric saved tower level rejected")
    invalid["towers"] = [{"x": 400.0, "type": "bone", "hp": "90"}]
    bad_file = FileAccess.open("user://campaign_smoke_test.json", FileAccess.WRITE)
    bad_file.store_string(JSON.stringify(invalid))
    bad_file.close()
    check(not game.load_campaign(), "non-numeric saved tower HP rejected")
    invalid["towers"] = []
    invalid["reward_bone"] = "2"
    bad_file = FileAccess.open("user://campaign_smoke_test.json", FileAccess.WRITE)
    bad_file.store_string(JSON.stringify(invalid))
    bad_file.close()
    check(not game.load_campaign(), "non-numeric saved reward rejected")
    invalid["reward_bone"] = 1.5
    bad_file = FileAccess.open("user://campaign_smoke_test.json", FileAccess.WRITE)
    bad_file.store_string(JSON.stringify(invalid))
    bad_file.close()
    check(not game.load_campaign(), "fractional saved reward rejected")
    invalid.erase("reward_bone")
    invalid["legendary_boon"] = 3
    bad_file = FileAccess.open("user://campaign_smoke_test.json", FileAccess.WRITE)
    bad_file.store_string(JSON.stringify(invalid))
    bad_file.close()
    check(not game.load_campaign(), "out-of-range legendary boon rejected")
    invalid.erase("legendary_boon")
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

    game.difficulty = 3
    game.legacy_shards = 42
    game.achievement_wins = 6
    game.achievement_nightmare = true
    game.save_meta()
    game.difficulty = 1
    game.legacy_shards = 0
    game.achievement_wins = 0
    game.achievement_nightmare = false
    game.load_meta()
    check(game.difficulty == 3 and game.legacy_shards == 42 and game.achievement_wins == 6 and game.achievement_nightmare, "valid persistent progress round-trips")

    var bad_meta := FileAccess.open("user://meta_smoke_test.json", FileAccess.WRITE)
    bad_meta.store_string(JSON.stringify({"difficulty": 4, "shards": "100", "wins": 99}))
    bad_meta.close()
    game.difficulty = 2
    game.legacy_shards = 17
    game.achievement_wins = 3
    game.load_meta()
    check(game.difficulty == 2 and game.legacy_shards == 17 and game.achievement_wins == 3, "malformed persistent progress rejected atomically")

    bad_meta = FileAccess.open("user://meta_smoke_test.json", FileAccess.WRITE)
    bad_meta.store_string(JSON.stringify({"difficulty": 2.5, "shards": 100}))
    bad_meta.close()
    game.load_meta()
    check(game.difficulty == 2 and game.legacy_shards == 17, "fractional persistent difficulty rejected")

    bad_meta = FileAccess.open("user://meta_smoke_test.json", FileAccess.WRITE)
    bad_meta.store_string(JSON.stringify({"nightmare": "true"}))
    bad_meta.close()
    game.load_meta()
    check(game.difficulty == 2 and game.legacy_shards == 17, "non-boolean persistent achievement rejected")

    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://meta_smoke_test.json"))
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://campaign_smoke_test.json"))
    game.queue_free()
    print("Failures: ", failures)
    quit(1 if failures > 0 else 0)
