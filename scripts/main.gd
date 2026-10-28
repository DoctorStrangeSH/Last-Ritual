extends Node2D
## Last Ritual v1.7: final siege, Godot 4.2+
const W := 1152.0
const H := 648.0
const FLOOR := 550.0
const DAY_LENGTH := 56.0
const MAX_WALL := 100.0
var phase := "title"
var time_left := DAY_LENGTH
var wall_hp := MAX_WALL
var mana := 70
var souls := 0
var enemies: Array[Dictionary] = []
var towers: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var spawn_timer := 0.0
var wave_count := 0
var player := Vector2(95, FLOOR - 25)
var vel := Vector2.ZERO
var grounded := false
var facing := 1.0
var jump_was_down := false
var swing_timer := 0.0
var boss_strike_timer := 2.0
var boss_windup := 0.0
var potions_used := 0
var dash_cooldown := 0.0
var dash_trail := 0.0
var platforms := [Rect2(205, 473, 135, 16), Rect2(415, 413, 145, 16), Rect2(640, 462, 130, 16), Rect2(830, 396, 135, 16)]
var gems: Array[Vector2] = []
var night_enemies: Array[Dictionary] = []
var mage: Dictionary = {}
var mage_bolts: Array[Dictionary] = []
var boss_hp := 140.0
var boss_pos := Vector2(1015, FLOOR - 46)
var stone_taken := false
var attack_cooldown := 0.0
var hurt_cooldown := 0.0
var player_hp := 100.0
var notice := ""
var notice_timer := 0.0
var font: Font
var paused := false
var kills_today := 0
var repairs_today := 0
var selected_build := "bone"
var day_elapsed := 0.0
var current_day := 1
var stones_collected := 0
var tower_power_level := 0
var wall_ward_level := 0
var saboteurs_defeated := 0
var trap_clock := 0.0
var trap_positions := [375.0, 775.0]
var chest_taken := false
var relic_taken := false
var final_timer := 45.0

func _ready() -> void:
    font = ThemeDB.fallback_font
    reset_all()

func reset_all() -> void:
    phase = "title"
    paused = false
    kills_today = 0
    repairs_today = 0
    selected_build = "bone"
    day_elapsed = 0.0
    current_day = 1
    stones_collected = 0
    tower_power_level = 0
    wall_ward_level = 0
    saboteurs_defeated = 0
    trap_clock = 0.0
    chest_taken = false
    relic_taken = false
    final_timer = 45.0
    time_left = DAY_LENGTH
    wall_hp = MAX_WALL
    mana = 70
    souls = 0
    enemies.clear()
    towers.clear()
    shots.clear()
    wave_count = 0
    spawn_timer = 1.0
    player = Vector2(95, FLOOR - 25)
    vel = Vector2.ZERO
    grounded = true
    facing = 1.0
    jump_was_down = false
    swing_timer = 0.0
    boss_strike_timer = 2.0
    boss_windup = 0.0
    potions_used = 0
    dash_cooldown = 0.0
    dash_trail = 0.0
    player_hp = 100.0
    boss_hp = 140.0
    stone_taken = false
    attack_cooldown = 0.0
    hurt_cooldown = 0.0
    gems = [Vector2(250, 442), Vector2(460, 380), Vector2(689, 429), Vector2(879, 363), Vector2(535, 520)]
    night_enemies = [{"x": 350.0, "hp": 44.0, "dir": -1.0}, {"x": 700.0, "hp": 44.0, "dir": 1.0}]
    mage = {"x": 570.0, "hp": 60.0, "cooldown": 1.4}
    mage_bolts.clear()
    notice = ""
    notice_timer = 0.0
    queue_redraw()

func _process(delta: float) -> void:
    if paused:
        queue_redraw()
        return
    if notice_timer > 0:
        notice_timer -= delta
    if phase == "day":
        update_day(delta)
    elif phase == "night":
        update_night(delta)
    elif phase == "final_siege":
        final_timer -= delta
        update_day(delta)
        if phase == "night":
            phase = "final_siege"
        if wall_hp > 0.0 and final_timer <= 0.0:
            phase = "win"
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_P and phase != "title" and phase != "win" and phase != "lose":
            paused = not paused
            queue_redraw()
            return
        if paused:
            return
        if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
            if phase == "title" or phase == "win" or phase == "lose":
                reset_all()
                phase = "day"
            elif phase == "ritual":
                resolve_altar()
        if phase == "day" or phase == "final_siege":
            if event.keycode == KEY_R:
                repair_wall()
            elif event.keycode == KEY_1:
                selected_build = "bone"
                show_notice("Выбрана костяная башня: щёлкни мышью, чтобы построить")
            elif event.keycode == KEY_2:
                selected_build = "fire"
                show_notice("Выбрана адская баллиста: щёлкни мышью, чтобы построить")
        elif phase == "night":
            if event.keycode == KEY_J:
                attack()
            elif event.keycode == KEY_H:
                heal_player()
            elif event.keycode == KEY_SHIFT:
                shadow_dash()
        elif phase == "ritual" and event.keycode == KEY_1:
            buy_upgrade("tower")
        elif phase == "ritual" and event.keycode == KEY_2:
            buy_upgrade("ward")
        elif phase == "ritual" and event.keycode == KEY_C:
            if mana >= 25:
                mana -= 25
                souls += 1
                show_notice("Алтарь преобразовал ману в душу")
            else:
                show_notice("Не хватает маны для преобразования")

func resolve_altar() -> void:
    if phase != "ritual":
        return
    if stones_collected < 5:
        current_day += 1
        phase = "day"
        time_left = DAY_LENGTH
        day_elapsed = 0.0
        spawn_timer = 1.0
        wave_count = 0
        enemies.clear()
        shots.clear()
        player_hp = 100.0
        show_notice("День %d: армия Света усилилась! Башни сохранены." % current_day)
    elif mana >= 50 and souls >= 8:
        mana -= 50
        souls -= 8
        phase = "final_siege"
        final_timer = 45.0
        enemies.clear()
        shots.clear()
        spawn_timer = 0.3
        show_notice("Последний штурм! Продержись 45 секунд.")
    else:
        show_notice("Для ритуала нужно 50 маны и 8 душ. C — обмен.")

func _input(event: InputEvent) -> void:
    if (phase == "day" or phase == "final_siege") and not paused and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        build_tower(selected_build, get_global_mouse_position().x)

func buy_upgrade(kind: String) -> void:
    if stones_collected >= 5:
        show_notice("Осада окончена: заверши ритуал")
        return
    if kind == "tower":
        if tower_power_level >= 1:
            show_notice("Усиление башен уже приобретено")
        elif mana < 45:
            show_notice("Для усиления башен нужно 45 маны")
        else:
            mana -= 45
            tower_power_level = 1
            show_notice("Башни усилены: +35% урона навсегда")
    elif kind == "ward":
        if wall_ward_level >= 1:
            show_notice("Защитная печать уже активирована")
        elif souls < 4:
            show_notice("Для печати нужно 4 души")
        else:
            souls -= 4
            wall_ward_level = 1
            wall_hp = minf(MAX_WALL, wall_hp + 30.0)
            show_notice("Печать укрепила стены и снизила урон на 25%")

func show_notice(message: String) -> void:
    notice = message
    notice_timer = 2.7

func build_tower(kind: String, mx: float) -> void:
    var cost := 30 if kind == "bone" else 55
    if mx < 245 or mx > 1020:
        show_notice("Ставь башни между крепостью и врагом")
        return
    if mana < cost:
        show_notice("Недостаточно маны")
        return
    for tower in towers:
        if absf(tower["x"] - mx) < 65.0:
            show_notice("Башни слишком близко")
            return
    mana -= cost
    towers.append({"x": mx, "type": kind, "cooldown": 0.0})
    show_notice("Построено: " + ("Костяная башня" if kind == "bone" else "Адская баллиста"))

func repair_wall() -> void:
    if wall_hp >= MAX_WALL:
        show_notice("Стены уже целы")
        return
    if mana < 20:
        show_notice("Для ремонта нужно 20 маны")
        return
    mana -= 20
    repairs_today += 1
    wall_hp = minf(MAX_WALL, wall_hp + 25.0)
    show_notice("Стены восстановлены на 25 прочности")

func begin_night() -> void:
    phase = "night"
    stone_taken = false
    player = Vector2(95, FLOOR - 25)
    vel = Vector2.ZERO
    grounded = true
    jump_was_down = false
    player_hp = 100.0
    boss_hp = 140.0 if current_day == 1 else (190.0 if current_day == 2 else (230.0 if current_day == 3 else (270.0 if current_day == 4 else 340.0)))
    boss_strike_timer = 2.0
    boss_windup = 0.0
    mage = {"x": 570.0, "hp": 60.0 if current_day == 1 else 85.0, "cooldown": 1.4}
    mage_bolts.clear()
    night_enemies = [{"x": 350.0, "hp": 44.0, "dir": -1.0}, {"x": 700.0, "hp": 44.0 if current_day == 1 else 70.0, "dir": 1.0}]
    gems = [Vector2(250, 442), Vector2(460, 380), Vector2(689, 429), Vector2(879, 363), Vector2(535, 520)]
    chest_taken = false
    relic_taken = false
    trap_clock = 0.0
    if current_day == 5:
        platforms = [Rect2(190, 450, 150, 16), Rect2(415, 390, 140, 16), Rect2(600, 345, 130, 16), Rect2(795, 390, 130, 16)]
        trap_positions = [325.0, 520.0, 755.0, 965.0]
        gems = [Vector2(252, 419), Vector2(470, 359), Vector2(658, 315), Vector2(858, 358), Vector2(1030, 514)]
        mage["x"] = 680.0
        mage["hp"] = 145.0
        night_enemies = [{"x": 315.0, "hp": 115.0, "dir": -1.0}, {"x": 810.0, "hp": 130.0, "dir": 1.0}]
    elif current_day == 4:
        platforms = [Rect2(160, 460, 135, 16), Rect2(365, 400, 140, 16), Rect2(560, 350, 145, 16), Rect2(770, 410, 150, 16)]
        trap_positions = [305.0, 535.0, 740.0, 975.0]
        gems = [Vector2(220, 430), Vector2(425, 370), Vector2(625, 320), Vector2(825, 380), Vector2(1030, 517)]
        mage["x"] = 635.0
        mage["hp"] = 120.0
        night_enemies = [{"x": 270.0, "hp": 95.0, "dir": -1.0}, {"x": 825.0, "hp": 110.0, "dir": 1.0}]
    elif current_day == 3:
        platforms = [Rect2(175, 445, 130, 16), Rect2(390, 385, 140, 16), Rect2(610, 400, 120, 16), Rect2(790, 345, 140, 16)]
        trap_positions = [340.0, 735.0, 955.0]
        gems = [Vector2(230, 415), Vector2(455, 355), Vector2(675, 370), Vector2(850, 315), Vector2(1030, 516)]
        mage["x"] = 685.0
        mage["hp"] = 105.0
        night_enemies = [{"x": 315.0, "hp": 80.0, "dir": 1.0}, {"x": 800.0, "hp": 100.0, "dir": -1.0}]
    elif current_day == 2:
        platforms = [Rect2(165, 440, 150, 16), Rect2(360, 375, 130, 16), Rect2(575, 430, 145, 16), Rect2(770, 345, 145, 16)]
        trap_positions = [315.0, 645.0, 930.0]
        gems = [Vector2(230, 405), Vector2(415, 340), Vector2(650, 396), Vector2(845, 310), Vector2(1025, 519)]
        mage["x"] = 715.0
        night_enemies = [{"x": 250.0, "hp": 70.0, "dir": 1.0}, {"x": 845.0, "hp": 80.0, "dir": -1.0}]
    else:
        platforms = [Rect2(205, 473, 135, 16), Rect2(415, 413, 145, 16), Rect2(640, 462, 130, 16), Rect2(830, 396, 135, 16)]
        trap_positions = [375.0, 775.0]
    show_notice("Ночь %d: найди Камень Бездны!" % current_day)

func update_day(delta: float) -> void:
    day_elapsed += delta
    if phase == "day":
        time_left -= delta
    spawn_timer -= delta
    if spawn_timer <= 0.0:
        wave_count += 1
        spawn_timer = maxf(1.05, 3.5 - wave_count * 0.065)
        var kind := "raider"
        if current_day >= 3 and wave_count % 6 == 0:
            kind = "saboteur"
        elif wave_count % 7 == 0:
            kind = "runner"
        elif wave_count % 5 == 0:
            kind = "brute"
        var health := (27.0 if kind == "runner" else (100.0 if kind == "brute" else (55.0 if kind == "saboteur" else 46.0))) * (1.0 if current_day == 1 else (1.45 if current_day == 2 else (1.7 if current_day == 3 else 1.95)))
        var speed := 84.0 if kind == "runner" else (65.0 if kind == "saboteur" else (25.0 if kind == "brute" else 43.0))
        var damage := (6.0 if kind == "runner" else (19.0 if kind == "brute" else 9.0)) * (1.0 if current_day == 1 else 1.3)
        enemies.append({"x": W + 32.0, "hp": health, "max_hp": health, "speed": speed, "damage": damage, "hit_cd": 0.0, "kind": kind, "sabotaged": false})
    for tower in towers:
        tower["disabled"] = maxf(0.0, float(tower.get("disabled", 0.0)) - delta)
        tower["cooldown"] -= delta
        if tower["cooldown"] <= 0.0 and tower["disabled"] <= 0.0:
            var target_x := INF
            for enemy in enemies:
                if absf(enemy["x"] - tower["x"]) <= (260.0 if tower["type"] == "bone" else 375.0) and enemy["x"] < target_x:
                    target_x = enemy["x"]
            if target_x != INF:
                tower["cooldown"] = 0.9 if tower["type"] == "bone" else 1.8
                shots.append({"x": tower["x"], "target": target_x, "damage": 22.0 if tower["type"] == "bone" else 65.0, "type": tower["type"]})
    for shot in shots:
        var closest_index := -1
        var distance := INF
        for i in range(enemies.size()):
            var d: float = absf(enemies[i]["x"] - shot["target"])
            if d < distance:
                distance = d
                closest_index = i
        if closest_index >= 0:
            enemies[closest_index]["hp"] -= shot["damage"] * (1.35 if tower_power_level > 0 else 1.0)
    shots.clear()
    for i in range(enemies.size() - 1, -1, -1):
        var enemy := enemies[i]
        if enemy["hp"] <= 0.0:
            mana += 9
            souls += 1
            kills_today += 1
            if enemy["kind"] == "saboteur":
                saboteurs_defeated += 1
            enemies.remove_at(i)
            continue
        if enemy["kind"] == "saboteur" and not enemy["sabotaged"]:
            for tower in towers:
                if absf(enemy["x"] - tower["x"]) < 95.0:
                    tower["disabled"] = 4.5
                    enemy["sabotaged"] = true
                    show_notice("Диверсант отключил башню на 4,5 секунды!")
                    break
        if enemy["x"] > 191.0:
            enemy["x"] -= enemy["speed"] * delta
        else:
            enemy["hit_cd"] -= delta
            if enemy["hit_cd"] <= 0.0:
                wall_hp -= enemy["damage"] * (0.75 if wall_ward_level > 0 else 1.0)
                enemy["hit_cd"] = 1.3
    if wall_hp <= 0.0:
        phase = "lose"
    elif phase == "day" and time_left <= 0.0:
        begin_night()

func heal_player() -> void:
    if player_hp >= 100.0:
        show_notice("Здоровье уже полное")
    elif mana < 20:
        show_notice("Для исцеления требуется 20 маны")
    else:
        mana -= 20
        player_hp = minf(100.0, player_hp + 30.0)
        potions_used += 1
        show_notice("Тёмная магия восстановила 30 здоровья")

func shadow_dash() -> void:
    if dash_cooldown > 0.0:
        show_notice("Теневой рывок восстанавливается")
        return
    if mana < 15:
        show_notice("Теневой рывок требует 15 маны")
        return
    mana -= 15
    dash_cooldown = 2.5
    dash_trail = 0.25
    player.x = clampf(player.x + facing * 125.0, 16.0, W - 16.0)
    hurt_cooldown = maxf(hurt_cooldown, 0.35)
    show_notice("Теневой рывок!")

func update_night(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
    swing_timer = maxf(0.0, swing_timer - delta)
    dash_cooldown = maxf(0.0, dash_cooldown - delta)
    dash_trail = maxf(0.0, dash_trail - delta)
    trap_clock += delta
    var direction := Input.get_axis("ui_left", "ui_right")
    if Input.is_key_pressed(KEY_A):
        direction -= 1.0
    if Input.is_key_pressed(KEY_D):
        direction += 1.0
    vel.x = clampf(direction, -1.0, 1.0) * 235.0
    if absf(vel.x) > 1.0:
        facing = signf(vel.x)
    var jump_down := Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_SPACE) or Input.is_action_pressed("ui_accept")
    if jump_down and not jump_was_down and grounded:
        vel.y = -455.0
        grounded = false
    jump_was_down = jump_down
    vel.y += 1060.0 * delta
    var old_bottom := player.y + 22.0
    player.x = clampf(player.x + vel.x * delta, 16.0, W - 16.0)
    player.y += vel.y * delta
    grounded = false
    if player.y + 22.0 >= FLOOR:
        player.y = FLOOR - 22.0
        vel.y = 0.0
        grounded = true
    if vel.y >= 0.0:
        for p in platforms:
            if player.x + 13.0 > p.position.x and player.x - 13.0 < p.end.x and old_bottom <= p.position.y + 8.0 and player.y + 22.0 >= p.position.y:
                player.y = p.position.y - 22.0
                vel.y = 0.0
                grounded = true
    var chest_pos := Vector2(850, 314) if current_day == 2 else (Vector2(858, 358) if current_day == 5 else (Vector2(835, 378) if current_day == 4 else (Vector2(855, 314) if current_day == 3 else Vector2(899, 365))))
    if not chest_taken and player.distance_to(chest_pos) < 42.0:
        chest_taken = true
        mana += 35
        souls += 2
        show_notice("Тайник некроманта: +35 маны, +2 души")
    if current_day == 2 and not relic_taken and player.distance_to(Vector2(424, 342)) < 39.0:
        relic_taken = true
        mana += 20
        souls += 3
        show_notice("Реликвия усыпальницы: +20 маны, +3 души")
    var spike_phase := fmod(trap_clock, 3.1)
    if spike_phase >= 2.1 and player.y + 21.0 >= FLOOR - 13.0:
        for tx in trap_positions:
            if absf(player.x - tx) < 29.0:
                hurt(20.0)
    for i in range(gems.size() - 1, -1, -1):
        if player.distance_to(gems[i]) < 32.0:
            mana += 12
            gems.remove_at(i)
    for i in range(night_enemies.size() - 1, -1, -1):
        var e := night_enemies[i]
        e["x"] += e["dir"] * 38.0 * delta
        if e["x"] < 280.0 or e["x"] > 845.0:
            e["dir"] *= -1.0
        if e["hp"] > 0.0 and absf(player.x - e["x"]) < 30.0 and player.y > FLOOR - 55.0:
            hurt(17.0)
        if e["hp"] <= 0:
            mana += 10
            souls += 2
            night_enemies.remove_at(i)
    if mage["hp"] > 0.0:
        mage["cooldown"] -= delta
        if mage["cooldown"] <= 0.0 and absf(player.x - mage["x"]) < 520.0:
            mage["cooldown"] = 2.2
            var start := Vector2(mage["x"], FLOOR - 65.0)
            var aim := (player - start).normalized()
            mage_bolts.append({"pos": start, "velocity": aim * 195.0, "life": 3.0})
    for i in range(mage_bolts.size() - 1, -1, -1):
        var bolt := mage_bolts[i]
        bolt["pos"] += bolt["velocity"] * delta
        bolt["life"] -= delta
        if bolt["pos"].distance_to(player) < 23.0:
            hurt(14.0)
            mage_bolts.remove_at(i)
        elif bolt["life"] <= 0.0:
            mage_bolts.remove_at(i)
    if boss_hp > 0.0:
        boss_strike_timer -= delta
        if boss_strike_timer <= 0.0 and boss_windup <= 0.0:
            boss_windup = 0.75
            boss_strike_timer = 2.8
        if boss_windup > 0.0:
            boss_windup -= delta
            if boss_windup <= 0.0 and absf(player.x - boss_pos.x) < 87.0 and player.y > FLOOR - 100.0:
                hurt(24.0)
    if boss_hp <= 0.0 and not stone_taken and player.distance_to(Vector2(1010, 465)) < 43.0:
        stone_taken = true
        stones_collected += 1
        show_notice("Камень %d/5 получен! Вернись к порталу слева." % stones_collected)
    if stone_taken and player.x < 85.0:
        phase = "ritual"

func hurt(amount: float) -> void:
    if hurt_cooldown > 0.0:
        return
    hurt_cooldown = 1.2
    player_hp -= amount
    if player_hp <= 0.0:
        phase = "lose"

func attack() -> void:
    if attack_cooldown > 0.0:
        return
    attack_cooldown = 0.34
    swing_timer = 0.16
    var reach := 88.0
    for e in night_enemies:
        if (e["x"] - player.x) * facing >= -10.0 and (e["x"] - player.x) * facing < reach and absf(player.y - (FLOOR - 22.0)) < 75.0:
            e["hp"] -= 24.0
    if mage["hp"] > 0.0 and (mage["x"] - player.x) * facing >= -10.0 and (mage["x"] - player.x) * facing < reach and absf(player.y - (FLOOR - 60.0)) < 95.0:
        mage["hp"] -= 24.0
        if mage["hp"] <= 0.0:
            mana += 18
            souls += 2
            show_notice("Маг Света повержен!")
    if boss_hp > 0.0 and (boss_pos.x - player.x) * facing >= -10.0 and (boss_pos.x - player.x) * facing < reach and absf(player.y - boss_pos.y) < 85.0:
        boss_hp -= 18.0
        if boss_hp <= 0.0:
            mana += 25
            souls += 4
            show_notice("Хранитель повержен. Забери Камень Бездны!")

func label(t: String, x: float, y: float, size: int = 20, color: Color = Color.WHITE) -> void:
    draw_string(font, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func box(rect: Rect2, col: Color) -> void:
    draw_rect(rect, col)

func draw_dark_lord(pos: Vector2) -> void:
    # Procedural character silhouette: cloak, horned helm and glowing eyes.
    var cloak := PackedVector2Array([pos + Vector2(-15, 9), pos + Vector2(15, 9), pos + Vector2(24, 27), pos + Vector2(-23, 27)])
    draw_colored_polygon(cloak, Color("42305f"))
    box(Rect2(pos.x - 13, pos.y - 17, 26, 34), Color("7451a0") if hurt_cooldown <= 0.0 else Color("d87386"))
    draw_circle(pos + Vector2(0, -24), 15, Color("25213c"))
    draw_colored_polygon(PackedVector2Array([pos + Vector2(-14, -28), pos + Vector2(-23, -49), pos + Vector2(-5, -36)]), Color("5d5273"))
    draw_colored_polygon(PackedVector2Array([pos + Vector2(14, -28), pos + Vector2(23, -49), pos + Vector2(5, -36)]), Color("5d5273"))
    box(Rect2(pos.x - 10, pos.y - 27, 7, 4), Color("f2678b"))
    box(Rect2(pos.x + 3, pos.y - 27, 7, 4), Color("f2678b"))

func _draw() -> void:
    box(Rect2(0, 0, W, H), Color("10101e"))
    for i in range(11):
        draw_circle(Vector2(55 + i * 111, 85 + (i * 37) % 80), 2.0, Color("77779a"))
    if phase == "day" or phase == "night" or phase == "final_siege":
        # Layered silhouettes create depth without requiring external textures.
        for i in range(9):
            var sx := float(i * 148 - 50)
            draw_colored_polygon(PackedVector2Array([Vector2(sx, FLOOR), Vector2(sx + 72, 320 + (i % 3) * 40), Vector2(sx + 155, FLOOR)]), Color("191a2d"))
            box(Rect2(sx + 47, 375 + (i % 2) * 32, 22, FLOOR - 375), Color("222237"))
        for i in range(19):
            box(Rect2(i * 64, FLOOR - 8, 60, 8), Color("4a4154"))
    if phase == "title":
        draw_circle(Vector2(880, 170), 105, Color("5e244e"))
        label("ПОСЛЕДНИЙ РИТУАЛ", 225, 255, 52, Color("e3b3e9"))
        label("Тёмный Лорд • Осада • Камень Бездны", 315, 320, 23)
        label("ENTER — начать пролог", 432, 415, 26, Color("f5cf84"))
        label("Версия 1.4: пять дней, пять ночей, пять камней", 325, 474, 18, Color("aaaaaa"))
        return
    if phase == "win" or phase == "lose":
        label("РИТУАЛ ЗАВЕРШЁН" if phase == "win" else "КРЕПОСТЬ ПАЛА", 300, 275, 48, Color("a9e4bc") if phase == "win" else Color("ff7777"))
        label("Ты пробудил древнюю силу." if phase == "win" else "Тьма ещё может вернуться...", 350, 340, 26)
        label("ENTER — новая попытка", 414, 415, 24)
        return
    if phase == "ritual":
        draw_circle(Vector2(575, 340), 140, Color("382347"))
        draw_colored_polygon(PackedVector2Array([Vector2(575, 215), Vector2(640, 340), Vector2(575, 465), Vector2(510, 340)]), Color("a950d1"))
        label("АЛТАРЬ БЕЗДНЫ", 398, 145, 39, Color("e9b5fb"))
        label("Камней: %d / 5. %s" % [stones_collected, "ENTER — продолжить осаду" if stones_collected < 5 else "Для ритуала нужно 50 маны и 8 душ"], 230, 515, 23)
        label("Мана: %d  |  Души: %d" % [mana, souls], 435, 554, 24, Color("edc477"))
        if stones_collected < 5:
            label("1: усилить башни (45 маны) %s" % ["[КУПЛЕНО]" if tower_power_level > 0 else ""], 310, 415, 20)
            label("2: печать стен (4 души) %s" % ["[КУПЛЕНО]" if wall_ward_level > 0 else ""], 310, 445, 20)
        label("ENTER — продолжить / ритуал  |  C — 25 маны на 1 душ", 310, 600, 20)
    else:
        box(Rect2(0, FLOOR, W, H - FLOOR), Color("32313b"))
        for i in range(23):
            box(Rect2(i * 52, FLOOR + 12, 50, 5), Color("45414e"))
        if phase == "day" or phase == "final_siege":
            draw_circle(Vector2(970, 115), 55, Color("bf7a50"))
            box(Rect2(65, 315, 127, 236), Color("514358"))
            box(Rect2(85, 274, 86, 58), Color("514358"))
            for i in range(3):
                box(Rect2(70 + i * 44, 297, 25, 24), Color("514358"))
            box(Rect2(111, 430, 40, 120), Color("241c31"))
            for row in range(6):
                for col in range(3):
                    box(Rect2(72 + col * 38 + (row % 2) * 9, 339 + row * 33, 30, 4), Color("6a596e"))
            for j in range(3):
                box(Rect2(86 + j * 25, 357, 10, 28), Color("211c30"))
            draw_circle(Vector2(131, 412), 17, Color("aa5570", 0.6))
            label("КРЕПОСТЬ", 73, 252, 19)
            for tower in towers:
                var tx: float = tower["x"]
                box(Rect2(tx - 17, FLOOR - 74, 34, 74), Color("9a8a9e") if tower["type"] == "bone" else Color("a65542"))
                draw_circle(Vector2(tx, FLOOR - 82), 20, Color("8a8190") if float(tower.get("disabled", 0.0)) > 0.0 else (Color("8ad0d1") if tower["type"] == "bone" else Color("ff965d")))
            for e in enemies:
                var ex: float = e["x"]
                var enemy_color := Color("7adbe4") if e["kind"] == "saboteur" else (Color("edc265") if e["kind"] == "runner" else (Color("d66c69") if e["kind"] == "brute" else Color("b0af9b")))
                box(Rect2(ex - 13, FLOOR - 43, 26, 43), enemy_color)
                box(Rect2(ex - 17, FLOOR - 53, 34 * e["hp"] / e["max_hp"], 4), Color("f57c79"))
            var cursor_x := get_global_mouse_position().x
            if cursor_x >= 245.0 and cursor_x <= 1020.0:
                var range_radius := 260.0 if selected_build == "bone" else 375.0
                draw_arc(Vector2(cursor_x, FLOOR - 72), range_radius, PI, TAU, 28, Color("72aa9a", 0.28), 2.0)
                box(Rect2(cursor_x - 17.0, FLOOR - 74.0, 34, 74), Color("619d9c", 0.46) if selected_build == "bone" else Color("ba7954", 0.46))
            label("ФИНАЛЬНЫЙ ШТУРМ — %d с" % ceili(maxf(0.0, final_timer)) if phase == "final_siege" else "ДЕНЬ %d / 5  •  ОСАДА" % current_day, 25, 35, 27, Color("f8c59e"))
            label("До ночи: %02d c    Стены: %d / 100    Мана: %d    Души: %d" % [ceili(maxf(time_left, 0.0)), maxi(0, ceili(wall_hp)), mana, souls], 25, 71, 22)
            box(Rect2(25, 82, 260, 13), Color("553840"))
            box(Rect2(25, 82, 260.0 * clampf(wall_hp / MAX_WALL, 0.0, 1.0), 13), Color("8cbe88") if wall_hp > 30.0 else Color("ed6b73"))
            label("Убийств: %d  |  Врагов: %d  |  Выбрано: %s" % [kills_today, enemies.size(), "Костяная" if selected_build == "bone" else "Баллиста"], 25, 126, 18)
            label("1/2: выбор башни  |  ЛКМ: строить  |  R: ремонт стен (20)  |  P: пауза", 24, 625, 18)
        elif phase == "night":
            draw_circle(Vector2(940, 115), 53, Color("bbb6d6"))
            for p in platforms:
                box(p, Color("826479") if current_day == 2 else Color("6c5c77"))
            if current_day == 2:
                for pillar in range(5):
                    box(Rect2(100 + pillar * 220, 215, 29, 335), Color("3c344d"))
                    box(Rect2(91 + pillar * 220, 213, 47, 12), Color("554562"))
            var spike_phase := fmod(trap_clock, 3.1)
            for tx in trap_positions:
                var trap_color := Color("5c566a") if spike_phase < 1.4 else (Color("efa857") if spike_phase < 2.1 else Color("f05268"))
                box(Rect2(tx - 31.0, FLOOR - 8.0, 62, 8), trap_color)
                if spike_phase >= 2.1:
                    for spike in range(4):
                        draw_colored_polygon(PackedVector2Array([Vector2(tx - 28 + spike * 16, FLOOR), Vector2(tx - 20 + spike * 16, FLOOR - 24), Vector2(tx - 12 + spike * 16, FLOOR)]), trap_color)
            var chest_at := Vector2(850, 314) if current_day == 2 else (Vector2(858, 358) if current_day == 5 else (Vector2(835, 378) if current_day == 4 else (Vector2(855, 314) if current_day == 3 else Vector2(899, 365))))
            if not chest_taken:
                box(Rect2(chest_at.x - 23, chest_at.y - 20, 46, 26), Color("a67c47"))
                box(Rect2(chest_at.x - 23, chest_at.y - 23, 46, 6), Color("f1d085"))
                label("ТАЙНИК", chest_at.x - 35, chest_at.y - 32, 15, Color("f1d085"))
            if current_day == 2 and not relic_taken:
                draw_circle(Vector2(424, 342), 13, Color("d9a2e7"))
                label("РЕЛИКВИЯ", 383, 311, 16, Color("e7b4f3"))
            for gem in gems:
                draw_colored_polygon(PackedVector2Array([gem + Vector2(0, -16), gem + Vector2(13, 0), gem + Vector2(0, 16), gem + Vector2(-13, 0)]), Color("5de0e9"))
            for e in night_enemies:
                box(Rect2(e["x"] - 16, FLOOR - 34, 32, 34), Color("86aa87"))
            if mage["hp"] > 0.0:
                box(Rect2(mage["x"] - 14.0, FLOOR - 68.0, 28, 68), Color("5d9ac7"))
                draw_circle(Vector2(mage["x"], FLOOR - 73.0), 17.0, Color("a8d6ef"))
                box(Rect2(mage["x"] - 19.0, FLOOR - 90.0, 38.0 * mage["hp"] / 60.0, 4), Color("71b7ff"))
            for bolt in mage_bolts:
                draw_circle(bolt["pos"], 8.0, Color("7bd9ff"))
            if boss_hp > 0.0:
                if boss_windup > 0.0:
                    box(Rect2(boss_pos.x - 85, FLOOR - 10, 170, 10), Color("eb5c60"))
                    label("УДАР!", boss_pos.x - 30, 405, 20, Color("f4a2a2"))
                box(Rect2(boss_pos.x - 31, boss_pos.y - 47, 62, 91), Color("a24e71"))
                box(Rect2(boss_pos.x - 45, boss_pos.y - 65, 90 * boss_hp / (140.0 if current_day == 1 else (190.0 if current_day == 2 else (230.0 if current_day == 3 else (270.0 if current_day == 4 else 340.0)))), 7), Color("ed6975"))
                label("ХРАНИТЕЛЬ", 935, 380, 17)
            elif not stone_taken:
                var stone := Vector2(1010, 465)
                draw_colored_polygon(PackedVector2Array([stone + Vector2(0, -28), stone + Vector2(20, 0), stone + Vector2(0, 28), stone + Vector2(-20, 0)]), Color("d75bf3"))
            box(Rect2(35, 465, 49, 85), Color("784a93"))
            label("ПОРТАЛ", 24, 451, 16)
            if dash_trail > 0.0:
                box(Rect2(player.x - facing * 72.0 - 12.0, player.y - 21.0, 24.0, 43.0), Color("533b87"))
                box(Rect2(player.x - facing * 38.0 - 12.0, player.y - 21.0, 24.0, 43.0), Color("7951ab"))
            draw_dark_lord(player)
            if swing_timer > 0.0:
                box(Rect2(player.x + (17.0 if facing > 0 else -75.0), player.y - 17.0, 58.0, 10.0), Color("d6a2e9"))
            label("НОЧЬ %d / 5  •  %s" % [current_day, "КАТАКОМБЫ" if current_day == 1 else ("ПРОКЛЯТАЯ УСЫПАЛЬНИЦА" if current_day == 2 else ("СОБОР СВЕТА" if current_day == 3 else ("КРОВАВЫЕ ШАХТЫ" if current_day == 4 else "ГРОБНИЦА ПЕРВОГО КОРОЛЯ")))], 25, 35, 27, Color("b9afea"))
            label("Здоровье: %d    Мана: %d    Души: %d    Камень: %s" % [maxi(0, ceili(player_hp)), mana, souls, "ДА" if stone_taken else "НЕТ"], 25, 71, 22)
            label("Шипы: серые — безопасно; жёлтые — предупреждение; красные — урон", 25, 106, 17, Color("e6bb91"))
            label("A/D: ходьба | W / Space: прыжок | J: удар | H: лечение | Shift: рывок | P: пауза", 20, 625, 18)
    if notice_timer > 0.0:
        box(Rect2(190, 97, 775, 50), Color("39283d"))
        label(notice, 215, 131, 19, Color("f5dcaf"))
    if paused:
        box(Rect2(310, 220, 535, 170), Color("171425"))
        label("ПАУЗА", 469, 287, 45, Color("e3b3e9"))
        label("Нажми P, чтобы продолжить", 394, 345, 23)
