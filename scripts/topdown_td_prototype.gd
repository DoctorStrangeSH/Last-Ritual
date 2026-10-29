extends Node2D
## V2 independent top-down TD construction slice. No paths or wave spawning yet.
const SLOT_POSITIONS := [Vector2(280, 190), Vector2(430, 190), Vector2(590, 190), Vector2(750, 190), Vector2(280, 440), Vector2(430, 440), Vector2(590, 440), Vector2(750, 440)]
const COSTS := {"bone": 30, "fire": 45, "necro": 60}
const WAVE_BUTTON := Rect2(65, 545, 170, 60)
var slots: Array[Dictionary] = []
var selected_type := ""
var selected_slot := -1
var coins := 150
var fire_synergy_bonus := 0
var bone_synergy_bonus := 0
var necro_kill_bonus := 0
var necro_kill_streak := 0
var summoned_spirits: Array[Dictionary] = []
const PATHS := [
    [Vector2(65, 285), Vector2(560, 285), Vector2(1070, 285)],
    [Vector2(65, 345), Vector2(560, 345), Vector2(1070, 345)]
]
var enemies: Array[Dictionary] = []
var wave_number := 0
var altar_hp := 100
var defense_state := "playing" # playing, won, lost
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
    hero_attack_cooldown = 0.28
    if best["hp"] <= 0:
        enemies.erase(best)
        enemies_defeated += 1
        coins += 5
    queue_redraw()
    return true

func start_wave() -> bool:
    if defense_state != "playing" or not enemies.is_empty() or wave_number >= 3 or altar_hp <= 0:
        return false
    wave_number += 1
    enemies_spawned = 0
    var count := wave_number + 2
    for i in range(count):
        enemies.append({"lane": i % PATHS.size(), "pos": PATHS[i % PATHS.size()][0], "waypoint": 1, "hp": 3 + wave_number, "delay": float(i) * 0.7})
        enemies_spawned += 1
    queue_redraw()
    return true

func advance_enemies(delta: float) -> void:
    for enemy in enemies.duplicate():
        if enemy["delay"] > 0.0:
            enemy["delay"] = maxf(0.0, float(enemy["delay"]) - delta)
            continue
        var path: Array = PATHS[int(enemy["lane"])]
        var waypoint: int = enemy["waypoint"]
        var target: Vector2 = path[waypoint]
        var position: Vector2 = enemy["pos"]
        enemy["pos"] = position.move_toward(target, 85.0 * delta)
        if enemy["pos"].distance_to(target) < 0.1:
            waypoint += 1
            if waypoint >= path.size():
                enemies.erase(enemy)
                enemies_escaped += 1
                altar_hp = maxi(0, altar_hp - 10)
                if altar_hp == 0:
                    defense_state = "lost"
            else:
                enemy["waypoint"] = waypoint
    queue_redraw()

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
        var target: Dictionary = {}
        var nearest := INF
        for enemy in enemies:
            if enemy["delay"] > 0.0:
                continue
            var distance: float = tower["pos"].distance_to(enemy["pos"])
            if distance < nearest and distance <= TOWER_RANGE[kind]:
                nearest = distance
                target = enemy
        if target.is_empty():
            continue
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
        if kind == "fire":
            damage += fire_synergy_bonus
        elif kind == "bone":
            damage += bone_synergy_bonus
        for hit_target in hit_targets:
            shot_trails.append({"from": tower["pos"], "to": hit_target["pos"], "time": 0.18})
            hit_target["hp"] -= damage
            if kind == "fire" and hit_target["hp"] > 0:
                apply_burn(hit_target)
            if hit_target["hp"] <= 0:
                enemies.erase(hit_target)
                enemies_defeated += 1
                coins += 5
                if kind == "necro":
                    coins += necro_kill_bonus
                    necro_kill_streak += 1
                    if necro_kill_streak >= 3:
                        necro_kill_streak = 0
                        spawn_necro_spirit(tower["pos"])
        tower_cooldowns[slot_id] = 0.8
    queue_redraw()

func spawn_necro_spirit(origin: Vector2) -> void:
    # Keep the summon build useful without allowing an unlimited spirit army.
    if summoned_spirits.size() >= 2:
        return
    summoned_spirits.append({"pos": origin, "life": 4.0, "cooldown": 0.0, "damage": 2})

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
    defense_state = "playing"
    altar_hp = 100
    wave_number = 0
    enemies_spawned = 0
    enemies_escaped = 0
    enemies_defeated = 0
    coins = 150
    hero_pos = Vector2(560, 420)
    hero_attack_cooldown = 0.0
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
    if defense_state != "playing":
        return
    if wave_number == 3 and enemies.is_empty():
        defense_state = "won"
        queue_redraw()
        return
    hero_attack_cooldown = maxf(0.0, hero_attack_cooldown - delta)
    var move_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if Input.is_key_pressed(KEY_A): move_direction.x -= 1.0
    if Input.is_key_pressed(KEY_D): move_direction.x += 1.0
    if Input.is_key_pressed(KEY_W): move_direction.y -= 1.0
    if Input.is_key_pressed(KEY_S): move_direction.y += 1.0
    move_hero(move_direction, delta)
    advance_enemies(delta)
    tick_burning(delta)
    attack_with_towers(delta)
    tick_necro_spirits(delta)
    for trail in shot_trails.duplicate():
        trail["time"] -= delta
        if trail["time"] <= 0.0:
            shot_trails.erase(trail)
    queue_redraw()


func _ready() -> void:
    for i in range(SLOT_POSITIONS.size()):
        slots.append({"id": i, "pos": SLOT_POSITIONS[i], "tower": "", "level": 0})
    queue_redraw()

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
    queue_redraw()
    return true

func sell_selected() -> bool:
    if selected_slot < 0 or slots[selected_slot]["tower"] == "":
        return false
    coins += 10 * int(slots[selected_slot]["level"])
    slots[selected_slot]["tower"] = ""
    slots[selected_slot]["level"] = 0
    tower_cooldowns.erase(selected_slot)
    selected_slot = -1
    queue_redraw()
    return true

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_R and defense_state != "playing":
        restart_defense()
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and defense_state != "playing":
        if RESTART_BUTTON.has_point(event.position):
            restart_defense()
        return
    if defense_state != "playing":
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

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(1152, 648)), Color("#131827"))
    if defense_state != "playing":
        draw_rect(Rect2(345, 225, 460, 210), Color("#285849") if defense_state == "won" else Color("#693943"))
        draw_string(ThemeDB.fallback_font, Vector2(485, 301), "VICTORY" if defense_state == "won" else "ALTAR FALLEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
        draw_rect(RESTART_BUTTON, Color("#8ca9bc"))
        draw_string(ThemeDB.fallback_font, Vector2(480, 386), "RESTART DEFENSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(66, 45), "ALTAR %d / 100     WAVE %d / 3     GOLD %d" % [altar_hp, wave_number, coins], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    draw_rect(WAVE_BUTTON, Color("#487d6b") if enemies.is_empty() and wave_number < 3 and altar_hp > 0 else Color("#454b54"))
    draw_string(ThemeDB.fallback_font, Vector2(78, 581), "START WAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
    for path in PATHS:
        for i in range(path.size() - 1):
            draw_line(path[i], path[i + 1], Color("#594e50"), 24.0)
    for enemy in enemies:
        if enemy["delay"] <= 0.0:
            draw_circle(enemy["pos"], 12.0, Color("#c67f64"))
    for spirit in summoned_spirits:
        draw_circle(spirit["pos"], 10.0, Color("#6de6b2"))
        draw_circle(spirit["pos"], 5.0, Color("#d8fff0"))
    for trail in shot_trails:
        draw_line(trail["from"], trail["to"], Color("#ffda8e"), 4.0)
    draw_circle(hero_pos, 15.0, Color("#72cbd9"))
    for i in range(slots.size()):
        var pos: Vector2 = slots[i]["pos"]
        var occupied: bool = slots[i]["tower"] != ""
        draw_circle(pos, 32, Color("#57666e") if not occupied else Color("#a66b50"))
        draw_circle(pos, 26, Color("#202f3a") if not occupied else Color("#d1b57e"))
        if selected_slot == i:
            draw_arc(pos, 39, 0, TAU, 32, Color("#d8d0a1"), 3)
        if selected_type != "" and not occupied and pos.distance_to(get_global_mouse_position()) < 36:
            draw_arc(pos, 80, 0, TAU, 48, Color("#78b8b4"), 2)
    for i in range(3):
        draw_rect(Rect2(260.0 + i * 210.0, 550.0, 180.0, 64.0), Color("#876c58"))
    draw_rect(Rect2(880, 545, 110, 55), Color("#518b78"))
    draw_rect(Rect2(1010, 545, 110, 55), Color("#914c59"))
