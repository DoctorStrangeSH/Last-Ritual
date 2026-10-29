extends Node2D
## Isolated P1 top-down combat prototype; no save data or classic scene dependencies.
const ARENA := Rect2(48.0, 68.0, 1056.0, 520.0)
const SFX_SCRIPT = preload("res://scripts/procedural_sfx.gd")
var sfx: Node
const SPEED := 240.0
const ATTACK_RANGE := 155.0
const DASH_DISTANCE := 170.0
const DASH_COOLDOWN := 2.5
const DASH_INVULNERABILITY := 0.22
const RANGED_WARNING := 0.65
const MELEE_WARNING := 0.45
const MELEE_RECHARGE := 1.15
const MELEE_REACH := 60.0
const MELEE_HIT_RADIUS := 32.0
var room_index := 0
var difficulty := 0 # 0 normal, 1 hard, 2 nightmare
var dungeon_seed := 0
var room_variant := 0
var route_boon := ""
var night_souls := 0
var shop_open := false
const ROOM_KINDS := ["CRYPT", "AMBUSH", "ELITE"]
const ROUTE_RECTS := [Rect2(66.0, 490.0, 245.0, 65.0), Rect2(327.0, 490.0, 245.0, 65.0), Rect2(588.0, 490.0, 245.0, 65.0), Rect2(849.0, 490.0, 245.0, 65.0)]
const SHOP_RECTS := [Rect2(340.0, 320.0, 155.0, 60.0), Rect2(500.0, 320.0, 155.0, 60.0), Rect2(660.0, 320.0, 155.0, 60.0)]
const HELP_BUTTON := Rect2(984.0, 10.0, 153.0, 46.0)
const HELP_CLOSE_BUTTON := Rect2(688.0, 441.0, 135.0, 48.0)
const DASH_BUTTON := Rect2(60.0, 600.0, 170.0, 38.0)
var player_pos := Vector2(160.0, 325.0)
var last_move_direction := Vector2.RIGHT
var dash_cooldown := 0.0
var dash_flash_time := 0.0
var dash_origin := Vector2.ZERO
var player_hp := 100
var enemies: Array[Dictionary] = []
var hostile_shots: Array[Dictionary] = []
var ranged_fire_clock := 0.0
var reward_available := false
var rewards_taken := 0
var relics: Array[String] = []
var attack_damage := 1
var attack_speed_multiplier := 1.0
var attack_cooldown := 0.0
var invulnerable_time := 0.0
var player_hit_flash := 0.0
var floating_combat_texts: Array[Dictionary] = []
var death_bursts: Array[Dictionary] = []
var reward_notice := ""
var reward_notice_time := 0.0
var run_state := "playing" # playing, won, lost
var help_visible := false

func _ready() -> void:
    sfx = SFX_SCRIPT.new()
    add_child(sfx)
    open_room(0)

func open_room(index: int, override_variant: int = -1) -> void:
    room_index = clampi(index, 0, 2)
    player_pos = Vector2(160.0, 325.0)
    reward_available = false
    shop_open = false
    enemies.clear()
    hostile_shots.clear()
    ranged_fire_clock = 0.0
    death_bursts.clear()
    floating_combat_texts.clear()
    reward_notice = ""
    reward_notice_time = 0.0
    room_variant = override_variant if override_variant >= 0 else posmod(dungeon_seed + index, ROOM_KINDS.size())
    var offsets := [Vector2.ZERO, Vector2(-90.0, 65.0), Vector2(40.0, -65.0)]
    var offset: Vector2 = offsets[room_variant]
    for i in range(2):
        enemies.append({"pos": Vector2(570.0 + i * 160.0, 240.0 + i * 130.0) + offset, "hp": 3 + (2 if room_variant == 2 else 0) + difficulty * 2, "speed": (65.0 + i * 20.0 + (25.0 if room_variant == 1 else 0.0)) * (1.0 + difficulty * 0.15), "ranged": i == 1})
    if room_variant == 2:
        enemies.append({"pos": Vector2(850.0, 450.0), "hp": 6 + difficulty * 2, "speed": 90.0 * (1.0 + difficulty * 0.15), "ranged": false})
    queue_redraw()

func set_dungeon_seed(value: int) -> void:
    dungeon_seed = value
    if run_state == "playing" and room_index == 0 and rewards_taken == 0:
        open_room(0)

func move_player(direction: Vector2, delta: float) -> void:
    if run_state != "playing":
        return
    if direction.length_squared() > 1.0:
        direction = direction.normalized()
    if direction.length_squared() > 0.01:
        last_move_direction = direction.normalized()
    player_pos += direction * SPEED * delta
    player_pos = player_pos.clamp(ARENA.position + Vector2(16, 16), ARENA.end - Vector2(16, 16))
    queue_redraw()

func dash() -> bool:
    if help_visible or run_state != "playing" or shop_open or reward_available or dash_cooldown > 0.0:
        return false
    if last_move_direction.length_squared() < 0.01:
        return false
    var destination: Vector2 = (player_pos + last_move_direction.normalized() * DASH_DISTANCE).clamp(ARENA.position + Vector2(16, 16), ARENA.end - Vector2(16, 16))
    if player_pos.distance_squared_to(destination) < 1.0:
        return false
    dash_origin = player_pos
    player_pos = destination
    dash_cooldown = DASH_COOLDOWN
    dash_flash_time = 0.18
    invulnerable_time = maxf(invulnerable_time, DASH_INVULNERABILITY)
    queue_redraw()
    return true

func attack(target: Vector2) -> bool:
    if run_state != "playing" or attack_cooldown > 0.0 or enemies.is_empty():
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
    enemies[hit]["hp"] -= attack_damage
    sfx.play_effect("hit")
    enemies[hit]["hit_flash"] = 0.12
    floating_combat_texts.append({"pos": enemies[hit]["pos"] + Vector2(0, -22), "text": "-%d" % attack_damage, "time": 0.65, "color": Color("#fff0b0")})
    if enemies[hit]["hp"] <= 0:
        death_bursts.append({"pos": enemies[hit]["pos"], "time": 0.4})
        sfx.play_effect("kill")
        enemies.remove_at(hit)
        night_souls += 1
    if enemies.is_empty():
        reward_available = true
    attack_cooldown = 0.20 / attack_speed_multiplier
    queue_redraw()
    return true

func claim_reward() -> bool:
    return choose_relic("bone")

func choose_relic(kind: String) -> bool:
    if run_state != "playing" or not reward_available or not kind in ["bone", "ember", "blood"]:
        return false
    reward_available = false
    rewards_taken += 1
    if room_index == 2:
        run_state = "won"
    relics.append(kind)
    reward_notice = "RELIC ACQUIRED: %s" % kind.to_upper()
    reward_notice_time = 1.4
    sfx.play_effect("relic")
    match kind:
        "bone":
            attack_damage += 1
        "ember":
            attack_speed_multiplier += 0.25
        "blood":
            player_hp = maxi(1, player_hp - 15)
            attack_damage += 2
    queue_redraw()
    return true

func door_available() -> bool:
    return run_state == "playing" and not shop_open and enemies.is_empty() and not reward_available and room_index < 2

func next_room() -> bool:
    return choose_route(0)

func choose_route(choice: int) -> bool:
    if not door_available() or choice < 0 or choice >= ROUTE_RECTS.size():
        return false
    var variant := posmod(dungeon_seed + room_index + 1 + choice, ROOM_KINDS.size())
    if choice == 0:
        # Treasury route: recover health before the next encounter.
        player_hp = mini(100, player_hp + 18)
        route_boon = "TREASURE: +18 HP"
    elif choice == 1:
        # Risk route: trade health for run-long damage and fight an elite room.
        if player_hp <= 12:
            return false
        player_hp -= 12
        attack_damage += 1
        variant = 2
        route_boon = "RISK: -12 HP / +1 DAMAGE"
    elif choice == 2:
        # Cursed altar event: a larger sacrifice buys permanent speed this night.
        if player_hp <= 20:
            return false
        player_hp -= 20
        attack_speed_multiplier += 0.35
        variant = 1
        route_boon = "CURSED ALTAR: -20 HP / +35% SPEED"
    else:
        shop_open = true
        route_boon = "MERCHANT: SPEND SOULS OR LEAVE"
        queue_redraw()
        return true
    open_room(room_index + 1, variant)
    return true

func buy_shop_offer(choice: int) -> bool:
    if not shop_open or run_state != "playing" or choice < 0 or choice > 1:
        return false
    var price := 2 if choice == 0 else 1
    if night_souls < price:
        return false
    night_souls -= price
    if choice == 0:
        attack_damage += 1
        route_boon = "MERCHANT: +1 DAMAGE"
    else:
        player_hp = mini(100, player_hp + 20)
        route_boon = "MERCHANT: +20 HP"
    queue_redraw()
    return true

func leave_shop() -> bool:
    if not shop_open or run_state != "playing":
        return false
    shop_open = false
    open_room(room_index + 1)
    return true

func restart_run() -> void:
    help_visible = false
    dash_cooldown = 0.0
    dash_flash_time = 0.0
    last_move_direction = Vector2.RIGHT
    player_hp = 100
    night_souls = 0
    shop_open = false
    route_boon = ""
    rewards_taken = 0
    relics.clear()
    attack_damage = 1
    attack_speed_multiplier = 1.0
    attack_cooldown = 0.0
    invulnerable_time = 0.0
    player_hit_flash = 0.0
    floating_combat_texts.clear()
    death_bursts.clear()
    reward_notice = ""
    reward_notice_time = 0.0
    run_state = "playing"
    open_room(0)

func take_damage(amount: int) -> void:
    if run_state != "playing" or invulnerable_time > 0.0 or amount <= 0:
        return
    player_hp = maxi(0, player_hp - amount)
    sfx.play_effect("damage")
    player_hit_flash = 0.22
    floating_combat_texts.append({"pos": player_pos + Vector2(0, -26), "text": "-%d HP" % amount, "time": 0.8, "color": Color("#ff7c91")})
    invulnerable_time = 0.75
    if player_hp == 0:
        run_state = "lost"
        hostile_shots.clear()
    queue_redraw()

func _process(delta: float) -> void:
    if help_visible or run_state != "playing":
        return
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    dash_cooldown = maxf(0.0, dash_cooldown - delta)
    dash_flash_time = maxf(0.0, dash_flash_time - delta)
    invulnerable_time = maxf(0.0, invulnerable_time - delta)
    player_hit_flash = maxf(0.0, player_hit_flash - delta)
    reward_notice_time = maxf(0.0, reward_notice_time - delta)
    for burst in death_bursts.duplicate():
        burst["time"] = float(burst["time"]) - delta
        if float(burst["time"]) <= 0.0:
            death_bursts.erase(burst)
    for combat_text in floating_combat_texts.duplicate():
        combat_text["time"] = float(combat_text["time"]) - delta
        combat_text["pos"] = combat_text["pos"] + Vector2(0, -24.0 * delta)
        if float(combat_text["time"]) <= 0.0:
            floating_combat_texts.erase(combat_text)
    for enemy in enemies:
        enemy["hit_flash"] = maxf(0.0, float(enemy.get("hit_flash", 0.0)) - delta)
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if Input.is_key_pressed(KEY_A): direction.x -= 1.0
    if Input.is_key_pressed(KEY_D): direction.x += 1.0
    if Input.is_key_pressed(KEY_W): direction.y -= 1.0
    if Input.is_key_pressed(KEY_S): direction.y += 1.0
    move_player(direction, delta)
    update_enemy_attacks(delta)
    for shot in hostile_shots.duplicate():
        shot["pos"] += shot["velocity"] * delta
        if not ARENA.has_point(shot["pos"]):
            hostile_shots.erase(shot)
        elif shot["pos"].distance_to(player_pos) <= 19.0:
            if invulnerable_time <= 0.0:
                take_damage(8)
            hostile_shots.erase(shot)
    for enemy in enemies:
        var pos: Vector2 = enemy["pos"]
        var step: Vector2 = (player_pos - pos).normalized() * float(enemy["speed"]) * delta
        if enemy["ranged"] and player_pos.distance_to(pos) < 230.0:
            step = Vector2.ZERO
        if not enemy["ranged"] and float(enemy.get("melee_warning", 0.0)) > 0.0:
            step = Vector2.ZERO
        enemy["pos"] = (pos + step).clamp(ARENA.position, ARENA.end)
    queue_redraw()

func update_enemy_attacks(delta: float) -> void:
    # Ranged units lock their aim during a visible windup rather than firing instantly.
    ranged_fire_clock += delta
    if ranged_fire_clock >= 1.7:
        ranged_fire_clock = fmod(ranged_fire_clock, 1.7)
        for enemy in enemies:
            if enemy["ranged"] and float(enemy.get("ranged_warning", 0.0)) <= 0.0:
                enemy["ranged_warning"] = RANGED_WARNING
                enemy["attack_target"] = player_pos
    for enemy in enemies:
        if enemy["ranged"]:
            var ranged_remaining: float = float(enemy.get("ranged_warning", 0.0))
            if ranged_remaining > 0.0:
                enemy["ranged_warning"] = maxf(0.0, ranged_remaining - delta)
                if float(enemy["ranged_warning"]) <= 0.0:
                    shoot_hostile(enemy["pos"], enemy["attack_target"])
            continue
        var recovery: float = maxf(0.0, float(enemy.get("melee_recharge", 0.0)) - delta)
        enemy["melee_recharge"] = recovery
        var melee_remaining: float = float(enemy.get("melee_warning", 0.0))
        if melee_remaining > 0.0:
            enemy["melee_warning"] = maxf(0.0, melee_remaining - delta)
            if float(enemy["melee_warning"]) <= 0.0:
                # The target was locked before the strike: dodging out avoids it.
                if player_pos.distance_to(enemy["attack_target"]) <= MELEE_HIT_RADIUS:
                    take_damage(10)
                enemy["melee_recharge"] = MELEE_RECHARGE
        elif recovery <= 0.0 and enemy["pos"].distance_to(player_pos) <= MELEE_REACH:
            enemy["melee_warning"] = MELEE_WARNING
            enemy["attack_target"] = player_pos

func shoot_hostile(origin: Vector2, target: Vector2 = Vector2.ZERO) -> void:
    var aimed: Vector2 = player_pos if target == Vector2.ZERO else target
    var direction := (aimed - origin).normalized()
    if direction == Vector2.ZERO:
        return
    hostile_shots.append({"pos": origin, "velocity": direction * 180.0})
    queue_redraw()

const RESTART_BUTTON := Rect2(444.0, 304.0, 264.0, 52.0)
const RELIC_RECTS := [
    Rect2(280.0, 450.0, 180.0, 70.0),
    Rect2(490.0, 450.0, 180.0, 70.0),
    Rect2(700.0, 450.0, 180.0, 70.0)
]
const RELIC_IDS := ["bone", "ember", "blood"]
const RELIC_TITLES := ["BONE SHARD", "EMBER", "BLOOD PACT"]
const RELIC_EFFECTS := ["+1 DAMAGE", "+25% ATTACK SPEED", "-15 HP / +2 DAMAGE"]

func click_ui(point: Vector2) -> bool:
    if run_state != "playing":
        if RESTART_BUTTON.has_point(point):
            restart_run()
            return true
        return false
    if shop_open:
        for i in range(SHOP_RECTS.size()):
            if SHOP_RECTS[i].has_point(point):
                return leave_shop() if i == 2 else buy_shop_offer(i)
        return false
    if not reward_available:
        if door_available():
            for i in range(ROUTE_RECTS.size()):
                if ROUTE_RECTS[i].has_point(point):
                    return choose_route(i)
        return false
    for i in range(RELIC_RECTS.size()):
        if RELIC_RECTS[i].has_point(point):
            return choose_relic(RELIC_IDS[i])
    return false

func draw_label(value: String, point: Vector2, font_size: int = 18, color: Color = Color.WHITE) -> void:
    draw_string(ThemeDB.fallback_font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

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
    if help_visible:
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
        dash()
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and DASH_BUTTON.has_point(event.position):
        dash()
        return
    if event is InputEventKey and event.pressed and event.keycode == KEY_R and run_state != "playing":
        restart_run()
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if click_ui(event.position):
            return
    if run_state != "playing":
        return
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if not reward_available and not shop_open:
                attack(get_global_mouse_position())
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            if player_pos.distance_to(Vector2(1080.0, 325.0)) < 85.0:
                next_room()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(1152, 648)), Color("#111521"))
    draw_rect(ARENA, Color("#242936"))
    draw_rect(ARENA, Color("#7d7798"), false, 4.0)
    if dash_flash_time > 0.0:
        draw_line(dash_origin, player_pos, Color("#83e4ed", dash_flash_time / 0.18), 8.0)
    draw_circle(player_pos, 22.0 if player_hit_flash > 0.0 else 17.0, Color("#fff1d1") if player_hit_flash > 0.0 else (Color("#80dbed") if invulnerable_time <= 0.0 or int(invulnerable_time * 16.0) % 2 == 0 else Color("#4c657a")))
    draw_rect(Rect2(48.0, 25.0, 220.0, 18.0), Color("#442c37"))
    draw_rect(Rect2(48.0, 25.0, 220.0 * float(player_hp) / 100.0, 18.0), Color("#cf657a"))
    draw_label("HP %d / 100   ROOM %d / 3   %s   SOULS %d   RELICS %d" % [player_hp, room_index + 1, ROOM_KINDS[room_variant], night_souls, relics.size()], Vector2(280, 41), 17)
    if route_boon != "":
        draw_label(route_boon, Vector2(300, 65), 14, Color("#d5c592"))
    if run_state == "won":
        draw_rect(Rect2(350.0, 190.0, 452.0, 180.0), Color("#295343"))
        draw_label("VICTORY", Vector2(510, 245), 30)
    if run_state == "lost":
        draw_rect(Rect2(350.0, 190.0, 452.0, 180.0), Color("#422837"))
        draw_label("DEFEAT", Vector2(510, 245), 30)
    if run_state != "playing":
        draw_rect(RESTART_BUTTON, Color("#739bb0"))
        draw_label("RESTART RUN", Vector2(488, 337), 22)
    for enemy in enemies:
        var ranged_remaining: float = float(enemy.get("ranged_warning", 0.0))
        var melee_remaining: float = float(enemy.get("melee_warning", 0.0))
        if ranged_remaining > 0.0:
            var aim: Vector2 = enemy["attack_target"]
            var ranged_charge: float = 1.0 - ranged_remaining / RANGED_WARNING
            draw_line(enemy["pos"], aim, Color("#ffbc76", 0.45 + ranged_charge * 0.55), 3.0)
            draw_arc(aim, 24.0, -PI / 2.0, -PI / 2.0 + TAU * ranged_charge, 32, Color("#ffbc76"), 4.0)
        elif melee_remaining > 0.0:
            var attack_at: Vector2 = enemy["attack_target"]
            var melee_charge: float = 1.0 - melee_remaining / MELEE_WARNING
            draw_arc(attack_at, MELEE_HIT_RADIUS, -PI / 2.0, -PI / 2.0 + TAU * melee_charge, 32, Color("#ff7b89"), 5.0)
        var enemy_color: Color = Color("#fff1d1") if float(enemy.get("hit_flash", 0.0)) > 0.0 else (Color("#aa70d6") if enemy["ranged"] else Color("#cf646c"))
        draw_circle(enemy["pos"], 23.0 if float(enemy.get("hit_flash", 0.0)) > 0.0 else 19.0, enemy_color)
    for burst in death_bursts:
        var progress: float = 1.0 - float(burst["time"]) / 0.4
        draw_arc(burst["pos"], 20.0 + progress * 24.0, 0.0, TAU, 24, Color("#f0a0b1", 1.0 - progress), 3.0)
    for shot in hostile_shots:
        draw_circle(shot["pos"], 7.0, Color("#ffbd77"))
    for combat_text in floating_combat_texts:
        draw_label(str(combat_text["text"]), combat_text["pos"], 16, combat_text["color"])
    if reward_notice_time > 0.0:
        draw_rect(Rect2(387, 91, 380, 44), Color("#314f47"))
        draw_label(reward_notice, Vector2(414, 119), 19, Color("#fff1c8"))
    if reward_available:
        draw_circle(Vector2(576, 325), 24.0, Color("#f4d78c"))
        draw_label("CHOOSE ONE RELIC", Vector2(480, 425), 23)
        var palette := [Color("#526d9b"), Color("#a16a36"), Color("#863c54")]
        for i in range(RELIC_RECTS.size()):
            draw_rect(RELIC_RECTS[i], palette[i])
            if RELIC_RECTS[i].has_point(get_local_mouse_position()):
                draw_rect(RELIC_RECTS[i], Color("#fff2c5"), false, 3.0)
            draw_label(RELIC_TITLES[i], RELIC_RECTS[i].position + Vector2(10, 26), 15)
            draw_label(RELIC_EFFECTS[i], RELIC_RECTS[i].position + Vector2(10, 50), 12)
    if shop_open:
        draw_rect(Rect2(285.0, 205.0, 570.0, 220.0), Color("#263b45"))
        draw_label("WANDERING MERCHANT - SOULS %d" % night_souls, Vector2(359, 255), 23)
        for i in range(SHOP_RECTS.size()):
            draw_rect(SHOP_RECTS[i], Color("#4e8373") if i < 2 else Color("#775e6d"))
            draw_label("+1 DMG / 2" if i == 0 else "+20 HP / 1" if i == 1 else "LEAVE", SHOP_RECTS[i].position + Vector2(10, 37), 17)
    if door_available():
        draw_label("CHOOSE YOUR NEXT ROUTE", Vector2(450, 473), 22)
        for i in range(ROUTE_RECTS.size()):
            var variant := posmod(dungeon_seed + room_index + 1 + i, ROOM_KINDS.size())
            draw_rect(ROUTE_RECTS[i], Color("#496c74") if i == 0 else Color("#81556e") if i == 1 else Color("#7a568b") if i == 2 else Color("#6c8061"))
            var offer := "TREASURE +18 HP" if i == 0 else "RISK -12 HP / +1 ATK" if i == 1 else "CURSE -20 HP / +35% SPD" if i == 2 else "MERCHANT / SOULS"
            draw_label(offer, ROUTE_RECTS[i].position + Vector2(10, 39), 16)
        draw_rect(Rect2(1058.0, 275.0, 46.0, 96.0), Color("#72b59b"))
    else:
        draw_rect(Rect2(1058.0, 275.0, 46.0, 96.0), Color("#59495b"))

    draw_rect(DASH_BUTTON, Color("#497b80") if dash_cooldown <= 0.0 and run_state == "playing" and not reward_available and not shop_open else Color("#353c46"))
    draw_label("DASH / SPACE" if dash_cooldown <= 0.0 else "DASH %.1fs" % dash_cooldown, DASH_BUTTON.position + Vector2(14, 26), 16, Color("#fff2c5"))
    draw_rect(HELP_BUTTON, Color("#526d9b") if help_visible else Color("#343b47"))
    draw_rect(HELP_BUTTON, Color("#d5c592"), false, 1.5)
    draw_label("HELP / H", HELP_BUTTON.position + Vector2(24.0, 30.0), 16, Color("#fff2c5"))
    if help_visible:
        var help_panel := Rect2(306, 144, 540, 360)
        draw_rect(help_panel, Color(0.055, 0.07, 0.11, 0.97))
        draw_rect(help_panel, Color("#d5c592"), false, 2.0)
        draw_label("NIGHT CONTROLS", Vector2(435, 190), 27, Color("#e7d3a8"))
        draw_label("WASD / ARROWS  -  Move", Vector2(354, 238), 18)
        draw_label("LEFT CLICK enemy  -  Attack in range", Vector2(354, 273), 18)
        draw_label("CLICK a relic card  -  Choose your reward", Vector2(354, 308), 17)
        draw_label("CLICK a route card  -  Choose the next room", Vector2(354, 343), 17)
        draw_label("SPACE / DASH  -  Evade warning circles and aim lines", Vector2(354, 378), 15)
        draw_label("RIGHT CLICK near the door  -  Advance", Vector2(354, 409), 16)
        draw_label("H  -  Close this help panel", Vector2(354, 438), 16, Color("#d5c592"))
        draw_label("The action pauses while help is open.", Vector2(354, 469), 14, Color("#9da9bf"))
        draw_rect(HELP_CLOSE_BUTTON, Color("#527d70"))
        draw_label("CONTINUE", HELP_CLOSE_BUTTON.position + Vector2(12.0, 31.0), 17, Color.WHITE)
