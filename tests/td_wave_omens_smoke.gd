extends SceneTree
## «Знамения угрозы»: pre-wave risk/reward choice in the day siege.

const OMENS = preload("res://scripts/td/td_wave_omens.gd")
var failures := 0

func check(value: bool, description: String) -> void:
    if not value:
        failures += 1
        push_error("FAIL " + description)
    else:
        print("PASS " + description)

func left_click(point: Vector2) -> InputEventMouseButton:
    var event := InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_LEFT
    event.position = point
    event.pressed = true
    return event

func new_day(scene: PackedScene, seed_value: int, day: int):
    var game = scene.instantiate()
    root.add_child(game)
    game.set_process(false)
    game.set_fortress_map_seed(seed_value)
    game.siege_day = day
    return game

func clear_wave(game) -> void:
    for enemy in game.enemies.duplicate():
        game.enemies.erase(enemy)

func _initialize() -> void:
    call_deferred("run_tests")

func run_tests() -> void:
    # Pure module: deterministic, two distinct offers, only waves 2–5.
    check(OMENS.offers(7, 1, 1).is_empty() and OMENS.offers(7, 1, 6).is_empty(), "No omens on the opening wave or the boss wave")
    var all_distinct := true
    var all_known := true
    var seen := {}
    for seed_value in range(64):
        for day in range(1, 6):
            for wave in range(2, 6):
                var offers: Array[String] = OMENS.offers(seed_value, day, wave)
                all_distinct = all_distinct and offers.size() == 2 and offers[0] != offers[1]
                for omen_id in offers:
                    all_known = all_known and OMENS.CATALOG.has(omen_id)
                    seen[omen_id] = true
    check(all_distinct, "Every omen wave offers two different threats")
    check(all_known and seen.size() == OMENS.ORDER.size(), "Offers use every catalogued threat and nothing else")
    check(OMENS.offers(99, 3, 4) == OMENS.offers(99, 3, 4), "Offers are reproducible for the same seed, day and wave")
    var early: Dictionary = OMENS.resolve("raiders", 5, 1, 2, 3)
    var late: Dictionary = OMENS.resolve("raiders", 5, 5, 5, 3)
    check(int(late["reward"]) > int(early["reward"]) and OMENS.extra_count(late) > OMENS.extra_count(early), "Later days raise both the threat and the bounty")
    check(int(early["lane"]) >= 0 and int(early["lane"]) < 3, "Focused route is a valid lane index")
    check(OMENS.resolve("unknown", 5, 1, 2, 3).is_empty() and OMENS.resolve("raiders", 5, 1, 6, 3).is_empty(), "Unknown omen and boss wave resolve to nothing")
    check(OMENS.describe(early).contains("бегун"), "Russian description names the added enemies")

    var scene: PackedScene = load("res://scenes/topdown_td_prototype.tscn")
    check(scene != null, "TD scene loads")
    if scene == null:
        quit(1)
        return

    # Programmatic start_wave() is unchanged: no omen, no modal.
    var plain = new_day(scene, 4242, 2)
    plain.start_wave()
    clear_wave(plain)
    var plain_budget: int = int(plain.wave_enemy_budget(2)["total"])
    plain.start_wave()
    check(plain.enemies.size() == plain_budget and plain.active_omen.is_empty(), "Wave without a chosen omen keeps the original composition")
    check(not plain.omen_choice_open, "start_wave() never opens the omen modal")

    # Wave 1: the button starts the wave directly.
    var game = new_day(scene, 4242, 2)
    check(game.wave_omen_offers().is_empty(), "No omen choice before the opening wave")
    game.request_wave_start()  # what the wave button calls
    check(game.wave_number == 1 and not game.omen_choice_open, "Opening wave starts directly from the wave button")
    clear_wave(game)

    # Wave 2: the button opens the modal instead of starting.
    var offers: Array[Dictionary] = game.wave_omen_offers()
    check(offers.size() == 2, "Two resolved threats are offered before wave 2")
    game.request_wave_start()
    check(game.omen_choice_open and game.wave_number == 1, "Wave button opens the omen choice before wave 2")
    var cancel := InputEventKey.new()
    cancel.keycode = KEY_ESCAPE
    cancel.pressed = true
    game._unhandled_input(cancel)
    check(not game.omen_choice_open and game.wave_number == 1, "Esc closes the choice without starting the wave")
    check(not game.choose_wave_omen("not-offered"), "A threat that was not offered is rejected")

    # Accept the second card by clicking it.
    var chosen: Dictionary = offers[1]
    game.request_wave_start()
    var coins_before: int = game.coins
    game._unhandled_input(left_click(game.OMEN_BUTTONS[2].get_center()))
    check(game.wave_number == 2 and game.active_omen.get("id", "") == chosen["id"], "Clicking a threat card accepts it and starts the wave")
    var expected: int = int(game.wave_enemy_budget(2)["total"]) + OMENS.extra_count(chosen)
    check(game.enemies.size() == expected, "Accepted threat adds exactly its extra enemies")
    var omen_units: Array = game.enemies.filter(func(e): return e.get("omen", false))
    var on_lane := true
    for unit in omen_units:
        on_lane = on_lane and int(unit["lane"]) == int(chosen["lane"])
    check(omen_units.size() == OMENS.extra_count(chosen) and on_lane, "Extra enemies march on the announced route")
    check(game.settle_wave_omen() == 0, "No bounty while the threat is still alive")
    clear_wave(game)
    var paid: int = game.settle_wave_omen()
    check(paid == int(chosen["reward"]) and game.coins == coins_before + paid, "Bounty is paid once the wave is cleared")
    check(game.settle_wave_omen() == 0 and game.active_omen.is_empty(), "Bounty is never paid twice")
    check(game.omens_accepted == 1 and game.omen_bounty_total == paid, "Run statistics count the accepted threat")

    # Declining with key 1 starts a normal wave.
    game.request_wave_start()
    var one := InputEventKey.new()
    one.keycode = KEY_1
    one.pressed = true
    game._unhandled_input(one)
    check(game.wave_number == 3 and game.active_omen.is_empty() and game.enemies.size() == int(game.wave_enemy_budget(3)["total"]), "Key 1 declines and starts the ordinary wave")

    # A lost wave forfeits the bounty; restart clears all omen state.
    clear_wave(game)
    if game.can_choose_interwave_event():
        game.choose_interwave_event(game.council_offers()[0])
    check(game.choose_wave_omen(str(game.wave_omen_offers()[0]["id"])), "Threat can be accepted after the war council")
    game.altar_hp = 0
    clear_wave(game)
    check(game.settle_wave_omen() == 0, "A fallen altar earns no bounty")
    game.restart_defense()
    check(game.active_omen.is_empty() and not game.omen_choice_open and game.omen_bounty_total == 0, "Restart clears omen state")

    # Modifiers: ironclad adds brute HP, raiders speed up runners.
    var ironclad_game = new_day(scene, 4242, 3)
    ironclad_game.wave_number = 2
    ironclad_game.pending_omen = "ironclad"
    ironclad_game.start_wave()
    var ironclad_brute: Dictionary = ironclad_game.enemies.filter(func(e): return e["role"] == "brute")[0]
    var reference = new_day(scene, 4242, 3)
    reference.wave_number = 2
    reference.start_wave()
    var reference_brute: Dictionary = reference.enemies.filter(func(e): return e["role"] == "brute")[0]
    check(int(ironclad_brute["max_hp"]) == int(reference_brute["max_hp"]) + int(OMENS.CATALOG["ironclad"]["brute_hp"]), "Iron Fist brutes gain exactly the catalogued bonus HP")

    # Omen units carry no kill gold: the bounty is their whole reward.
    var omen_unit: Dictionary = ironclad_game.enemies.filter(func(e): return e.get("omen", false))[0]
    check(ironclad_game.kill_gold(omen_unit) == 0 and ironclad_game.kill_gold(reference_brute) == 5, "Omen enemies give no kill gold; ordinary ones still give 5")

    for node in [plain, game, ironclad_game, reference]:
        node.queue_free()
    print("TD WAVE OMENS RESULT: ", "PASS" if failures == 0 else str(failures) + " FAILURES")
    quit(0 if failures == 0 else 1)
