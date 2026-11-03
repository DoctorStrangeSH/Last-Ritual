extends SceneTree
## Night trophies: catalogue, each day effect, the elite-room pick at night and
## carrying trophies through run_loop. Headless; never touches the real profile.

const TROPHIES = preload("res://scripts/run_trophies.gd")
const TD_SCENE = preload("res://scenes/topdown_td_prototype.tscn")
const NIGHT_SCENE = preload("res://scenes/topdown_night_prototype.tscn")
const RUN_SCENE = preload("res://scenes/run_loop.tscn")
var failures := 0

func check(value: bool, description: String) -> void:
    if not value:
        failures += 1
        push_error("FAIL " + description)
    else:
        print("PASS " + description)

func _initialize() -> void:
    call_deferred("run")

func day(trophies: Array):
    var game = TD_SCENE.instantiate()
    root.add_child(game)
    game.set_process(false)
    game.set_fortress_map_seed(3)
    game.apply_run_trophies(trophies)
    return game

func drop(node) -> void:
    node.get_parent().remove_child(node)
    node.free()

func run() -> void:
    catalogue()
    day_effects()
    night_pick()
    run_loop_carry()
    print("RUN TROPHIES RESULT: ", "PASS" if failures == 0 else "FAIL")
    quit(1 if failures > 0 else 0)

func catalogue() -> void:
    check(TROPHIES.ORDER.size() == 8 and TROPHIES.CATALOG.size() == 8, "Eight trophies in catalogue")
    for id in TROPHIES.ORDER:
        check(TROPHIES.CATALOG.has(id) and TROPHIES.title(id) != "" and TROPHIES.effect(id) != "", "Trophy has title and effect: " + id)
    var icons := load(TROPHIES.ICON_PATH) as Texture2D
    check(icons != null and icons.get_size() == Vector2(TROPHIES.ICON_SIZE * 8, TROPHIES.ICON_SIZE), "Icon strip holds 8 frames of 24x24")
    var first: Array[String] = TROPHIES.offers(42, [])
    check(first == TROPHIES.offers(42, []), "Offers are deterministic for a seed")
    check(first.size() == 3, "Three offers while the catalogue is full")
    var curses := 0
    for id in first:
        curses += 1 if TROPHIES.is_curse(id) else 0
    check(curses == 1, "Exactly one curse among the offers")
    var seen := {}
    for seed in range(64):
        for id in TROPHIES.offers(seed, []):
            seen[id] = true
    check(seen.size() == 8, "Every trophy can be offered")
    var owned: Array = ["cursed_idol", "blood_millstone", "warden_stone"]
    var rest: Array[String] = TROPHIES.offers(7, owned)
    check(rest.size() == 3 and not rest.any(func(id): return owned.has(id)), "Owned trophies are never offered again; blessings fill in")
    check(TROPHIES.offers(1, TROPHIES.ORDER).is_empty(), "No offers once everything is owned")
    check(TROPHIES.sanitize(["junk", "phoenix_ash", "warlord_skull", "phoenix_ash"]) == ["warlord_skull", "phoenix_ash"], "Sanitize drops junk and duplicates")

func day_effects() -> void:
    # Warlord Skull: +2 vs captains and the boss only.
    var game = day(["warlord_skull"])
    game.slots[0]["tower"] = "bone"
    game.slots[0]["level"] = 1
    var plain = day([])
    plain.slots[0]["tower"] = "bone"
    plain.slots[0]["level"] = 1
    var boss := {"role": "boss", "pos": Vector2.ZERO}
    var grunt := {"role": "grunt", "pos": Vector2.ZERO}
    check(game.tower_synergy_damage(0, boss) == plain.tower_synergy_damage(0, boss) + 2, "Warlord Skull adds 2 against the boss")
    check(game.tower_synergy_damage(0, grunt) == plain.tower_synergy_damage(0, grunt), "Warlord Skull ignores ordinary enemies")
    drop(game)
    drop(plain)

    # Grave Lantern: +12% range, used by targeting.
    game = day(["grave_lantern"])
    check(is_equal_approx(game.tower_range("bone"), 135.0 * TROPHIES.LANTERN_RANGE) and TROPHIES.LANTERN_RANGE > 1.0, "Grave Lantern extends tower range")
    game.slots[0]["tower"] = "bone"
    game.slots[0]["level"] = 1
    var far: Vector2 = Vector2(game.slots[0]["pos"]) + Vector2(140, 0)
    game.enemies.append({"pos": far, "hp": 5, "max_hp": 5, "role": "grunt", "delay": 0.0, "lane": 0, "waypoint": 1, "speed": 0.0})
    check(not game.choose_tower_target(0).is_empty(), "Lantern lets a tower target an enemy beyond its base range")
    drop(game)
    game = day([])
    game.slots[0]["tower"] = "bone"
    game.slots[0]["level"] = 1
    game.enemies.append({"pos": Vector2(game.slots[0]["pos"]) + Vector2(140, 0), "hp": 5, "max_hp": 5, "role": "grunt", "delay": 0.0, "lane": 0, "waypoint": 1, "speed": 0.0})
    check(game.choose_tower_target(0).is_empty(), "Without the lantern that enemy is out of range")
    drop(game)

    # Looter's Satchel: once per cleared wave.
    game = day(["looter_satchel"])
    var coins_before: int = game.coins
    game.wave_number = 1
    check(game.settle_wave_trophies() == TROPHIES.SATCHEL_GOLD and game.settle_wave_trophies() == 0, "Satchel pays once per cleared wave")
    game.enemies.append({"pos": Vector2.ZERO, "hp": 1, "max_hp": 1, "role": "grunt", "delay": 0.0, "lane": 0, "waypoint": 1, "speed": 0.0})
    game.wave_number = 2
    check(game.settle_wave_trophies() == 0, "Satchel waits until the wave is cleared")
    check(game.coins == coins_before + TROPHIES.SATCHEL_GOLD, "Satchel gold is added to coins")
    drop(game)

    # Warden Stone: +15 each morning, capped at 100.
    game = TD_SCENE.instantiate()
    root.add_child(game)
    game.set_process(false)
    game.altar_hp = 50
    game.apply_run_trophies(["warden_stone"])
    check(game.altar_hp == 50 + TROPHIES.WARDEN_HEAL, "Warden Stone heals the altar in the morning")
    game.altar_hp = 95
    game.apply_run_trophies(["warden_stone"])
    check(game.altar_hp == 100, "Warden Stone never heals above 100")
    drop(game)

    # Phoenix Ash: the first escape of the day is harmless, the second is not.
    game = day(["phoenix_ash"])
    var path: Array = game.paths[0]
    for i in range(2):
        game.enemies.append({"lane": 0, "pos": path[path.size() - 1], "waypoint": path.size(), "hp": 3, "max_hp": 3, "speed": 80.0, "role": "grunt", "delay": 0.0})
        game.advance_enemies(0.01)
    check(game.altar_hp == 90 and game.phoenix_ash_spent and game.enemies_escaped == 2, "Phoenix Ash absorbs exactly one escape per day")
    game.apply_run_trophies(["phoenix_ash"])
    check(not game.phoenix_ash_spent, "Phoenix Ash recharges each morning")
    drop(game)

    # Soul Lantern: necro spirits arrive one kill earlier.
    for with_lantern in [false, true]:
        game = day(["soul_lantern"] if with_lantern else [])
        game.slots[0]["tower"] = "necro"
        game.slots[0]["level"] = 1
        var threshold: int = int(game.TD_NECRO_ATTACK_PROFILE.for_specialization("")["kill_streak_threshold"])
        game.necro_kill_streak = threshold - 2
        game.enemies.append({"pos": Vector2(game.slots[0]["pos"]) + Vector2(30, 0), "hp": 1, "max_hp": 1, "role": "grunt", "delay": 0.0, "lane": 0, "waypoint": 1, "speed": 0.0})
        game.attack_with_towers(0.1)
        check(game.summoned_spirits.size() == (1 if with_lantern else 0), "Soul Lantern %s an early spirit" % ("summons" if with_lantern else "is needed for"))
        drop(game)

    # Cursed Idol: morning gold, faster enemies.
    plain = day([])
    game = day(["cursed_idol"])
    check(game.coins == plain.coins + TROPHIES.IDOL_GOLD, "Cursed Idol pays its gold each morning")
    var walker := {"role": "grunt", "pos": Vector2.ZERO}
    check(is_equal_approx(game.enemy_movement_multiplier(walker), plain.enemy_movement_multiplier(walker) * TROPHIES.IDOL_SPEED), "Cursed Idol makes enemies faster")
    drop(game)
    drop(plain)

    # Blood Millstone: +1 tower damage, repair closed.
    game = day(["blood_millstone"])
    plain = day([])
    for g in [game, plain]:
        g.slots[0]["tower"] = "fire"
        g.slots[0]["level"] = 1
        g.altar_hp = 60
        g.coins = 200
    check(game.tower_synergy_damage(0, grunt) == plain.tower_synergy_damage(0, grunt) + 1, "Blood Millstone adds 1 tower damage")
    check(not game.repair_altar() and plain.repair_altar(), "Blood Millstone closes altar repair")
    drop(game)
    drop(plain)

func clear_with_last_hit(night) -> void:
    while night.enemies.size() > 1:
        night.enemies.remove_at(0)
    night.enemies[0]["hp"] = 1
    night.enemies[0]["pos"] = night.player_pos + Vector2(40, 0)
    night.attack_cooldown = 0.0
    night.attack(night.enemies[0]["pos"])

func night_pick() -> void:
    var night = NIGHT_SCENE.instantiate()
    root.add_child(night)
    night.set_process(false)
    night.enable_floor_exploration(1203)
    check(night.TROPHY_ICONS != null and night.TROPHY_ICONS.get_size() == Vector2(192, 24), "Night keeps the trophy icon texture alive (no white squares)")
    check(night.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Night draws pixel icons with nearest filtering")
    var elite := -1
    for room in night.floor_data["rooms"]:
        if str(room["kind"]) == "ЭЛИТА":
            elite = int(room["id"])
            break
    check(elite >= 0, "The floor has an elite room")
    if elite < 0:
        drop(night)
        return
    night.trophies_owned.assign(["cursed_idol"])
    night.open_room(elite)
    check(night.room_variant == 2 and night.enemies.any(func(e): return str(e.get("role", "")) == "champion"), "Elite room always fights the armored champion")
    clear_with_last_hit(night)
    check(night.reward_available and night.trophy_offers.size() == 3, "Clearing the elite room offers three trophies")
    check(not night.trophy_offers.has("cursed_idol"), "A trophy owned from earlier nights is not offered")
    check(not night.choose_relic("bone"), "The elite reward is a trophy, not a night relic")
    var pick: String = night.trophy_offers[0]
    check(night.choose_trophy(pick) and night.trophies_gained == [pick], "Choosing a trophy records it for the run")
    check(night.cleared_rooms.has(elite) and not night.reward_available and night.door_available(), "Elite room is cleared and doors open")
    check(not night.choose_trophy(pick), "A trophy cannot be taken twice")
    # An ordinary fight room still gives a night relic.
    for room in night.floor_data["rooms"]:
        if str(room["kind"]) == "БОЙ":
            night.open_room(int(room["id"]))
            break
    clear_with_last_hit(night)
    check(night.trophy_offers.is_empty() and night.choose_relic("ember"), "Ordinary fight rooms keep their relic pick")
    drop(night)

func run_loop_carry() -> void:
    var run = RUN_SCENE.instantiate()
    run.meta.save_path = "user://last_ritual_meta_trophies_smoke.json"
    root.add_child(run)
    check(run.start_run() and run.phase == "day", "Run starts on day one")
    run.active_game.altar_hp = 50
    run.finish_phase(true)
    check(run.complete_transition() and run.phase == "night", "Dusk leads into the night")
    check(run.active_game.trophies_owned.is_empty(), "No trophies before the first elite room")
    run.active_game.trophies_gained.assign(["warden_stone"])
    run.finish_phase(true)
    check(run.run_trophies == ["warden_stone"], "Night trophies are kept by the run")
    check(run.choose_run_reward("gold") and run.complete_transition() and run.phase == "day", "Dawn starts day two")
    check(run.active_game.run_trophies == ["warden_stone"], "Day two receives the run's trophies")
    check(run.active_game.altar_hp == 65, "Warden Stone heals the carried-over altar in the morning")
    run.finish_phase(true)
    check(run.complete_transition() and run.active_game.trophies_owned == ["warden_stone"], "The next night knows which trophies are owned")
    run.reset_run()
    check(run.run_trophies.is_empty(), "A new run starts without trophies")
    drop(run)
    if FileAccess.file_exists("user://last_ritual_meta_trophies_smoke.json"):
        DirAccess.remove_absolute(ProjectSettings.globalize_path("user://last_ritual_meta_trophies_smoke.json"))
