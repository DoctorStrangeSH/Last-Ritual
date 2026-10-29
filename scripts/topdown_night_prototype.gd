extends Node2D
## Isolated P1 top-down combat prototype; no save data or classic scene dependencies.
const ARENA := Rect2(48.0, 68.0, 1056.0, 520.0)
const SPEED := 240.0
const ATTACK_RANGE := 155.0
var room_index := 0
var player_pos := Vector2(160.0, 325.0)
var player_hp := 100
var enemies: Array[Dictionary] = []
var reward_available := false
var rewards_taken := 0
var attack_cooldown := 0.0
var invulnerable_time := 0.0

func _ready() -> void:
    open_room(0)

func open_room(index: int) -> void:
    room_index = clampi(index, 0, 2)
    player_pos = Vector2(160.0, 325.0)
    reward_available = false
    enemies.clear()
    for i in range(2):
        enemies.append({"pos": Vector2(570.0 + i * 160.0, 240.0 + i * 130.0), "hp": 3, "speed": 65.0 + i * 20.0})
    queue_redraw()

func move_player(direction: Vector2, delta: float) -> void:
    if direction.length_squared() > 1.0:
        direction = direction.normalized()
    player_pos += direction * SPEED * delta
    player_pos = player_pos.clamp(ARENA.position + Vector2(16, 16), ARENA.end - Vector2(16, 16))
    queue_redraw()

func attack(target: Vector2) -> bool:
    if attack_cooldown > 0.0 or enemies.is_empty():
        return false
    var hit := -1
    var nearest := INF
    for i in range(enemies.size()):
        var p: Vector2 = enemies[i]["pos"]
        var dist := player_pos.distance_to(p)
        if dist <= ATTACK_RANGE and p.distance_to(target) < 55.0 and dist < nearest:
            nearest = dist
            hit = i
    if hit == -1:
        return false
    enemies[hit]["hp"] -= 1
    if enemies[hit]["hp"] <= 0:
        enemies.remove_at(hit)
    if enemies.is_empty():
        reward_available = true
    attack_cooldown = 0.20
    queue_redraw()
    return true

func claim_reward() -> bool:
    if not reward_available:
        return false
    reward_available = false
    rewards_taken += 1
    queue_redraw()
    return true

func door_available() -> bool:
    return enemies.is_empty() and not reward_available and room_index < 2

func next_room() -> bool:
    if not door_available():
        return false
    open_room(room_index + 1)
    return true

func _process(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    invulnerable_time = maxf(0.0, invulnerable_time - delta)
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if Input.is_key_pressed(KEY_A): direction.x -= 1.0
    if Input.is_key_pressed(KEY_D): direction.x += 1.0
    if Input.is_key_pressed(KEY_W): direction.y -= 1.0
    if Input.is_key_pressed(KEY_S): direction.y += 1.0
    move_player(direction, delta)
    for enemy in enemies:
        var pos: Vector2 = enemy["pos"]
        var step: Vector2 = (player_pos - pos).normalized() * float(enemy["speed"]) * delta
        enemy["pos"] = (pos + step).clamp(ARENA.position, ARENA.end)
        if player_pos.distance_to(enemy["pos"]) < 25.0 and invulnerable_time <= 0.0:
            player_hp = maxi(0, player_hp - 10)
            invulnerable_time = 0.75
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if reward_available and player_pos.distance_to(Vector2(576, 325)) < 85.0:
                claim_reward()
            else:
                attack(get_global_mouse_position())
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            if player_pos.distance_to(Vector2(1080.0, 325.0)) < 85.0:
                next_room()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(1152, 648)), Color("#111521"))
    draw_rect(ARENA, Color("#242936"))
    draw_rect(ARENA, Color("#7d7798"), false, 4.0)
    draw_circle(player_pos, 17.0, Color("#80dbed"))
    for enemy in enemies:
        draw_circle(enemy["pos"], 19.0, Color("#cf646c"))
    if reward_available:
        draw_circle(Vector2(576, 325), 24.0, Color("#f4d78c"))
    if door_available():
        draw_rect(Rect2(1058.0, 275.0, 46.0, 96.0), Color("#72b59b"))
    else:
        draw_rect(Rect2(1058.0, 275.0, 46.0, 96.0), Color("#59495b"))
