extends Node2D
## V2 independent top-down TD construction slice. No paths or wave spawning yet.
const SLOT_POSITIONS := [Vector2(280, 190), Vector2(430, 190), Vector2(590, 190), Vector2(750, 190), Vector2(280, 440), Vector2(430, 440), Vector2(590, 440), Vector2(750, 440)]
const COSTS := {"bone": 30, "fire": 45, "necro": 60}
var slots: Array[Dictionary] = []
var selected_type := ""
var selected_slot := -1
var coins := 150
const PATHS := [
    [Vector2(65, 285), Vector2(560, 285), Vector2(1070, 285)],
    [Vector2(65, 345), Vector2(560, 345), Vector2(1070, 345)]
]
var enemies: Array[Dictionary] = []
var wave_number := 0
var altar_hp := 100
var enemies_spawned := 0
var enemies_escaped := 0
var enemies_defeated := 0
var tower_cooldowns: Dictionary = {}
var shot_trails: Array[Dictionary] = []
const TOWER_RANGE := {"bone": 135.0, "fire": 160.0, "necro": 125.0}
const TOWER_DAMAGE := {"bone": 2, "fire": 1, "necro": 3}

func start_wave() -> bool:
    if not enemies.is_empty() or wave_number >= 3 or altar_hp <= 0:
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
        shot_trails.append({"from": tower["pos"], "to": target["pos"], "time": 0.18})
        target["hp"] -= int(TOWER_DAMAGE[kind]) * int(tower["level"])
        tower_cooldowns[slot_id] = 0.8
        if target["hp"] <= 0:
            enemies.erase(target)
            enemies_defeated += 1
            coins += 5
    queue_redraw()

func _process(delta: float) -> void:
    advance_enemies(delta)
    attack_with_towers(delta)
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
            else:
                select_slot(id)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(1152, 648)), Color("#131827"))
    for path in PATHS:
        for i in range(path.size() - 1):
            draw_line(path[i], path[i + 1], Color("#594e50"), 24.0)
    for enemy in enemies:
        if enemy["delay"] <= 0.0:
            draw_circle(enemy["pos"], 12.0, Color("#c67f64"))
    for trail in shot_trails:
        draw_line(trail["from"], trail["to"], Color("#ffda8e"), 4.0)
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
