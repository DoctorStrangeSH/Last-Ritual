extends SceneTree
## Headless balance simulator for the five daily TD sieges.
##
## It drives the REAL controller (scripts/topdown_td_prototype.gd) with scripted
## build strategies, a simple hero model (--hero=0..1 is the share of time the hero is active) and no night income unless requested, and
## reports how often each strategy survives each day. It is a measuring tool:
## it never changes balance and it is not a substitute for a Windows playtest.
##
## Usage:
##   godot --headless --path . --script res://tests/td_balance_simulation.gd -- \
##       --seeds=8 --difficulties=0,1,2 --night-coins=0 --hero=1.0 --out=build/td_balance_report.md
## With no arguments it runs a small deterministic smoke configuration.

const TD_SCENE = preload("res://scenes/topdown_td_prototype.tscn")
const STEP := 0.05
const MAX_WAVE_SECONDS := 240.0
const DAYS := 5
const WAVES := 6
const MAX_EARLY_TOWERS := 4
# Each strategy: tower order for new builds and the branch bought at level 3.
const STRATEGIES := {
    "mixed": {"order": ["necro", "fire", "bone", "frost"], "spec": {"necro": "swarm", "fire": "swarm", "bone": "siege", "frost": "swarm"}},
    "necro_legion": {"order": ["necro"], "spec": {"necro": "swarm"}},
    "necro_reaper": {"order": ["necro"], "spec": {"necro": "siege"}},
    "fire_sparks": {"order": ["fire"], "spec": {"fire": "swarm"}},
    "bone_ballista": {"order": ["bone"], "spec": {"bone": "siege"}},
    "frost_blizzard": {"order": ["frost"], "spec": {"frost": "swarm"}},
}

var failures := 0
var hero_budget := 0.0
var hero_hits := 0
var omen_mode := "none"

func check(value: bool, description: String) -> void:
    if not value:
        failures += 1
        push_error("FAIL " + description)
    else:
        print("PASS " + description)

func _initialize() -> void:
    call_deferred("run")

func parse_args() -> Dictionary:
    var options := {"seeds": 2, "difficulties": [0], "night_coins": 0, "hero": 1.0, "omens": "none", "out": "", "strategies": STRATEGIES.keys()}
    for raw in OS.get_cmdline_user_args():
        var parts: PackedStringArray = str(raw).trim_prefix("--").split("=", true, 1)
        if parts.size() != 2:
            continue
        match parts[0]:
            "seeds": options["seeds"] = clampi(int(parts[1]), 1, 8)
            "night-coins": options["night_coins"] = maxi(0, int(parts[1]))
            "hero": options["hero"] = clampf(float(parts[1]), 0.0, 1.0)
            "omens": options["omens"] = "greedy" if parts[1] == "greedy" else "none"
            "out": options["out"] = parts[1]
            "difficulties":
                var list: Array = []
                for item in parts[1].split(","):
                    list.append(clampi(int(item), 0, 2))
                options["difficulties"] = list
            "strategies":
                var names: Array = []
                for item in parts[1].split(","):
                    if STRATEGIES.has(item):
                        names.append(item)
                if not names.is_empty():
                    options["strategies"] = names
    return options

## Slots closest to the roads first, like a sensible player would use them.
func slot_priority(game) -> Array[int]:
    var scored: Array = []
    for slot_id in range(game.slots.size()):
        var best := INF
        for path in game.paths:
            for point in path:
                best = minf(best, (game.slots[slot_id]["pos"] as Vector2).distance_to(point))
        scored.append({"id": slot_id, "score": best})
    scored.sort_custom(func(a, b): return a["score"] < b["score"] or (a["score"] == b["score"] and a["id"] < b["id"]))
    var ids: Array[int] = []
    for entry in scored:
        ids.append(int(entry["id"]))
    return ids

func tower_count(game) -> int:
    var count := 0
    for slot in game.slots:
        if str(slot["tower"]) != "":
            count += 1
    return count

## Spend coins greedily: first a small core, then upgrades, then extra towers.
func prepare(game, strategy: Dictionary) -> void:
    var order: Array = strategy["order"]
    var spec: Dictionary = strategy["spec"]
    var priority: Array[int] = slot_priority(game)
    if game.altar_hp <= 60 and game.coins >= game.REPAIR_COST:
        game.repair_altar()
    if game.can_choose_interwave_event():
        var offers: Array[String] = game.council_offers()
        var pick: String = offers[0]
        for preferred in (["repair", "raid", "safe"] if game.altar_hp < 85 else ["raid", "safe", "repair"]):
            if offers.has(preferred):
                pick = preferred
                break
        game.choose_interwave_event(pick)
    var guard := 0
    while guard < 64:
        guard += 1
        if not try_spend(game, order, spec, priority):
            break

func try_spend(game, order: Array, spec: Dictionary, priority: Array[int]) -> bool:
    var built := tower_count(game)
    if built < MAX_EARLY_TOWERS and build_next(game, order, priority, built):
        return true
    # Finish specialisation first (it is the strongest single purchase), then upgrade the weakest tower.
    for slot_id in priority:
        var slot: Dictionary = game.slots[slot_id]
        if str(slot["tower"]) != "" and int(slot["level"]) == 3 and str(slot.get("specialization", "")) == "":
            game.select_slot(slot_id)
            if game.upgrade_selected():
                game.choose_specialization(str(spec.get(str(slot["tower"]), "siege")))
                return true
    var best_slot := -1
    for slot_id in priority:
        var slot: Dictionary = game.slots[slot_id]
        if str(slot["tower"]) == "" or int(slot["level"]) >= 3:
            continue
        if best_slot < 0 or int(slot["level"]) < int(game.slots[best_slot]["level"]):
            best_slot = slot_id
    if best_slot >= 0:
        game.select_slot(best_slot)
        if game.upgrade_selected():
            return true
    return build_next(game, order, priority, built)

func build_next(game, order: Array, priority: Array[int], built: int) -> bool:
    for slot_id in priority:
        if str(game.slots[slot_id]["tower"]) != "":
            continue
        var kind: String = str(order[built % order.size()])
        if not game.choose_tower(kind):
            return false
        return game.build_tower(slot_id)
    return false

## A simple but competent hero: chase the enemy closest to the altar (boss first
## while it is charging) and keep attacking it. Uses the real hero_attack().
func hero_step(game, presence: float) -> void:
    game.hero_attack_cooldown = maxf(0.0, game.hero_attack_cooldown - STEP)
    hero_budget += presence
    if hero_budget < 1.0:
        return
    hero_budget -= 1.0
    var target: Dictionary = {}
    var best_progress := -1.0
    for enemy in game.enemies:
        if float(enemy["delay"]) > 0.0:
            continue
        var progress := float(enemy["waypoint"]) * 1000.0 - (enemy["pos"] as Vector2).distance_to(game.paths[int(enemy["lane"])][mini(int(enemy["waypoint"]), game.paths[int(enemy["lane"])].size() - 1)])
        if str(enemy.get("role", "")) == "boss" and bool(enemy.get("boss_warning", false)):
            progress += 100000.0
        if progress > best_progress:
            best_progress = progress
            target = enemy
    if target.is_empty():
        return
    var to_target: Vector2 = (target["pos"] as Vector2) - game.hero_pos
    if to_target.length() > game.HERO_ATTACK_RANGE * 0.8:
        game.move_hero(to_target.normalized(), STEP)
    if game.hero_attack(target["pos"]):
        hero_hits += 1

## "greedy" accepts the highest-bounty omen whenever one is offered.
func start_next_wave(game) -> bool:
    if omen_mode == "greedy":
        var offers: Array[Dictionary] = game.wave_omen_offers()
        if not offers.is_empty() and not game.can_choose_interwave_event():
            var best: Dictionary = offers[0]
            for offer in offers:
                if int(offer["reward"]) > int(best["reward"]):
                    best = offer
            return game.choose_wave_omen(str(best["id"]))
    return game.start_wave()

func fight_wave(game, hero: float) -> float:
    var elapsed := 0.0
    while not game.enemies.is_empty() and game.defense_state == "playing" and elapsed < MAX_WAVE_SECONDS:
        game.advance_enemies(STEP)
        game.tick_support_enemies(STEP)
        game.tick_boss(STEP)
        game.tick_burning(STEP)
        game.attack_with_towers(STEP)
        game.tick_necro_spirits(STEP)
        if hero > 0.0:
            hero_step(game, hero)
        game.settle_wave_omen()
        game.shot_trails.clear()
        elapsed += STEP
    return elapsed

func new_game(difficulty: int, day: int, map_seed: int, carried: Dictionary):
    var game = TD_SCENE.instantiate()
    root.add_child(game)
    game.set_process(false)
    game.set_process_unhandled_input(false)
    game.difficulty = difficulty
    game.siege_day = day
    game.set_fortress_map_seed(map_seed)
    if not carried.is_empty():
        game.import_fortress_state(carried)
    return game

## Returns {days: [per-day result], survived_days: int}.
func simulate_run(strategy: Dictionary, difficulty: int, map_seed: int, night_coins: int, hero: float) -> Dictionary:
    var carried := {}
    var days: Array = []
    for day in range(1, DAYS + 1):
        var game = new_game(difficulty, day, map_seed, carried)
        game.coins += night_coins if day > 1 else 0
        var leaks_per_wave: Array = []
        var seconds := 0.0
        var start_hp: int = game.altar_hp
        var total_hp := 0
        hero_hits = 0
        hero_budget = 0.0
        while game.defense_state == "playing" and game.wave_number < WAVES:
            prepare(game, strategy)
            var escaped_before: int = game.enemies_escaped
            if not start_next_wave(game):
                break
            for spawned in game.enemies:
                total_hp += int(spawned["max_hp"])
            seconds += fight_wave(game, hero)
            leaks_per_wave.append(game.enemies_escaped - escaped_before)
        var cleared: bool = game.defense_state == "playing" and game.wave_number >= WAVES and game.enemies.is_empty()
        days.append({"day": day, "cleared": cleared, "altar_hp": game.altar_hp, "start_hp": start_hp, "escaped": game.enemies_escaped, "defeated": game.enemies_defeated, "coins": game.coins, "towers": tower_count(game), "leaks": leaks_per_wave, "seconds": seconds, "total_hp": total_hp, "hero_hits": hero_hits, "lost_wave": game.wave_number if not cleared else 0})
        carried = game.export_fortress_state() if cleared else {}
        game.get_parent().remove_child(game)
        game.free()
        if not cleared:
            break
    var survived := 0
    for entry in days:
        if entry["cleared"]:
            survived += 1
    return {"days": days, "survived": survived}

func run() -> void:
    var options := parse_args()
    omen_mode = str(options["omens"])
    var rows: Array = []
    var signature := ""
    for difficulty in options["difficulties"]:
        for strategy_name in options["strategies"]:
            var survive_counts := [0, 0, 0, 0, 0]
            var hp_sums := [0.0, 0.0, 0.0, 0.0, 0.0]
            var hp_counts := [0, 0, 0, 0, 0]
            var escaped_sums := [0.0, 0.0, 0.0, 0.0, 0.0]
            var lost_waves := {}
            var hero_damage := 0.0
            var enemy_hp := 0.0
            for map_seed in range(int(options["seeds"])):
                var result := simulate_run(STRATEGIES[strategy_name], int(difficulty), map_seed, int(options["night_coins"]), float(options["hero"]))
                for entry in result["days"]:
                    var index: int = int(entry["day"]) - 1
                    hp_sums[index] += float(entry["altar_hp"])
                    hp_counts[index] += 1
                    escaped_sums[index] += float(entry["escaped"])
                    hero_damage += 2.0 * float(entry["hero_hits"])
                    enemy_hp += float(entry["total_hp"])
                    if entry["cleared"]:
                        survive_counts[index] += 1
                    else:
                        var key := "d%dw%d" % [entry["day"], entry["lost_wave"]]
                        lost_waves[key] = int(lost_waves.get(key, 0)) + 1
                signature += "%d|%s|%d|%d;" % [difficulty, strategy_name, map_seed, result["survived"]]
            rows.append({"difficulty": difficulty, "strategy": strategy_name, "seeds": options["seeds"], "survive": survive_counts, "hp_sums": hp_sums, "hp_counts": hp_counts, "escaped": escaped_sums, "lost": lost_waves, "hero_share": (hero_damage / enemy_hp * 100.0) if enemy_hp > 0.0 else 0.0})
    var report := build_report(rows, options)
    print(report)
    if str(options["out"]) != "":
        var directory := str(options["out"]).get_base_dir()
        if directory != "":
            DirAccess.make_dir_recursive_absolute(directory)
        var file := FileAccess.open(str(options["out"]), FileAccess.WRITE)
        if file != null:
            file.store_string(report)
            file.close()
    check(rows.size() == options["difficulties"].size() * options["strategies"].size(), "Simulation produced one row per difficulty and strategy")
    check(signature.length() > 0, "Simulation recorded results")
    # Determinism: the same configuration must reproduce the same outcome.
    var repeat := simulate_run(STRATEGIES["mixed"], 0, 0, int(options["night_coins"]), float(options["hero"]))
    var again := simulate_run(STRATEGIES["mixed"], 0, 0, int(options["night_coins"]), float(options["hero"]))
    check(repeat["survived"] == again["survived"] and repeat["days"][0]["altar_hp"] == again["days"][0]["altar_hp"], "Simulation is deterministic for a fixed seed")
    print("TD BALANCE SIMULATION RESULT: ", "PASS" if failures == 0 else "FAIL")
    quit(1 if failures > 0 else 0)

func build_report(rows: Array, options: Dictionary) -> String:
    var lines: PackedStringArray = []
    lines.append("# TD balance simulation")
    lines.append("")
    lines.append("Seeds (road layouts) per row: %d. Night income per day: %d coins. Omens: %s. Hero model: %s. Scripted greedy builds." % [options["seeds"], options["night_coins"], options["omens"], "present %d%% of the time (chases the front enemy, interrupts the boss)" % roundi(float(options["hero"]) * 100.0) if float(options["hero"]) > 0.0 else "off"])
    lines.append("")
    lines.append("Cells show: share of runs that cleared the day / mean altar HP after the day (of runs that reached it).")
    lines.append("")
    lines.append("| Difficulty | Strategy | Day 1 | Day 2 | Day 3 | Day 4 | Day 5 | Hero dmg share | Most common loss |")
    lines.append("|---|---|---|---|---|---|---|---|---|")
    for row in rows:
        var cells: PackedStringArray = []
        for index in range(DAYS):
            var reached: int = int(row["hp_counts"][index])
            if reached == 0:
                cells.append("—")
                continue
            cells.append("%d%% / %d" % [roundi(100.0 * float(row["survive"][index]) / float(row["seeds"])), roundi(float(row["hp_sums"][index]) / float(reached))])
        var worst := "—"
        var worst_count := 0
        for key in row["lost"].keys():
            if int(row["lost"][key]) > worst_count:
                worst_count = int(row["lost"][key])
                worst = "%s (x%d)" % [key, worst_count]
        lines.append("| %s | %s | %s | %d%% | %s |" % [["normal", "hard", "nightmare"][int(row["difficulty"])], row["strategy"], " | ".join(cells), roundi(float(row["hero_share"])), worst])
    lines.append("")
    return "\n".join(lines)
