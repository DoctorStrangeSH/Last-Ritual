extends Node2D
## V2 independent top-down TD construction slice. No paths or wave spawning yet.
const SFX_SCRIPT = preload("res://scripts/procedural_sfx.gd")
var sfx: Node
const SLOT_POSITIONS := [Vector2(280, 190), Vector2(430, 190), Vector2(590, 190), Vector2(750, 190), Vector2(280, 440), Vector2(430, 440), Vector2(590, 440), Vector2(750, 440)]
const COSTS := {"bone": 30, "fire": 45, "necro": 60}
const WAVE_BUTTON := Rect2(65, 545, 170, 60)
const REPAIR_BUTTON := Rect2(485, 474, 225, 54)
const REPAIR_COST := 25
const REPAIR_HP := 20
const HELP_BUTTON := Rect2(987.0, 10.0, 150.0, 46.0)
const HELP_CLOSE_BUTTON := Rect2(720.0, 471.0, 130.0, 43.0)
const TARGET_BUTTON := Rect2(716, 76, 299, 46)
const TARGET_PRIORITIES := ["nearest", "support", "front"]
const TARGET_LABELS := {"nearest": "БЛИЖАЙШИЙ", "support": "ПОДДЕРЖКА", "front": "У ВОРОТ"}
var slots: Array[Dictionary] = []
var specialization_open := false
const SPECIALIZATION_BUTTONS := [Rect2(315, 325, 220, 70), Rect2(555, 325, 220, 70)]
const SPECIALIZATION_LABELS := {"bone": ["БАЛЛИСТА: +2 УРОН", "РОЙ: СКОРОСТЬ"], "fire": ["ИНФЕРНО: ПЛАМЯ", "ИСКРЫ: ЧАСТЫЕ УДАРЫ"], "necro": ["ЖНЕЦ: СИЛА ДУХОВ", "ЛЕГИОН: БОЛЬШЕ ДУХОВ"]}
var selected_type := ""
var selected_slot := -1
var coins := 150
var difficulty := 0 # 0 normal, 1 hard, 2 nightmare
var siege_day := 1 # 1 scouting, 2 swift assault, 3 armored siege
var fire_synergy_bonus := 0
var bone_synergy_bonus := 0
var necro_kill_bonus := 0
var necro_kill_streak := 0
var summoned_spirits: Array[Dictionary] = []
const PATHS := [
    [Vector2(65, 285), Vector2(205, 285), Vector2(300, 260), Vector2(375, 302), Vector2(490, 263), Vector2(625, 292), Vector2(780, 260), Vector2(900, 295), Vector2(1070, 285)],
    [Vector2(65, 345), Vector2(200, 355), Vector2(325, 382), Vector2(425, 344), Vector2(550, 384), Vector2(705, 340), Vector2(845, 380), Vector2(950, 347), Vector2(1070, 345)]
]
var enemies: Array[Dictionary] = []
var wave_number := 0
var altar_hp := 100
var defense_state := "playing" # playing, won, lost
var help_visible := false
const RESTART_BUTTON := Rect2(455, 350, 242, 58)
var enemies_spawned := 0
var enemies_escaped := 0
var enemies_defeated := 0
var tower_cooldowns: Dictionary = {}
var shot_trails: Array[Dictionary] = []
const TOWER_RANGE := {"bone": 135.0, "fire": 160.0, "necro": 125.0}
const TOWER_DAMAGE := {"bone": 2, "fire": 1, "necro": 3}
const HERO_SPEED := 215.0
const HERO_ATTACK_RANGE := 150.0
var hero_pos := Vector2(560.0, 420.0)
var hero_attack_cooldown := 0.0
var boss_feedback_time := 0.0
var boss_feedback_text := ""

func move_hero(direction: Vector2, delta: float) -> void:
    hero_pos += direction.limit_length(1.0) * HERO_SPEED * delta
    hero_pos = hero_pos.clamp(Vector2(42, 75), Vector2(1110, 520))
    queue_redraw()

func hero_attack(target: Vector2) -> bool:
    if hero_attack_cooldown > 0.0 or altar_hp <= 0:
        return false
    var best: Dictionary = {}
    var best_distance := INF
    for enemy in enemies:
        if enemy["delay"] > 0.0:
            continue
        var enemy_pos: Vector2 = enemy["pos"]
        var distance := hero_pos.distance_to(enemy_pos)
        if distance <= HERO_ATTACK_RANGE and enemy_pos.distance_to(target) <= 42.0 and distance < best_distance:
            best = enemy
            best_distance = distance
    if best.is_empty():
        return false
    shot_trails.append({"from": hero_pos, "to": best["pos"], "time": 0.18})
    best["hp"] -= 2
    sfx.play_effect("hit")
    if best.get("role", "") == "boss" and best.get("boss_warning", false) and best["hp"] > 0:
        best["interrupt_hits"] = int(best.get("interrupt_hits", 0)) + 1
        if int(best["interrupt_hits"]) >= 2:
            best["boss_charge"] = 0.0
            best["boss_warning"] = false
            best["interrupt_hits"] = 0
            boss_feedback_text = "АТАКА ПРЕРВАНА!"
            sfx.play_effect("interrupt")
            boss_feedback_time = 1.4
    hero_attack_cooldown = 0.28
    if best["hp"] <= 0:
        enemies.erase(best)
        enemies_defeated += 1
        coins += 5
        sfx.play_effect("kill")
    queue_redraw()
    return true

func upcoming_wave_summary() -> String:
    if wave_number >= 3:
        return "ВСЕ ВОЛНЫ ОТБИТЫ"
    if siege_day == 2:
        return "ДЕНЬ 2: НАЛЁТ БЕГУНОВ / ВОЛНА %d" % (wave_number + 1)
    if siege_day >= 3:
        return "ДЕНЬ 3: ТЯЖЁЛАЯ ОСАДА / ВОЛНА %d" % (wave_number + 1)
    match wave_number + 1:
        1:
            return "РАЗВЕДКА: МЕДЛЕННАЯ ПЕХОТА"
        2:
            return "УГРОЗА: БЕГУНЫ + БРОНЯ + ЛЕКАРЬ"
        3:
            return "ОСАДА: БОСС + ПОЛЕВОЙ ЛЕКАРЬ"
    return ""

func repair_altar() -> bool:
    # Repair is a preparation action; never allow mid-wave or after victory/defeat.
    if defense_state != "playing" or not enemies.is_empty() or wave_number >= 3:
        return false
    if altar_hp <= 0 or altar_hp >= 100 or coins < REPAIR_COST:
        return false
    coins -= REPAIR_COST
    altar_hp = mini(100, altar_hp + REPAIR_HP)
    queue_redraw()
    return true

func start_wave() -> bool:
    if defense_state != "playing" or not enemies.is_empty() or wave_number >= 3 or altar_hp <= 0:
        return false
    wave_number += 1
    enemies_spawned = 0
    var count := wave_number + 2 + (1 if siege_day == 2 else 0) + (1 if siege_day >= 3 else 0)
    for i in range(count):
        var role := "runner" if siege_day == 2 and i % 2 == 0 else "brute" if siege_day >= 3 and i % 2 == 0 else "runner" if wave_number >= 2 and i % 3 == 0 else "brute" if wave_number >= 2 and i % 3 == 1 else "grunt"
        var hp := ((7 + wave_number) if role == "brute" else (2 + wave_number if role == "runner" else 3 + wave_number)) + difficulty * 2 + (3 if siege_day >= 3 else 0)
        var speed := (135.0 if role == "runner" else (55.0 if role == "brute" else 85.0)) * (1.0 + 0.15 * difficulty)
        enemies.append({"lane": i % PATHS.size(), "pos": PATHS[i % PATHS.size()][0], "waypoint": 1, "hp": hp, "max_hp": hp, "speed": speed, "role": role, "delay": float(i) * 0.7})
        enemies_spawned += 1
    if wave_number >= 2:
        var support_hp: int = 8 + wave_number * 2 + difficulty * 2
        enemies.append({"lane": 1, "pos": PATHS[1][0], "waypoint": 1, "hp": support_hp, "max_hp": support_hp, "speed": 62.0, "role": "healer", "delay": 1.5, "heal_timer": 1.0})
        enemies_spawned += 1
    if wave_number == 3:
        enemies.append({"lane": 0, "pos": PATHS[0][0], "waypoint": 1, "hp": 55 + difficulty * 15 + (20 if siege_day >= 3 else 0), "speed": 28.0 * (1.0 + 0.15 * difficulty), "role": "boss", "delay": 3.0, "boss_charge": 0.0, "boss_warning": false, "interrupt_hits": 0})
        enemies_spawned += 1
    queue_redraw()
    return true

func tick_support_enemies(delta: float) -> void:
    for support in enemies:
        if str(support.get("role", "")) != "healer" or float(support.get("delay", 0.0)) > 0.0:
            continue
        support["heal_timer"] = float(support.get("heal_timer", 1.0)) - delta
        if float(support["heal_timer"]) > 0.0:
            continue
        support["heal_timer"] = 1.0
        var healed := 0
        for ally in enemies:
            if ally == support or float(ally.get("delay", 0.0)) > 0.0:
                continue
            if support["pos"].distance_to(ally["pos"]) <= 135.0 and int(ally["hp"]) < int(ally.get("max_hp", ally["hp"])):
                ally["hp"] = mini(int(ally["hp"]) + 2, int(ally["max_hp"]))
                healed += 1
                if healed >= 2:
                    break
    queue_redraw()

func advance_enemies(delta: float) -> void:
    for enemy in enemies.duplicate():
        if enemy["delay"] > 0.0:
            enemy["delay"] = maxf(0.0, float(enemy["delay"]) - delta)
            continue
        var path: Array = PATHS[int(enemy["lane"])]
        var waypoint: int = int(enemy["waypoint"])
        var position: Vector2 = enemy["pos"]
        # Полный остаток движения за кадр проходит все достигнутые повороты.
        # Без этого враг задерживается на каждой точке и зависит от FPS.
        var remaining := float(enemy.get("speed", 85.0)) * delta
        while remaining > 0.0 and waypoint < path.size():
            var target: Vector2 = path[waypoint]
            var distance := position.distance_to(target)
            if distance > remaining:
                position = position.move_toward(target, remaining)
                remaining = 0.0
            else:
                position = target
                remaining -= distance
                waypoint += 1
        enemy["pos"] = position
        enemy["waypoint"] = waypoint
        if waypoint >= path.size():
            enemies.erase(enemy)
            enemies_escaped += 1
            altar_hp = maxi(0, altar_hp - 10)
            if altar_hp == 0:
                defense_state = "lost"
    queue_redraw()

func tick_boss(delta: float) -> void:
    for enemy in enemies:
        if enemy.get("role", "") != "boss" or float(enemy.get("delay", 0.0)) > 0.0:
            continue
        enemy["boss_charge"] = float(enemy.get("boss_charge", 0.0)) + delta
        enemy["boss_warning"] = float(enemy["boss_charge"]) >= 3.0
        if float(enemy["boss_charge"]) >= 4.0:
            enemy["boss_charge"] = 0.0
            enemy["boss_warning"] = false
            enemy["interrupt_hits"] = 0
            altar_hp = maxi(0, altar_hp - (8 + difficulty * 4))
            boss_feedback_text = "АЛТАРЬ ПОВРЕЖДЁН! -%d ОЗ" % (8 + difficulty * 4)
            sfx.play_effect("blast")
            boss_feedback_time = 1.2
            if altar_hp == 0:
                defense_state = "lost"
    queue_redraw()

const SYNERGY_DISTANCE := 190.0

func has_adjacent_tower(slot_id: int, tower_kind: String) -> bool:
    if slot_id < 0 or slot_id >= slots.size():
        return false
    var origin: Vector2 = slots[slot_id]["pos"]
    for other_id in range(slots.size()):
        if other_id != slot_id and str(slots[other_id]["tower"]) == tower_kind:
            if origin.distance_to(slots[other_id]["pos"]) <= SYNERGY_DISTANCE:
                return true
    return false

func tower_synergy_links(slot_id: int) -> Array[int]:
    var links: Array[int] = []
    if slot_id < 0 or slot_id >= slots.size():
        return links
    var kind: String = str(slots[slot_id]["tower"])
    for other_id in range(slots.size()):
        if other_id == slot_id:
            continue
        var other_kind: String = str(slots[other_id]["tower"])
        var active_pair: bool = (kind == "bone" and other_kind == "fire") or (kind == "fire" and other_kind == "bone") or (kind == "necro" and other_kind == "bone") or (kind == "bone" and other_kind == "necro")
        if active_pair and slots[slot_id]["pos"].distance_to(slots[other_id]["pos"]) <= SYNERGY_DISTANCE:
            links.append(other_id)
    return links

func tower_synergy_damage(slot_id: int, enemy: Dictionary) -> int:
    if slot_id < 0 or slot_id >= slots.size():
        return 0
    var kind: String = str(slots[slot_id]["tower"])
    if kind == "bone" and float(enemy.get("burn_time", 0.0)) > 0.0 and has_adjacent_tower(slot_id, "fire"):
        return 2
    if kind == "necro" and has_adjacent_tower(slot_id, "bone"):
        return 1
    return 0

func choose_tower_target(slot_id: int) -> Dictionary:
    if slot_id < 0 or slot_id >= slots.size():
        return {}
    var tower: Dictionary = slots[slot_id]
    var kind: String = str(tower["tower"])
    if kind == "" or not TOWER_RANGE.has(kind):
        return {}
    var priority: String = str(tower.get("target_priority", "nearest"))
    var best: Dictionary = {}
    var best_score := -INF
    for enemy in enemies:
        if float(enemy.get("delay", 0.0)) > 0.0:
            continue
        var distance: float = tower["pos"].distance_to(enemy["pos"])
        if distance > float(TOWER_RANGE[kind]):
            continue
        var score: float = -distance
        if priority == "support":
            score += 10000.0 if str(enemy.get("role", "")) == "healer" else 0.0
        elif priority == "front":
            score = float(enemy["pos"].x)
        if score > best_score:
            best_score = score
            best = enemy
    return best

func cycle_target_priority() -> bool:
    if selected_slot < 0 or selected_slot >= slots.size() or slots[selected_slot]["tower"] == "":
        return false
    var current: String = str(slots[selected_slot].get("target_priority", "nearest"))
    var index: int = TARGET_PRIORITIES.find(current)
    slots[selected_slot]["target_priority"] = TARGET_PRIORITIES[(index + 1) % TARGET_PRIORITIES.size()]
    queue_redraw()
    return true

func attack_with_towers(delta: float) -> void:
    for slot_id in range(slots.size()):
        var tower: Dictionary = slots[slot_id]
        var kind: String = tower["tower"]
        if kind == "":
            continue
        var cooldown: float = maxf(0.0, float(tower_cooldowns.get(slot_id, 0.0)) - delta)
        tower_cooldowns[slot_id] = cooldown
        if cooldown > 0.0:
            continue
        var target: Dictionary = choose_tower_target(slot_id)
        if target.is_empty():
            continue
        var nearest: float = tower["pos"].distance_to(target["pos"])
        var hit_targets: Array = [target]
        if kind == "bone":
            var direction: Vector2 = (target["pos"] - tower["pos"]).normalized()
            for candidate in enemies:
                if candidate == target or candidate["delay"] > 0.0 or hit_targets.size() >= 3:
                    continue
                var relative: Vector2 = candidate["pos"] - tower["pos"]
                var along: float = relative.dot(direction)
                var across: float = absf(direction.cross(relative))
                if along > nearest and along <= TOWER_RANGE[kind] and across <= 24.0:
                    hit_targets.append(candidate)
        var damage: int = int(TOWER_DAMAGE[kind]) * int(tower["level"])
        if tower.get("specialization", "") == "siege":
            damage += 2
        elif tower.get("specialization", "") == "swarm":
            damage = maxi(1, damage - 1)
        if kind == "fire":
            damage += fire_synergy_bonus
        elif kind == "bone":
            damage += bone_synergy_bonus
        for hit_target in hit_targets:
            shot_trails.append({"from": tower["pos"], "to": hit_target["pos"], "time": 0.18})
            hit_target["hp"] -= damage + tower_synergy_damage(slot_id, hit_target)
            if kind == "fire" and hit_target["hp"] > 0:
                apply_burn(hit_target)
                if tower.get("specialization", "") == "siege":
                    hit_target["burn_damage"] = int(hit_target["burn_damage"]) + 2
                    hit_target["burn_time"] = 4.0
            if hit_target["hp"] <= 0:
                enemies.erase(hit_target)
                enemies_defeated += 1
                coins += 5
                if kind == "necro":
                    coins += necro_kill_bonus
                    necro_kill_streak += 1
                    var spirit_threshold: int = 2 if tower.get("specialization", "") == "swarm" else 3
                    if necro_kill_streak >= spirit_threshold:
                        necro_kill_streak = 0
                        spawn_necro_spirit(tower["pos"], tower.get("specialization", "") == "siege")
        tower_cooldowns[slot_id] = 0.45 if tower.get("specialization", "") == "swarm" else 0.8
    queue_redraw()

func spawn_necro_spirit(origin: Vector2, empowered: bool = false) -> void:
    if summoned_spirits.size() >= 2:
        return
    summoned_spirits.append({"pos": origin, "life": 5.0 if empowered else 4.0, "cooldown": 0.0, "damage": 4 if empowered else 2})

func tick_necro_spirits(delta: float) -> void:
    for spirit in summoned_spirits.duplicate():
        spirit["life"] = float(spirit["life"]) - delta
        spirit["cooldown"] = maxf(0.0, float(spirit["cooldown"]) - delta)
        if float(spirit["life"]) <= 0.0:
            summoned_spirits.erase(spirit)
            continue
        if float(spirit["cooldown"]) > 0.0:
            continue
        var target: Dictionary = {}
        var nearest := 170.0
        for enemy in enemies:
            if float(enemy.get("delay", 0.0)) > 0.0:
                continue
            var distance: float = spirit["pos"].distance_to(enemy["pos"])
            if distance < nearest:
                nearest = distance
                target = enemy
        if not target.is_empty():
            target["hp"] -= int(spirit["damage"])
            shot_trails.append({"from": spirit["pos"], "to": target["pos"], "time": 0.15})
            spirit["cooldown"] = 0.75
            if target["hp"] <= 0:
                enemies.erase(target)
                enemies_defeated += 1
                coins += 5
    queue_redraw()

func apply_burn(enemy: Dictionary) -> void:
    enemy["burn_time"] = 3.0
    enemy["burn_tick"] = 0.5
    enemy["burn_damage"] = 1 + fire_synergy_bonus

func tick_burning(delta: float) -> void:
    for enemy in enemies.duplicate():
        if float(enemy.get("burn_time", 0.0)) <= 0.0:
            continue
        enemy["burn_time"] = maxf(0.0, float(enemy["burn_time"]) - delta)
        enemy["burn_tick"] = float(enemy.get("burn_tick", 0.5)) - delta
        while float(enemy["burn_tick"]) <= 0.0 and float(enemy["burn_time"]) > 0.0:
            enemy["hp"] -= int(enemy.get("burn_damage", 1))
            enemy["burn_tick"] = float(enemy["burn_tick"]) + 0.5
            if enemy["hp"] <= 0:
                enemies.erase(enemy)
                enemies_defeated += 1
                coins += 5
                break

func restart_defense() -> void:
    help_visible = false
    defense_state = "playing"
    altar_hp = 100
    wave_number = 0
    enemies_spawned = 0
    enemies_escaped = 0
    enemies_defeated = 0
    coins = 150
    hero_pos = Vector2(560, 420)
    hero_attack_cooldown = 0.0
    boss_feedback_time = 0.0
    boss_feedback_text = ""
    necro_kill_streak = 0
    summoned_spirits.clear()
    selected_type = ""
    selected_slot = -1
    enemies.clear()
    shot_trails.clear()
    tower_cooldowns.clear()
    for slot in slots:
        slot["tower"] = ""
        slot["level"] = 0
    queue_redraw()

func _process(delta: float) -> void:
    if help_visible or defense_state != "playing":
        return
    if wave_number == 3 and enemies.is_empty():
        defense_state = "won"
        queue_redraw()
        return
    hero_attack_cooldown = maxf(0.0, hero_attack_cooldown - delta)
    boss_feedback_time = maxf(0.0, boss_feedback_time - delta)
    var move_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if Input.is_key_pressed(KEY_A): move_direction.x -= 1.0
    if Input.is_key_pressed(KEY_D): move_direction.x += 1.0
    if Input.is_key_pressed(KEY_W): move_direction.y -= 1.0
    if Input.is_key_pressed(KEY_S): move_direction.y += 1.0
    move_hero(move_direction, delta)
    advance_enemies(delta)
    tick_support_enemies(delta)
    tick_boss(delta)
    tick_burning(delta)
    attack_with_towers(delta)
    tick_necro_spirits(delta)
    for trail in shot_trails.duplicate():
        trail["time"] -= delta
        if trail["time"] <= 0.0:
            shot_trails.erase(trail)
    queue_redraw()


func _ready() -> void:
    sfx = SFX_SCRIPT.new()
    add_child(sfx)
    for i in range(SLOT_POSITIONS.size()):
        slots.append({"id": i, "pos": SLOT_POSITIONS[i], "tower": "", "level": 0, "specialization": "", "target_priority": "nearest"})
    queue_redraw()

func export_fortress_state() -> Dictionary:
    var buildings: Array[Dictionary] = []
    for slot in slots:
        buildings.append({"tower": str(slot["tower"]), "level": int(slot["level"]), "specialization": str(slot.get("specialization", "")), "target_priority": str(slot.get("target_priority", "nearest"))})
    return {"buildings": buildings, "coins": coins, "altar_hp": altar_hp}

func import_fortress_state(state: Dictionary) -> bool:
    var buildings: Array = state.get("buildings", [])
    if buildings.size() != slots.size():
        return false
    for i in range(slots.size()):
        var building: Dictionary = buildings[i]
        var kind: String = str(building.get("tower", ""))
        var level: int = int(building.get("level", 0))
        var spec: String = str(building.get("specialization", ""))
        if not TARGET_PRIORITIES.has(str(building.get("target_priority", "nearest"))):
            return false
        if spec != "" and (level < 2 or not ["siege", "swarm"].has(spec)):
            return false
        if kind != "" and not COSTS.has(kind):
            return false
        if level < 0 or level > 3 or (kind == "" and level != 0) or (kind != "" and level == 0):
            return false
    for i in range(slots.size()):
        slots[i]["tower"] = str(buildings[i]["tower"])
        slots[i]["level"] = int(buildings[i]["level"])
        slots[i]["specialization"] = str(buildings[i].get("specialization", ""))
        slots[i]["target_priority"] = str(buildings[i].get("target_priority", "nearest"))
    coins = maxi(0, int(state.get("coins", coins)))
    altar_hp = clampi(int(state.get("altar_hp", altar_hp)), 1, 100)
    tower_cooldowns.clear()
    selected_slot = -1
    selected_type = ""
    queue_redraw()
    return true

func slot_at(point: Vector2) -> int:
    for i in range(slots.size()):
        if point.distance_to(slots[i]["pos"]) <= 30.0:
            return i
    return -1

func choose_tower(kind: String) -> bool:
    if not COSTS.has(kind):
        return false
    selected_type = kind
    selected_slot = -1
    queue_redraw()
    return true

func build_tower(slot_id: int) -> bool:
    if slot_id < 0 or slot_id >= slots.size() or not COSTS.has(selected_type):
        return false
    if slots[slot_id]["tower"] != "" or coins < COSTS[selected_type]:
        return false
    coins -= COSTS[selected_type]
    slots[slot_id]["tower"] = selected_type
    slots[slot_id]["level"] = 1
    slots[slot_id]["specialization"] = ""
    slots[slot_id]["target_priority"] = "nearest"
    tower_cooldowns[slot_id] = 0.0
    selected_type = ""
    selected_slot = slot_id
    queue_redraw()
    return true

func select_slot(slot_id: int) -> bool:
    if slot_id < 0 or slot_id >= slots.size() or slots[slot_id]["tower"] == "":
        return false
    selected_slot = slot_id
    selected_type = ""
    queue_redraw()
    return true

func upgrade_selected() -> bool:
    if selected_slot < 0 or slots[selected_slot]["tower"] == "":
        return false
    var cost: int = 20 * int(slots[selected_slot]["level"])
    if coins < cost or slots[selected_slot]["level"] >= 3:
        return false
    coins -= cost
    slots[selected_slot]["level"] += 1
    if slots[selected_slot]["level"] == 2 and slots[selected_slot]["specialization"] == "":
        specialization_open = true
    queue_redraw()
    return true

func choose_specialization(path: String) -> bool:
    if not specialization_open or selected_slot < 0 or not ["siege", "swarm"].has(path):
        return false
    slots[selected_slot]["specialization"] = path
    specialization_open = false
    queue_redraw()
    return true

func sell_selected() -> bool:
    if selected_slot < 0 or slots[selected_slot]["tower"] == "":
        return false
    coins += 10 * int(slots[selected_slot]["level"])
    slots[selected_slot]["tower"] = ""
    slots[selected_slot]["level"] = 0
    slots[selected_slot]["specialization"] = ""
    slots[selected_slot]["target_priority"] = "nearest"
    tower_cooldowns.erase(selected_slot)
    selected_slot = -1
    queue_redraw()
    return true

func toggle_controls_help() -> void:
    help_visible = not help_visible
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H:
        toggle_controls_help()
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if HELP_BUTTON.has_point(event.position):
            toggle_controls_help()
            return
        if help_visible:
            if HELP_CLOSE_BUTTON.has_point(event.position):
                toggle_controls_help()
            return
    if specialization_open and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if SPECIALIZATION_BUTTONS[0].has_point(event.position):
            choose_specialization("siege")
        elif SPECIALIZATION_BUTTONS[1].has_point(event.position):
            choose_specialization("swarm")
        return
    if help_visible:
        return
    if event is InputEventKey and event.pressed and event.keycode == KEY_R and defense_state != "playing":
        restart_defense()
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and defense_state != "playing":
        if RESTART_BUTTON.has_point(event.position):
            restart_defense()
        return
    if defense_state != "playing":
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and TARGET_BUTTON.has_point(event.position) and selected_slot >= 0:
        cycle_target_priority()
        return
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        selected_type = ""
        selected_slot = -1
        queue_redraw()
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_RIGHT:
            selected_type = ""
            selected_slot = -1
            queue_redraw()
        elif event.button_index == MOUSE_BUTTON_LEFT:
            var point := get_global_mouse_position()
            if REPAIR_BUTTON.has_point(point):
                repair_altar()
                return
            if WAVE_BUTTON.has_point(point):
                start_wave()
                return
            var types := ["bone", "fire", "necro"]
            for i in range(types.size()):
                if Rect2(260.0 + i * 210.0, 550.0, 180.0, 64.0).has_point(point):
                    choose_tower(types[i])
                    return
            if Rect2(880, 545, 110, 55).has_point(point):
                upgrade_selected()
                return
            if Rect2(1010, 545, 110, 55).has_point(point):
                sell_selected()
                return
            var id := slot_at(point)
            if selected_type != "":
                build_tower(id)
            elif id != -1:
                select_slot(id)
            else:
                hero_attack(point)

# Небольшой самостоятельный арт-проход: собственный процедурный рисунок без
# сторонних лицензий. Позже можно заменить тайлами, сохранив игровую геометрию.
func draw_fortress_ground() -> void:
    draw_rect(Rect2(0, 0, 1152, 648), Color("#111b23"))
    draw_rect(Rect2(28, 66, 1096, 464), Color("#25302f"))
    draw_rect(Rect2(28, 66, 1096, 464), Color("#59665c"), false, 4.0)
    # Повторяемый каменный рисунок с небольшими различиями цвета, без случайности.
    for row in range(10):
        for col in range(24):
            var offset := 12.0 if row % 2 == 1 else 0.0
            var tile := Rect2(40.0 + float(col) * 45.0 + offset, 74.0 + float(row) * 44.0, 41.0, 40.0)
            if tile.end.x > 1118.0:
                continue
            var shade := Color("#303a37") if (col * 7 + row * 3) % 5 == 0 else Color("#293531")
            draw_rect(tile, shade)
            draw_rect(tile, Color("#1d2829"), false, 1.0)
    # Стены цитадели справа и башенки с подсвеченными бойницами.
    draw_rect(Rect2(1090, 92, 38, 418), Color("#151f28"))
    draw_rect(Rect2(1087, 92, 8, 418), Color("#647073"))
    for y in range(105, 505, 66):
        draw_rect(Rect2(1078, y, 51, 42), Color("#4c5962"))
        draw_rect(Rect2(1084, y + 6, 38, 27), Color("#24323d"))
        draw_rect(Rect2(1100, y + 11, 8, 18), Color("#d9a85d"))
    # Входы двух дорог и знамёна возле ворот.
    for entry_y in [285.0, 345.0]:
        draw_rect(Rect2(24, entry_y - 32.0, 40, 64), Color("#121b22"))
        draw_rect(Rect2(40, entry_y - 23.0, 6, 46), Color("#b67861"))
    # Алтарь: подлинная цель нападения, видимая на карте.
    draw_circle(Vector2(1041, 314), 47.0, Color("#18383c"))
    draw_arc(Vector2(1041, 314), 38.0, 0.0, TAU, 48, Color("#6ac4b2"), 4.0)
    draw_circle(Vector2(1041, 314), 19.0, Color("#6b4f78"))
    draw_circle(Vector2(1041, 314), 9.0, Color("#e1b57e"))
    draw_rect(Rect2(0, 0, 1152, 64), Color("#131a27"))
    draw_line(Vector2(0, 64), Vector2(1152, 64), Color("#a08157"), 2.0)
    draw_rect(Rect2(0, 534, 1152, 114), Color("#141b27"))
    draw_line(Vector2(0, 534), Vector2(1152, 534), Color("#8c775b"), 2.0)

func draw_fortress_road(path: Array) -> void:
    for index in range(path.size() - 1):
        var a: Vector2 = path[index]
        var b: Vector2 = path[index + 1]
        draw_line(a, b, Color("#141b1c"), 37.0, true)
        draw_line(a, b, Color("#7b6860"), 31.0, true)
        draw_line(a, b, Color("#a18a76"), 23.0, true)
        draw_line(a, b, Color("#b7a089"), 1.5, true)
    for point in path:
        draw_circle(point, 13.0, Color("#a18a76"))

# Distinct readable silhouettes; no gameplay logic or external asset dependency.
func draw_tower_figure(pos: Vector2, kind: String, level: int) -> void:
    draw_rect(Rect2(pos + Vector2(-16, -21), Vector2(32, 35)), Color("#18242b"))
    draw_rect(Rect2(pos + Vector2(-13, -24), Vector2(26, 30)), Color("#667482"))
    draw_rect(Rect2(pos + Vector2(-10, 1), Vector2(20, 13)), Color("#303942"))
    match kind:
        "bone":
            draw_line(pos + Vector2(-12, -16), pos + Vector2(12, -16), Color("#e8dfc1"), 5.0)
            draw_line(pos + Vector2(-8, -23), pos + Vector2(-8, -7), Color("#e8dfc1"), 4.0)
            draw_line(pos + Vector2(8, -23), pos + Vector2(8, -7), Color("#e8dfc1"), 4.0)
            draw_circle(pos + Vector2(0, -15), 5.0, Color("#a8eee0"))
        "fire":
            draw_colored_polygon(PackedVector2Array([pos + Vector2(-9, -12), pos + Vector2(-3, -34), pos + Vector2(2, -24), pos + Vector2(9, -39), pos + Vector2(11, -11)]), Color("#ee844c"))
            draw_circle(pos + Vector2(1, -15), 7.0, Color("#ffe5a1"))
        "necro":
            draw_line(pos + Vector2(0, -9), pos + Vector2(0, -40), Color("#c9c5dd"), 4.0)
            draw_circle(pos + Vector2(0, -42), 9.0, Color("#6ad7bc"))
            draw_circle(pos + Vector2(0, -42), 4.0, Color("#d8fff2"))
    if level > 1:
        draw_arc(pos, 32.0, -PI / 2.0, -PI / 2.0 + TAU * float(level - 1) / 3.0, 28, Color("#f5dc8c"), 3.0)

func draw_defender_figure(pos: Vector2) -> void:
    draw_circle(pos + Vector2(2, 12), 16.0, Color("#142029"))
    draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -24), pos + Vector2(-17, 9), pos + Vector2(17, 9)]), Color("#34496d"))
    draw_circle(pos + Vector2(0, -13), 10.0, Color("#a8d9dc"))
    draw_circle(pos + Vector2(-4, -14), 2.5, Color("#142229"))
    draw_circle(pos + Vector2(4, -14), 2.5, Color("#142229"))
    draw_line(pos + Vector2(13, -4), pos + Vector2(25, -25), Color("#c6d7df"), 4.0)

func _draw() -> void:
    if specialization_open:
        draw_rect(Rect2(275, 260, 560, 175), Color("#202c38"))
        draw_string(ThemeDB.fallback_font, Vector2(350, 300), "ВЫБЕРИТЕ СПЕЦИАЛИЗАЦИЮ", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#f4dfb7"))
        draw_rect(SPECIALIZATION_BUTTONS[0], Color("#805d49"))
        draw_rect(SPECIALIZATION_BUTTONS[1], Color("#426d6a"))
        if selected_slot >= 0:
            var labels: Array = SPECIALIZATION_LABELS[str(slots[selected_slot]["tower"])]
            draw_string(ThemeDB.fallback_font, Vector2(322, 365), str(labels[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
            draw_string(ThemeDB.fallback_font, Vector2(563, 365), str(labels[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
    draw_fortress_ground()
    if defense_state != "playing":
        draw_rect(Rect2(345, 225, 460, 210), Color("#285849") if defense_state == "won" else Color("#693943"))
        draw_string(ThemeDB.fallback_font, Vector2(485, 301), "ПОБЕДА" if defense_state == "won" else "АЛТАРЬ ПАЛ", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
        draw_rect(RESTART_BUTTON, Color("#8ca9bc"))
        draw_string(ThemeDB.fallback_font, Vector2(480, 386), "НАЧАТЬ ЗАНОВО", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(66, 45), "АЛТАРЬ %d / 100     ВОЛНА %d / 3     ЗОЛОТО %d" % [altar_hp, wave_number, coins], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    if selected_slot >= 0 and selected_slot < slots.size() and slots[selected_slot]["tower"] != "":
        draw_rect(TARGET_BUTTON, Color("#385a63"))
        draw_rect(TARGET_BUTTON, Color("#e5c985"), false, 2.0)
        var priority: String = str(slots[selected_slot].get("target_priority", "nearest"))
        draw_string(ThemeDB.fallback_font, TARGET_BUTTON.position + Vector2(9, 29), "ЦЕЛЬ: " + str(TARGET_LABELS[priority]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fff1c9"))
    var repair_ready: bool = defense_state == "playing" and enemies.is_empty() and wave_number < 3 and altar_hp > 0 and altar_hp < 100 and coins >= REPAIR_COST
    draw_rect(REPAIR_BUTTON, Color("#527b75") if repair_ready else Color("#454b54"))
    draw_string(ThemeDB.fallback_font, REPAIR_BUTTON.position + Vector2(12, 33), "РЕМОНТ +20 / 25 ЗОЛ.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#fff1ce") if repair_ready else Color("#abb2b5"))
    draw_rect(WAVE_BUTTON, Color("#487d6b") if enemies.is_empty() and wave_number < 3 and altar_hp > 0 else Color("#454b54"))
    draw_string(ThemeDB.fallback_font, Vector2(78, 581), "НАЧАТЬ ВОЛНУ", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
    if enemies.is_empty() and defense_state == "playing":
        draw_rect(Rect2(62, 487, 410, 42), Color("#263d43", 0.96))
        draw_string(ThemeDB.fallback_font, Vector2(74, 515), upcoming_wave_summary(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f2d89c"))
    for path in PATHS:
        draw_fortress_road(path)
    for enemy in enemies:
        if enemy["delay"] <= 0.0:
            if enemy.get("role", "") == "boss":
                draw_circle(enemy["pos"], 29.0, Color("#9a4268"))
                draw_circle(enemy["pos"], 19.0, Color("#df96ba"))
                if enemy.get("boss_warning", false):
                    var warning_progress: float = clampf(float(enemy.get("boss_charge", 3.0)) - 3.0, 0.0, 1.0)
                    draw_arc(enemy["pos"], 45.0, -PI / 2.0, -PI / 2.0 + TAU, 48, Color("#694e36"), 4.0)
                    draw_arc(enemy["pos"], 45.0, -PI / 2.0, -PI / 2.0 + TAU * warning_progress, 48, Color("#ffde80"), 6.0)
                    draw_string(ThemeDB.fallback_font, enemy["pos"] + Vector2(-55, -61), "УДАР ПО АЛТАРЮ", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#ffde80"))
                    draw_string(ThemeDB.fallback_font, enemy["pos"] + Vector2(-53, 61), "ГЕРОЙ: 2 УДАРА (%d/2)" % int(enemy.get("interrupt_hits", 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#f6e6c4"))
                draw_rect(Rect2(enemy["pos"] + Vector2(-28.0, -43.0), Vector2(56.0 * clampf(float(enemy["hp"]) / float(55 + difficulty * 15 + (20 if siege_day >= 3 else 0)), 0.0, 1.0), 5.0)), Color("#df7b94"))
            else:
                draw_circle(enemy["pos"], 16.0 if enemy.get("role", "grunt") == "brute" else 10.0 if enemy.get("role", "grunt") == "runner" else 12.0, Color("#8591b8") if enemy.get("role", "grunt") == "brute" else Color("#efc36f") if enemy.get("role", "grunt") == "runner" else Color("#c67f64"))
                if enemy.get("role", "") == "healer":
                    draw_circle(enemy["pos"], 17.0, Color("#427f71"))
                    draw_line(enemy["pos"] + Vector2(-9, 0), enemy["pos"] + Vector2(9, 0), Color("#d8ffe0"), 4.0)
                    draw_line(enemy["pos"] + Vector2(0, -9), enemy["pos"] + Vector2(0, 9), Color("#d8ffe0"), 4.0)
                    draw_arc(enemy["pos"], 135.0, 0.0, TAU, 48, Color("#65b99b", 0.22), 1.5)
    if boss_feedback_time > 0.0:
        draw_rect(Rect2(385, 71, 382, 42), Color("#314f47") if boss_feedback_text == "АТАКА ПРЕРВАНА!" else Color("#683c46"))
        draw_string(ThemeDB.fallback_font, Vector2(407, 98), boss_feedback_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("#fff0cf"))
    for spirit in summoned_spirits:
        draw_circle(spirit["pos"], 10.0, Color("#6de6b2"))
        draw_circle(spirit["pos"], 5.0, Color("#d8fff0"))
    for trail in shot_trails:
        draw_line(trail["from"], trail["to"], Color("#ffda8e"), 4.0)
    draw_defender_figure(hero_pos)
    if selected_slot >= 0 and selected_slot < slots.size() and slots[selected_slot]["tower"] != "":
        var linked: Array[int] = tower_synergy_links(selected_slot)
        for linked_id in linked:
            var source: Vector2 = slots[selected_slot]["pos"]
            var destination: Vector2 = slots[linked_id]["pos"]
            draw_line(source, destination, Color("#f1d08d", 0.8), 4.0)
            draw_arc(destination, 40.0, 0.0, TAU, 32, Color("#e8dc9b"), 3.0)
        if not linked.is_empty():
            draw_rect(Rect2(56, 75, 320, 42), Color("#263b39", 0.95))
            draw_string(ThemeDB.fallback_font, Vector2(72, 102), "СИНЕРГИЯ: %d СВЯЗЕЙ" % linked.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f1dba1"))
    for i in range(slots.size()):
        var pos: Vector2 = slots[i]["pos"]
        var occupied: bool = slots[i]["tower"] != ""
        draw_circle(pos + Vector2(3, 5), 35.0, Color("#152024"))
        draw_circle(pos, 33.0, Color("#64706a") if not occupied else Color("#b48153"))
        draw_circle(pos, 27.0, Color("#1e353b") if not occupied else Color("#e0bb76"))
        draw_arc(pos, 23.0, -PI / 2.0, PI * 1.5, 24, Color("#89b6ab") if not occupied else Color("#724b45"), 2.0)
        if occupied:
            draw_tower_figure(pos, str(slots[i]["tower"]), int(slots[i]["level"]))
            if slots[i].get("specialization", "") != "":
                draw_arc(pos, 28.0, 0.0, TAU, 24, Color("#ffdc91") if slots[i]["specialization"] == "siege" else Color("#86e0bd"), 3.0)
        if not occupied:
            draw_line(pos + Vector2(-8, 0), pos + Vector2(8, 0), Color("#9fc9b9"), 2.0)
            draw_line(pos + Vector2(0, -8), pos + Vector2(0, 8), Color("#9fc9b9"), 2.0)
        if selected_slot == i:
            draw_arc(pos, 39, 0, TAU, 32, Color("#d8d0a1"), 3)
        if selected_type != "" and not occupied and pos.distance_to(get_global_mouse_position()) < 36:
            draw_arc(pos, 80, 0, TAU, 48, Color("#78b8b4"), 2)
    var tower_names := ["КОСТЯНАЯ", "ОГНЕННАЯ", "НЕКРОМАНТ"]
    var tower_ids := ["bone", "fire", "necro"]
    for i in range(3):
        var card := Rect2(260.0 + i * 210.0, 550.0, 180.0, 64.0)
        draw_rect(card, Color("#4f746f") if selected_type == tower_ids[i] else Color("#514b52"))
        draw_rect(card, Color("#e5c985") if selected_type == tower_ids[i] else Color("#796b65"), false, 2.0)
        draw_string(ThemeDB.fallback_font, card.position + Vector2(9, 23), tower_names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
        draw_string(ThemeDB.fallback_font, card.position + Vector2(9, 49), "%d ЗОЛОТА" % COSTS[tower_ids[i]], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e5c985"))
    draw_rect(Rect2(880, 545, 110, 55), Color("#518b78"))
    draw_string(ThemeDB.fallback_font, Vector2(883, 579), "УЛУЧШИТЬ", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
    draw_rect(Rect2(1010, 545, 110, 55), Color("#914c59"))
    draw_string(ThemeDB.fallback_font, Vector2(1020, 579), "ПРОДАТЬ", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

    draw_rect(HELP_BUTTON, Color("#526d9b") if help_visible else Color("#343b47"))
    draw_rect(HELP_BUTTON, Color("#d5c592"), false, 1.5)
    draw_string(ThemeDB.fallback_font, HELP_BUTTON.position + Vector2(23.0, 30.0), "ПОМОЩЬ / H", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#fff2c5"))
    if help_visible:
        var help_panel := Rect2(286, 116, 580, 410)
        draw_rect(help_panel, Color(0.055, 0.07, 0.11, 0.97))
        draw_rect(help_panel, Color("#d5c592"), false, 2.0)
        draw_string(ThemeDB.fallback_font, Vector2(430, 160), "УПРАВЛЕНИЕ ОБОРОНОЙ", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("#e7d3a8"))
        draw_string(ThemeDB.fallback_font, Vector2(326, 207), "WASD / СТРЕЛКИ — движение героя", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(326, 247), "Выбери башню внизу, затем нажми на площадку", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(326, 287), "Нажми на башню, чтобы выбрать её", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(326, 327), "УЛУЧШИТЬ / ПРОДАТЬ — действия с башней", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(326, 367), "Клик по полю — атака героя по курсору", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(326, 407), "ПКМ / Esc — отменить выбор башни", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(326, 447), "НАЧАТЬ ВОЛНУ — запустить врагов", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(326, 490), "Игра на паузе — H или «Продолжить»", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#d5c592"))
        draw_rect(HELP_CLOSE_BUTTON, Color("#527d70"))
        draw_string(ThemeDB.fallback_font, HELP_CLOSE_BUTTON.position + Vector2(11.0, 29.0), "ПРОДОЛЖИТЬ", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
