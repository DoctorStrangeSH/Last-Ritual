extends Node2D
## Last Ritual v2.0-rc42: gothic title and ritual UI, Godot 4.2+
const W := 1152.0
const H := 648.0
const FLOOR := 550.0
const DAY_LENGTH := 56.0
const MAX_WALL := 100.0
const SAVE_PATH := "user://campaign_v1.json"
const AUDIO_SETTINGS_PATH := "user://audio_settings.cfg"
var save_path := SAVE_PATH
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
var campaign_kills := 0
var towers_built := 0
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
var impacts: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var atmosphere_clock := 0.0
var audio_bank: Dictionary = {}
var audio_players: Array[AudioStreamPlayer] = []
var next_audio_channel := 0
var hit_sound_cooldown := 0.0
var ambient_player: AudioStreamPlayer
var ambient_phase := ""
var music_volume := 3
var effects_volume := 3

func _ready() -> void:
    font = ThemeDB.fallback_font
    setup_audio()
    load_audio_settings()
    apply_audio_volumes()
    reset_all()

func reset_all() -> void:
    phase = "title"
    paused = false
    kills_today = 0
    campaign_kills = 0
    towers_built = 0
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
    impacts.clear()
    particles.clear()
    atmosphere_clock = 0.0
    hit_sound_cooldown = 0.0
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
    atmosphere_clock += delta
    update_ambience()
    hit_sound_cooldown = maxf(0.0, hit_sound_cooldown - delta)
    if notice_timer > 0:
        notice_timer -= delta
    for i in range(particles.size() - 1, -1, -1):
        particles[i]["life"] = float(particles[i]["life"]) - delta
        particles[i]["pos"] = particles[i]["pos"] + particles[i]["vel"] * delta
        particles[i]["vel"] = particles[i]["vel"] + Vector2(0.0, 95.0) * delta
        if particles[i]["life"] <= 0.0:
            particles.remove_at(i)
    for i in range(impacts.size() - 1, -1, -1):
        impacts[i]["life"] = float(impacts[i]["life"]) - delta
        if impacts[i]["life"] <= 0.0:
            impacts.remove_at(i)
    if phase == "day":
        update_day(delta)
    elif phase == "night":
        update_night(delta)
    elif phase == "final_siege":
        final_timer = maxf(0.0, final_timer - delta)
        update_day(delta)
        if phase == "final_siege" and wall_hp > 0.0 and final_timer <= 0.0:
            phase = "win"
            play_cue("victory")
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_M:
            music_volume = (music_volume + 1) % 5
            apply_audio_volumes()
            save_audio_settings()
            show_notice("Атмосфера: %d/4" % music_volume)
            return
        if event.keycode == KEY_N:
            effects_volume = (effects_volume + 1) % 5
            apply_audio_volumes()
            save_audio_settings()
            show_notice("Эффекты: %d/4" % effects_volume)
            return
        if event.keycode == KEY_P and phase != "title" and phase != "win" and phase != "lose":
            paused = not paused
            queue_redraw()
            return
        if paused:
            return
        if phase == "title" and event.keycode == KEY_L:
            if not load_campaign():
                show_notice("Сохранение не найдено или повреждено")
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
                save_campaign()
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
        kills_today = 0
        repairs_today = 0
        enemies.clear()
        shots.clear()
        player_hp = 100.0
        show_notice("День %d: армия Света усилилась! Башни сохранены." % current_day)
    elif mana >= 50 and souls >= 8:
        mana -= 50
        souls -= 8
        phase = "final_siege"
        play_cue("ritual")
        final_timer = 45.0
        enemies.clear()
        shots.clear()
        spawn_timer = 0.3
        for tower in towers:
            tower["disabled"] = 0.0
            tower["cooldown"] = 0.0
        wall_hp = minf(MAX_WALL, wall_hp + 20.0)
        mana += 30
        show_notice("Последний штурм: +20 стен, +30 маны! Продержись 45 сек.")
    else:
        show_notice("Для ритуала нужно 50 маны и 8 душ. C — обмен.")

func save_campaign() -> bool:
    if phase != "ritual" or stones_collected < 1 or stones_collected > 5:
        return false
    var saved_towers: Array[Dictionary] = []
    for tower in towers:
        saved_towers.append({"x": float(tower["x"]), "type": str(tower["type"])})
    var data := {
        "version": 1, "day": current_day, "stones": stones_collected,
        "mana": mana, "souls": souls, "wall_hp": wall_hp,
        "tower_power": tower_power_level, "wall_ward": wall_ward_level,
        "towers": saved_towers,
        "campaign_kills": campaign_kills, "towers_built": maxi(towers_built, towers.size())
    }
    var temp_path := save_path + ".tmp"
    var file := FileAccess.open(temp_path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(data))
    file.flush()
    file.close()
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(save_path)) == OK

func load_campaign() -> bool:
    if not FileAccess.file_exists(save_path):
        return false
    var file := FileAccess.open(save_path, FileAccess.READ)
    if file == null:
        return false
    if file.get_length() > 65536:
        return false
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not parsed is Dictionary:
        return false
    var data: Dictionary = parsed
    for key in ["version", "day", "stones", "mana", "souls", "wall_hp", "tower_power", "wall_ward", "towers"]:
        if not data.has(key):
            return false
    if data["version"] != 1 or not data["day"] is float or not data["stones"] is float:
        return false
    var day := int(data["day"])
    var stones := int(data["stones"])
    if float(day) != data["day"] or float(stones) != data["stones"]:
        return false
    if day < 1 or day > 5 or stones != day:
        return false
    for key in ["mana", "souls", "wall_hp", "tower_power", "wall_ward"]:
        if not data[key] is float:
            return false
    if not is_finite(float(data["mana"])) or not is_finite(float(data["souls"])) or not is_finite(float(data["wall_hp"])):
        return false
    if data["mana"] != floorf(float(data["mana"])) or data["souls"] != floorf(float(data["souls"])):
        return false
    if data["mana"] < 0 or data["mana"] > 100000 or data["souls"] < 0 or data["souls"] > 100000 or data["wall_hp"] <= 0 or data["wall_hp"] > MAX_WALL:
        return false
    if not is_finite(float(data["tower_power"])) or not is_finite(float(data["wall_ward"])):
        return false
    if data["tower_power"] not in [0.0, 1.0] or data["wall_ward"] not in [0.0, 1.0]:
        return false
    if not data["towers"] is Array or data["towers"].size() > 12:
        return false
    var checked_towers: Array[Dictionary] = []
    for item in data["towers"]:
        if not item is Dictionary or not item.has("x") or not item.has("type"):
            return false
        if not item["x"] is float or not is_finite(float(item["x"])) or item["x"] < 245.0 or item["x"] > 1020.0:
            return false
        if item["type"] != "bone" and item["type"] != "fire":
            return false
        for placed in checked_towers:
            if absf(float(placed["x"]) - float(item["x"])) < 65.0:
                return false
        checked_towers.append({"x": float(item["x"]), "type": item["type"], "cooldown": 0.0})
    var loaded_kills := 0
    var loaded_builds := checked_towers.size()
    for stat_key in ["campaign_kills", "towers_built"]:
        if data.has(stat_key):
            var stat_value: Variant = data[stat_key]
            if not (stat_value is float or stat_value is int) or not is_finite(float(stat_value)):
                return false
            if stat_value < 0 or stat_value > 100000 or float(stat_value) != floorf(float(stat_value)):
                return false
    if data.has("campaign_kills"):
        loaded_kills = int(data["campaign_kills"])
    if data.has("towers_built"):
        loaded_builds = int(data["towers_built"])
    if loaded_builds < checked_towers.size():
        return false
    reset_all()
    campaign_kills = loaded_kills
    towers_built = loaded_builds
    current_day = day
    stones_collected = stones
    mana = int(data["mana"])
    souls = int(data["souls"])
    wall_hp = float(data["wall_hp"])
    tower_power_level = int(data["tower_power"])
    wall_ward_level = int(data["wall_ward"])
    towers = checked_towers
    phase = "ritual"
    stone_taken = true
    show_notice("Сохранение загружено: камней %d / 5" % stones_collected)
    return true

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
            save_campaign()
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
            save_campaign()

func show_notice(message: String) -> void:
    notice = message
    notice_timer = 2.7

func build_tower(kind: String, mx: float) -> void:
    var cost := 30 if kind == "bone" else 55
    if mx < 245 or mx > 1020:
        show_notice("Ставь башни между крепостью и врагом")
        return
    if mana < cost:
        show_notice("Не хватает %d маны для башни (нужно %d)" % [cost - mana, cost])
        return
    for tower in towers:
        if absf(tower["x"] - mx) < 65.0:
            show_notice("Слишком близко: оставь между башнями не меньше 65 шагов")
            return
    mana -= cost
    towers.append({"x": mx, "type": kind, "cooldown": 0.0})
    towers_built += 1
    show_notice("Построено: " + ("Костяная башня" if kind == "bone" else "Адская баллиста"))
    if current_day == 1 and towers.size() == 1:
        show_notice("Первая башня готова! R чинит стены за 20 маны; враги идут справа.")

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
    show_notice("Ночь %d: победи хранителя, забери камень и вернись к порталу слева!" % current_day)

func update_day(delta: float) -> void:
    day_elapsed += delta
    if phase == "day":
        time_left -= delta
    spawn_timer -= delta
    if spawn_timer <= 0.0:
        wave_count += 1
        spawn_timer = maxf(1.05, 3.5 - wave_count * 0.065)
        if phase == "final_siege":
            spawn_timer = maxf(0.85, 1.75 - wave_count * 0.02)
        var kind := "raider"
        if current_day >= 3 and wave_count % 6 == 0:
            kind = "saboteur"
        elif wave_count % 7 == 0:
            kind = "runner"
        elif wave_count % 5 == 0:
            kind = "brute"
        var health := (27.0 if kind == "runner" else (100.0 if kind == "brute" else (55.0 if kind == "saboteur" else 46.0))) * (1.0 if current_day == 1 else (1.45 if current_day == 2 else (1.7 if current_day == 3 else (1.95 if current_day == 4 else 2.1))))
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
            emit_impact(Vector2(float(enemies[closest_index]["x"]), FLOOR - 32.0), Color("ffb36b") if shot["type"] == "fire" else Color("8de1e7"), 25.0)
            if hit_sound_cooldown <= 0.0:
                play_cue("hit")
                hit_sound_cooldown = 0.13
    shots.clear()
    for i in range(enemies.size() - 1, -1, -1):
        var enemy := enemies[i]
        if enemy["hp"] <= 0.0:
            mana += 9
            souls += 1
            kills_today += 1
            campaign_kills += 1
            if enemy["kind"] == "saboteur":
                saboteurs_defeated += 1
            burst_particles(Vector2(float(enemy["x"]), FLOOR - 30.0), Color("a2d5e0") if enemy["kind"] == "saboteur" else Color("d9a1a8"), 9)
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
        wall_hp = 0.0
        phase = "lose"
        play_cue("defeat")
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
        play_cue("magic")
        show_notice("Тёмная магия восстановила 30 здоровья (+30 HP, -20 маны)")

func shadow_dash() -> void:
    if dash_cooldown > 0.0:
        show_notice("Рывок ещё недоступен: осталось %.1f с" % dash_cooldown)
        return
    if mana < 15:
        show_notice("Для рывка нужно 15 маны (не хватает %d)" % (15 - mana))
        return
    mana -= 15
    dash_cooldown = 2.5
    dash_trail = 0.25
    player.x = clampf(player.x + facing * 125.0, 16.0, W - 16.0)
    hurt_cooldown = maxf(hurt_cooldown, 0.35)
    play_cue("magic")
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
            burst_particles(Vector2(float(e["x"]), FLOOR - 24.0), Color("a6c8a2"), 10)
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
            emit_impact(player, Color("8acfff"), 21.0)
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
    if phase == "night" and stone_taken and player_hp > 0.0 and player.x < 85.0:
        phase = "ritual"
        if not save_campaign():
            show_notice("Не удалось записать сохранение")

func hurt(amount: float) -> void:
    if hurt_cooldown > 0.0:
        return
    hurt_cooldown = 1.2
    player_hp -= amount
    play_cue("damage")
    if player_hp <= 0.0:
        player_hp = 0.0
        phase = "lose"

func attack() -> void:
    if attack_cooldown > 0.0:
        return
    attack_cooldown = 0.34
    swing_timer = 0.16
    play_cue("hit")
    var reach := 88.0
    for e in night_enemies:
        if (e["x"] - player.x) * facing >= -10.0 and (e["x"] - player.x) * facing < reach and absf(player.y - (FLOOR - 22.0)) < 75.0:
            e["hp"] -= 24.0
            emit_impact(Vector2(float(e["x"]), FLOOR - 25.0), Color("d7b0fa"), 19.0)
    if mage["hp"] > 0.0 and (mage["x"] - player.x) * facing >= -10.0 and (mage["x"] - player.x) * facing < reach and absf(player.y - (FLOOR - 60.0)) < 95.0:
        mage["hp"] -= 24.0
        emit_impact(Vector2(float(mage["x"]), FLOOR - 55.0), Color("d7b0fa"), 22.0)
        if mage["hp"] <= 0.0:
            mana += 18
            souls += 2
            burst_particles(Vector2(float(mage["x"]), FLOOR - 54.0), Color("8acfff"), 17)
            show_notice("Маг Света повержен!")
    if boss_hp > 0.0 and (boss_pos.x - player.x) * facing >= -10.0 and (boss_pos.x - player.x) * facing < reach and absf(player.y - boss_pos.y) < 85.0:
        boss_hp -= 18.0
        emit_impact(boss_pos, Color("f67ba2"), 28.0)
        if boss_hp <= 0.0:
            mana += 25
            souls += 4
            burst_particles(boss_pos, Color("f67ba2"), 24)
            show_notice("Хранитель повержен. Забери Камень Бездны!")

func setup_audio() -> void:
    # Small mono PCM waveforms generated once at startup; no external assets.
    for name in ["hit", "damage", "magic", "ritual", "victory", "defeat"]:
        var length: float = 0.15 if name == "hit" else (0.24 if name == "damage" else (0.40 if name == "magic" else 0.85))
        var freq: float = 155.0 if name == "hit" else (110.0 if name == "damage" else (430.0 if name == "magic" else (290.0 if name == "ritual" else (520.0 if name == "victory" else 120.0))))
        var sample_rate := 22050
        var sample_count := int(length * float(sample_rate))
        var bytes := PackedByteArray()
        bytes.resize(sample_count * 2)
        for sample in range(sample_count):
            var t: float = float(sample) / float(sample_rate)
            var envelope: float = pow(1.0 - float(sample) / float(sample_count), 1.8)
            var sweep: float = freq * (1.0 + t * (0.8 if name == "magic" or name == "victory" else -0.65))
            var wave: float = sin(TAU * sweep * t) * 0.75 + sin(TAU * sweep * 1.5 * t) * 0.25
            bytes.encode_s16(sample * 2, int(clampf(wave * envelope * 8500.0, -32767.0, 32767.0)))
        var stream := AudioStreamWAV.new()
        stream.format = AudioStreamWAV.FORMAT_16_BITS
        stream.mix_rate = sample_rate
        stream.stereo = false
        stream.data = bytes
        audio_bank[name] = stream
    for mood in ["title", "day", "night", "ritual", "final_siege"]:
        var fundamental: float = 58.0 if mood == "title" else (74.0 if mood == "day" else (49.0 if mood == "night" else (92.0 if mood == "ritual" else 108.0)))
        var rate := 22050
        var duration := 4.0
        var count := int(duration * float(rate))
        var pcm := PackedByteArray()
        pcm.resize(count * 2)
        for index in range(count):
            var t: float = float(index) / float(rate)
            var fade: float = minf(1.0, minf(t, duration - t) * 3.0)
            var tremolo: float = 0.72 + 0.28 * sin(TAU * 0.5 * t)
            var sample_value: float = (sin(TAU * fundamental * t) * 0.65 + sin(TAU * fundamental * 1.5 * t) * 0.25 + sin(TAU * fundamental * 0.5 * t) * 0.10) * tremolo * fade
            pcm.encode_s16(index * 2, int(clampf(sample_value * 3200.0, -32767.0, 32767.0)))
        var ambient_stream := AudioStreamWAV.new()
        ambient_stream.format = AudioStreamWAV.FORMAT_16_BITS
        ambient_stream.mix_rate = rate
        ambient_stream.stereo = false
        ambient_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
        ambient_stream.loop_begin = 0
        ambient_stream.loop_end = count
        ambient_stream.data = pcm
        audio_bank["ambient_" + mood] = ambient_stream
    ambient_player = AudioStreamPlayer.new()
    ambient_player.volume_db = -23.0
    add_child(ambient_player)
    for channel in range(4):
        var audio_player := AudioStreamPlayer.new()
        audio_player.volume_db = -9.0
        add_child(audio_player)
        audio_players.append(audio_player)

func apply_audio_volumes() -> void:
    if ambient_player != null:
        ambient_player.volume_db = -80.0 if music_volume == 0 else (-31.0 + float(music_volume) * 2.0)
    for audio_player in audio_players:
        audio_player.volume_db = -80.0 if effects_volume == 0 else (-21.0 + float(effects_volume) * 4.0)

func save_audio_settings() -> void:
    var config := ConfigFile.new()
    config.set_value("audio", "ambient", music_volume)
    config.set_value("audio", "effects", effects_volume)
    config.save(AUDIO_SETTINGS_PATH)

func load_audio_settings() -> void:
    var config := ConfigFile.new()
    if config.load(AUDIO_SETTINGS_PATH) != OK:
        return
    var ambient_value: Variant = config.get_value("audio", "ambient", 3)
    var effects_value: Variant = config.get_value("audio", "effects", 3)
    if ambient_value is int and ambient_value >= 0 and ambient_value <= 4:
        music_volume = ambient_value
    if effects_value is int and effects_value >= 0 and effects_value <= 4:
        effects_volume = effects_value

func update_ambience() -> void:
    if ambient_player == null:
        return
    var mood := phase
    if mood == "win" or mood == "lose":
        mood = ""
    if mood == ambient_phase:
        return
    ambient_phase = mood
    ambient_player.stop()
    if audio_bank.has("ambient_" + mood):
        ambient_player.stream = audio_bank["ambient_" + mood]
        ambient_player.play()

func play_cue(name: String) -> void:
    if not audio_bank.has(name) or audio_players.is_empty():
        return
    var player_audio := audio_players[next_audio_channel]
    next_audio_channel = (next_audio_channel + 1) % audio_players.size()
    player_audio.stream = audio_bank[name]
    player_audio.play()

func burst_particles(origin: Vector2, tint: Color, count: int) -> void:
    for i in range(count):
        if particles.size() >= 96:
            particles.pop_front()
        var angle := TAU * float(i) / float(count)
        var speed := 65.0 + float(i % 4) * 22.0
        particles.append({"pos": origin, "vel": Vector2(cos(angle), sin(angle)) * speed, "color": tint, "life": 0.55, "radius": 3.0 + float(i % 3)})

func emit_impact(pos: Vector2, color: Color, radius: float) -> void:
    if impacts.size() >= 36:
        impacts.pop_front()
    impacts.append({"pos": pos, "color": color, "radius": radius, "life": 0.23})

func draw_gothic_hud_panel(height: float) -> void:
    # Semi-transparent HUD keeps detailed scenery visible while improving legibility.
    box(Rect2(12.0, 9.0, W - 24.0, height), Color(0.075, 0.065, 0.12, 0.82))
    box(Rect2(12.0, 9.0, W - 24.0, 3.0), Color("a97d9d"))
    box(Rect2(12.0, 9.0 + height - 3.0, W - 24.0, 3.0), Color("66516d"))
    for corner in [22.0, W - 32.0]:
        draw_colored_polygon(PackedVector2Array([Vector2(corner, 14.0), Vector2(corner + 10.0, 24.0), Vector2(corner, 34.0), Vector2(corner - 10.0, 24.0)]), Color("ae8cae"))

func label(t: String, x: float, y: float, size: int = 20, color: Color = Color.WHITE) -> void:
    draw_string(font, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func box(rect: Rect2, col: Color) -> void:
    draw_rect(rect, col)

func draw_dark_lord(pos: Vector2) -> void:
    # Imported SVG artwork replaces the original geometric placeholder.
    # The sword effect remains drawn by the night phase.
    draw_texture_rect(preload("res://assets/characters/dark_lord.svg"), Rect2(pos.x - 31.0, pos.y - 57.0, 62.0, 83.0), false)

func _draw() -> void:
    box(Rect2(0, 0, W, H), Color("10101e"))
    if phase == "day" or phase == "final_siege":
        draw_texture_rect(preload("res://assets/backgrounds/siege_dusk.svg"), Rect2(0, 0, W, H), false)
    if phase == "night" and current_day == 1:
        draw_texture_rect(preload("res://assets/backgrounds/catacombs.svg"), Rect2(0, 0, W, H), false)
    elif phase == "night" and current_day == 3:
        draw_texture_rect(preload("res://assets/backgrounds/light_cathedral.svg"), Rect2(0, 0, W, H), false)
    elif phase == "night" and current_day == 2:
        draw_texture_rect(preload("res://assets/backgrounds/cursed_crypt.svg"), Rect2(0, 0, W, H), false)
    elif phase == "night" and current_day == 4:
        draw_texture_rect(preload("res://assets/backgrounds/blood_mines.svg"), Rect2(0, 0, W, H), false)
    elif phase == "night" and current_day == 5:
        draw_texture_rect(preload("res://assets/backgrounds/first_kings_tomb.svg"), Rect2(0, 0, W, H), false)
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
    if phase == "day" or phase == "night" or phase == "final_siege":
        # Semi-transparent drifting bands stay behind actors and HUD.
        for fog in range(6):
            var drift := fmod(float(fog * 233) + atmosphere_clock * (9.0 + float(fog % 3) * 4.0), W + 300.0) - 150.0
            draw_circle(Vector2(drift, FLOOR - 42.0 - float(fog % 2) * 28.0), 92.0 + float(fog % 3) * 18.0, Color(0.55, 0.48, 0.68, 0.055))
    if phase == "title":
        var title_pulse: float = 0.5 + 0.5 * sin(atmosphere_clock * 1.7)
        draw_circle(Vector2(885, 155), 104.0 + title_pulse * 8.0, Color(0.48, 0.19, 0.46, 0.19))
        draw_circle(Vector2(885, 155), 82.0, Color("5e244e"))
        for tower_shape in range(5):
            var tx: float = 190.0 + float(tower_shape) * 185.0
            var th: float = 160.0 + float(tower_shape % 3) * 48.0
            box(Rect2(tx, FLOOR - th, 80, th), Color("272039"))
            for tooth in range(3):
                box(Rect2(tx + float(tooth) * 26.0, FLOOR - th - 18.0, 19, 22), Color("272039"))
            box(Rect2(tx + 30.0, FLOOR - th + 46.0, 16, 33), Color("65405e"))
        box(Rect2(0, FLOOR, W, H - FLOOR), Color("242030"))
        for mist in range(7):
            var mx: float = fmod(float(mist * 202) + atmosphere_clock * 13.0, W + 250.0) - 125.0
            draw_circle(Vector2(mx, FLOOR - 24.0), 82.0, Color(0.62, 0.49, 0.76, 0.08))
        for spark in range(14):
            var sx: float = fmod(float(spark * 83) + atmosphere_clock * (5.0 + float(spark % 4)), W)
            var sy: float = 145.0 + float((spark * 47) % 310) + sin(atmosphere_clock * 1.2 + float(spark)) * 9.0
            draw_circle(Vector2(sx, sy), 2.0, Color(0.86, 0.59, 0.96, 0.3 + 0.2 * title_pulse))
        # Dark ornamental title card preserves readability over animated silhouettes.
        box(Rect2(164, 183, 824, 344), Color(0.09, 0.065, 0.14, 0.78))
        draw_rect(Rect2(164, 183, 824, 344), Color("96739c"), false, 3.0)
        draw_line(Vector2(194, 198), Vector2(958, 198), Color("d2a1b4"), 2.0)
        draw_line(Vector2(194, 511), Vector2(958, 511), Color("866487"), 2.0)
        for ornament in [192.0, 960.0]:
            draw_colored_polygon(PackedVector2Array([Vector2(ornament, 208), Vector2(ornament + 10, 221), Vector2(ornament, 234), Vector2(ornament - 10, 221)]), Color("bb86b4"))
        label("ПОСЛЕДНИЙ РИТУАЛ", 225, 255, 52, Color(0.78 + 0.12 * title_pulse, 0.56 + 0.15 * title_pulse, 0.86 + 0.10 * title_pulse))
        label("Тёмный Лорд • Осада • Камень Бездны", 315, 320, 23)
        label("ENTER — начать новую игру | L — загрузить сохранение", 290, 415, 24, Color("f5cf84"))
        label("M — атмосфера: %d/4  |  N — эффекты: %d/4" % [music_volume, effects_volume], 375, 463, 19, Color("d5bfda"))
        label("Версия 2.0 RC42: пять дней, пять ночей, пять камней", 325, 501, 18, Color("aaaaaa"))
        return
    if phase == "win" or phase == "lose":
        if phase == "win":
            var victory_pulse: float = 0.5 + 0.5 * sin(atmosphere_clock * 2.5)
            draw_circle(Vector2(576, 290), 165.0 + victory_pulse * 13.0, Color(0.58, 0.25, 0.87, 0.10 + victory_pulse * 0.08))
            draw_arc(Vector2(576, 290), 136.0, 0.0, TAU, 64, Color("c29ae9"), 4.0)
            for rune in range(10):
                var angle: float = atmosphere_clock * 0.33 + TAU * float(rune) / 10.0
                var point := Vector2(576 + cos(angle) * 138.0, 290 + sin(angle) * 138.0)
                draw_circle(point, 5.0, Color("ddc0ff"))
            label("РИТУАЛ ЗАВЕРШЁН", 286, 270, 48, Color("e3b3e9"))
            label("Древняя сила пробудилась. Крепость выстояла.", 285, 337, 24, Color("e9d8f0"))
        else:
            box(Rect2(0, FLOOR, W, H - FLOOR), Color("332633"))
            for ruin in range(5):
                var rx: float = 215.0 + float(ruin) * 170.0
                var height: float = 65.0 + float(ruin % 3) * 28.0
                draw_colored_polygon(PackedVector2Array([Vector2(rx - 36, FLOOR), Vector2(rx - 25, FLOOR - height), Vector2(rx - 10, FLOOR - height + 22), Vector2(rx + 8, FLOOR - height + 5), Vector2(rx + 34, FLOOR)]), Color("584353"))
                draw_line(Vector2(rx - 35, FLOOR - height), Vector2(rx + 20, FLOOR - 20), Color("a26165"), 3.0)
            for ash in range(12):
                var ash_x: float = fmod(float(ash * 109) + atmosphere_clock * 12.0, W)
                var ash_y: float = 165.0 + float((ash * 53) % 320) + sin(atmosphere_clock + float(ash)) * 10.0
                draw_circle(Vector2(ash_x, ash_y), 2.5, Color(0.9, 0.48, 0.48, 0.35))
            label("КРЕПОСТЬ ПАЛА", 325, 270, 48, Color("ff7777"))
            label("Огонь ритуала угас. Но тьма ещё вернётся.", 293, 337, 24, Color("e1b8bf"))
        box(Rect2(255, 365, 642, 103), Color(0.12, 0.09, 0.18, 0.86))
        label("ИТОГИ ПОХОДА", 451, 391, 22, Color("f5cf84"))
        label("Врагов: %d   |   Построено башен: %d   |   Камней: %d/5" % [campaign_kills, towers_built, stones_collected], 294, 427, 20)
        label("ENTER — новая попытка", 414, 509, 24, Color("f5cf84"))
        return
    if phase == "ritual":
        var altar_glow := 0.58 + 0.42 * sin(atmosphere_clock * 2.2)
        draw_circle(Vector2(575, 340), 161.0 + altar_glow * 11.0, Color(0.65, 0.24, 0.86, 0.07 + altar_glow * 0.07))
        draw_circle(Vector2(575, 340), 140, Color("382347"))
        draw_colored_polygon(PackedVector2Array([Vector2(575, 215), Vector2(640, 340), Vector2(575, 465), Vector2(510, 340)]), Color("a950d1"))
        # Altar UI frame and upgrade slate are drawn behind controls.
        box(Rect2(182, 90, 790, 78), Color(0.13, 0.075, 0.20, 0.91))
        draw_rect(Rect2(182, 90, 790, 78), Color("9660aa"), false, 3.0)
        box(Rect2(278, 387, 616, 77), Color(0.11, 0.08, 0.17, 0.90))
        draw_rect(Rect2(278, 387, 616, 77), Color("80628f"), false, 2.0)
        box(Rect2(200, 479, 755, 105), Color(0.11, 0.08, 0.17, 0.89))
        draw_rect(Rect2(200, 479, 755, 105), Color("80628f"), false, 2.0)
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
            draw_circle(Vector2(970, 115), 64.0, Color(1.0, 0.49, 0.28, 0.10))
            draw_circle(Vector2(970, 115), 55, Color("bf7a50"))
            # Ruined battleground: distant tombstones, broken statues and siege debris.
            for grave in range(7):
                var gx: float = 265.0 + float(grave) * 124.0
                var gh: float = 28.0 + float(grave % 3) * 10.0
                box(Rect2(gx - 13.0, FLOOR - gh, 26.0, gh), Color("484153"))
                draw_arc(Vector2(gx, FLOOR - gh), 13.0, PI, TAU, 16, Color("797084"), 3.0)
                draw_line(Vector2(gx, FLOOR - gh + 7.0), Vector2(gx, FLOOR - 8.0), Color("645b71"), 2.0)
            for statue in range(3):
                var sx_ruin: float = 340.0 + float(statue) * 275.0
                box(Rect2(sx_ruin - 20.0, FLOOR - 27.0, 40.0, 27.0), Color("585064"))
                box(Rect2(sx_ruin - 11.0, FLOOR - 88.0, 22.0, 61.0), Color("665d70"))
                draw_colored_polygon(PackedVector2Array([Vector2(sx_ruin - 16.0, FLOOR - 88.0), Vector2(sx_ruin + 7.0, FLOOR - 117.0), Vector2(sx_ruin + 11.0, FLOOR - 88.0)]), Color("73697d"))
                draw_line(Vector2(sx_ruin - 9.0, FLOOR - 67.0), Vector2(sx_ruin + 11.0, FLOOR - 37.0), Color("3c344a"), 3.0)
            for debris in range(10):
                var dx: float = 240.0 + float(debris) * 91.0
                draw_colored_polygon(PackedVector2Array([Vector2(dx - 15.0, FLOOR), Vector2(dx, FLOOR - 10.0 - float(debris % 3) * 5.0), Vector2(dx + 22.0, FLOOR)]), Color("5c5062"))
            draw_texture_rect(preload("res://assets/buildings/dark_fortress.svg"), Rect2(45, 258, 177, 293), false)
            label("КРЕПОСТЬ", 73, 252, 19)
            if phase == "final_siege":
                var progress: float = clampf(1.0 - final_timer / 45.0, 0.0, 1.0)
                var core := Vector2(540.0, FLOOR - 18.0)
                draw_circle(core, 85.0, Color(0.65, 0.28, 0.88, 0.08 + progress * 0.18))
                draw_arc(core, 72.0, 0.0, TAU, 60, Color(0.88, 0.59, 1.0, 0.45 + progress * 0.45), 4.0)
                draw_arc(core, 47.0, 0.0, TAU, 48, Color(0.69, 0.4, 0.95, 0.65), 3.0)
                for glyph in range(8):
                    var theta: float = atmosphere_clock * 0.7 + TAU * float(glyph) / 8.0
                    var glyph_pos := core + Vector2(cos(theta) * 68.0, sin(theta) * 26.0)
                    draw_circle(glyph_pos, 5.0, Color(0.9, 0.71, 1.0, 0.6 + progress * 0.4))
                for ray in range(5):
                    var ray_x: float = core.x - 36.0 + float(ray) * 18.0
                    var ray_height: float = 12.0 + progress * 95.0
                    draw_line(Vector2(ray_x, core.y - 20.0), Vector2(ray_x, core.y - ray_height), Color(0.82, 0.47, 1.0, 0.14 + progress * 0.38), 3.0)
            # Cloth banners move gently; purely decorative, no physics or RNG.
            for banner in range(2):
                var bx := 83.0 + float(banner) * 88.0
                var sway := sin(atmosphere_clock * 2.4 + float(banner) * 1.9) * 7.0
                draw_line(Vector2(bx, 265), Vector2(bx, 349), Color("b7a4a0"), 2.0)
                draw_colored_polygon(PackedVector2Array([Vector2(bx + 2, 278), Vector2(bx + 29 + sway * 0.35, 288), Vector2(bx + 23 + sway, 342), Vector2(bx + 12, 333), Vector2(bx + 2, 342)]), Color("7b3154"))
                draw_circle(Vector2(bx + 13 + sway * 0.3, 303), 5.0, Color("e7b580"))
            # Warm torch pools and animated flames along the fortress wall.
            for torch in range(2):
                var fx := 92.0 + float(torch) * 79.0
                var flicker := sin(atmosphere_clock * 10.0 + float(torch) * 2.3)
                draw_circle(Vector2(fx, 396), 24.0 + flicker * 3.0, Color(1.0, 0.48, 0.16, 0.10))
                box(Rect2(fx - 3.0, 400, 6, 23), Color("604239"))
                draw_colored_polygon(PackedVector2Array([Vector2(fx - 7.0, 399), Vector2(fx + flicker * 3.0, 377.0 - flicker * 3.0), Vector2(fx + 7.0, 399)]), Color("f6a24c"))
                draw_circle(Vector2(fx, 394), 4.0, Color("ffe0a0"))
            for tower in towers:
                var tx: float = tower["x"]
                var tower_art: Texture2D = preload("res://assets/towers/bone_tower.svg") if tower["type"] == "bone" else preload("res://assets/towers/infernal_ballista.svg")
                draw_texture_rect(tower_art, Rect2(tx - 30.0, FLOOR - 106.0, 60.0, 106.0), false)
                if float(tower.get("disabled", 0.0)) > 0.0:
                    draw_line(Vector2(tx - 12, FLOOR - 96), Vector2(tx + 12, FLOOR - 72), Color("e1bac3"), 3.0)
            for e in enemies:
                var ex: float = e["x"]
                var enemy_color := Color("7adbe4") if e["kind"] == "saboteur" else (Color("edc265") if e["kind"] == "runner" else (Color("d66c69") if e["kind"] == "brute" else Color("b0af9b")))
                if e["kind"] == "raider":
                    draw_texture_rect(preload("res://assets/enemies/raider.svg"), Rect2(ex - 21.0, FLOOR - 62.0, 42.0, 62.0), false)
                    box(Rect2(ex - 17, FLOOR - 67, 34.0 * clampf(float(e["hp"]) / float(e["max_hp"]), 0.0, 1.0), 4), Color("f57c79"))
                    continue
                if e["kind"] == "saboteur":
                    draw_texture_rect(preload("res://assets/enemies/saboteur.svg"), Rect2(ex - 21.0, FLOOR - 62.0, 42.0, 62.0), false)
                    box(Rect2(ex - 17, FLOOR - 67, 34.0 * clampf(float(e["hp"]) / float(e["max_hp"]), 0.0, 1.0), 4), Color("f57c79"))
                    continue
                if e["kind"] == "runner" or e["kind"] == "brute":
                    var sprite_path := preload("res://assets/enemies/runner.svg") if e["kind"] == "runner" else preload("res://assets/enemies/brute.svg")
                    var sprite_size := Vector2(41.0, 57.0) if e["kind"] == "runner" else Vector2(62.0, 77.0)
                    draw_texture_rect(sprite_path, Rect2(ex - sprite_size.x * 0.5, FLOOR - sprite_size.y, sprite_size.x, sprite_size.y), false)
                    box(Rect2(ex - 17.0, FLOOR - sprite_size.y - 7.0, 34.0 * clampf(float(e["hp"]) / float(e["max_hp"]), 0.0, 1.0), 4.0), Color("f57c79"))
                    continue
                var march: float = sin(atmosphere_clock * (11.0 if e["kind"] == "runner" else 6.0) + ex * 0.05) * 3.0
                var width: float = 19.0 if e["kind"] == "brute" else (10.0 if e["kind"] == "runner" else 13.0)
                var height: float = 56.0 if e["kind"] == "brute" else (37.0 if e["kind"] == "runner" else 43.0)
                box(Rect2(ex - width, FLOOR - height + march, width * 2.0, height - march), enemy_color)
                draw_circle(Vector2(ex, FLOOR - height - 8.0 + march), 13.0 if e["kind"] == "brute" else 9.0, Color("443d4b"))
                if e["kind"] == "saboteur":
                    draw_line(Vector2(ex - 14, FLOOR - 32), Vector2(ex + 15, FLOOR - 18), Color("214f60"), 4.0)
                    draw_circle(Vector2(ex + 12, FLOOR - 30), 6.0, Color("89f3ef"))
                elif e["kind"] == "runner":
                    draw_colored_polygon(PackedVector2Array([Vector2(ex - 10, FLOOR - height), Vector2(ex + 1, FLOOR - height - 24), Vector2(ex + 14, FLOOR - height)]), Color("d9aa5e"))
                    draw_line(Vector2(ex + 8, FLOOR - 20), Vector2(ex + 29, FLOOR - 43), Color("fae2ad"), 3.0)
                elif e["kind"] == "brute":
                    box(Rect2(ex - 26, FLOOR - height + 5, 52, 14), Color("8b424e"))
                    draw_line(Vector2(ex + 20, FLOOR - 41), Vector2(ex + 34, FLOOR - 18), Color("4a3940"), 7.0)
                else:
                    box(Rect2(ex - 14, FLOOR - height + 8, 28, 7), Color("766f78"))
                    draw_line(Vector2(ex + 12, FLOOR - 34), Vector2(ex + 26, FLOOR - 14), Color("b9bbc0"), 3.0)
                draw_circle(Vector2(ex - 4, FLOOR - height - 9 + march), 2.0, Color("ffc2a3"))
                draw_circle(Vector2(ex + 4, FLOOR - height - 9 + march), 2.0, Color("ffc2a3"))
                box(Rect2(ex - 17, FLOOR - 53, 34 * e["hp"] / e["max_hp"], 4), Color("f57c79"))
            var cursor_x := get_global_mouse_position().x
            if cursor_x >= 245.0 and cursor_x <= 1020.0:
                var range_radius := 260.0 if selected_build == "bone" else 375.0
                draw_arc(Vector2(cursor_x, FLOOR - 72), range_radius, PI, TAU, 28, Color("72aa9a", 0.28), 2.0)
                box(Rect2(cursor_x - 17.0, FLOOR - 74.0, 34, 74), Color("619d9c", 0.46) if selected_build == "bone" else Color("ba7954", 0.46))
            draw_gothic_hud_panel(150.0)
            label("ФИНАЛЬНЫЙ ШТУРМ — %d с" % ceili(maxf(0.0, final_timer)) if phase == "final_siege" else "ДЕНЬ %d / 5  •  ОСАДА" % current_day, 25, 35, 27, Color("f8c59e"))
            var siege_status := "Ритуал: %02d с" % ceili(maxf(final_timer, 0.0)) if phase == "final_siege" else "До ночи: %02d с" % ceili(maxf(time_left, 0.0))
            label("%s    Стены: %d / 100    Мана: %d    Души: %d" % [siege_status, maxi(0, ceili(wall_hp)), mana, souls], 25, 71, 22)
            if phase == "final_siege":
                box(Rect2(680, 84, 310, 13), Color("543c54"))
                box(Rect2(680, 84, 310.0 * clampf(1.0 - final_timer / 45.0, 0.0, 1.0), 13), Color("d8a6e8"))
                label("ЗАЩИЩАЙ АЛТАРЬ!", 700, 125, 18, Color("edc2f7"))
            box(Rect2(25, 82, 260, 13), Color("553840"))
            box(Rect2(25, 82, 260.0 * clampf(wall_hp / MAX_WALL, 0.0, 1.0), 13), Color("8cbe88") if wall_hp > 30.0 else Color("ed6b73"))
            label("Убийств: %d  |  Врагов: %d  |  Выбрано: %s" % [kills_today, enemies.size(), "Костяная" if selected_build == "bone" else "Баллиста"], 25, 126, 18)
            label("Цена: %d маны  |  Можно построить: %s" % [30 if selected_build == "bone" else 55, "ДА" if mana >= (30 if selected_build == "bone" else 55) else "НЕТ"], 25, 151, 17, Color("9ed9ad") if mana >= (30 if selected_build == "bone" else 55) else Color("f3a0a0"))
            if current_day == 1 and phase == "day" and towers.is_empty():
                box(Rect2(245, 176, 688, 73), Color(0.15, 0.11, 0.22, 0.85))
                label("ПЕРВЫЙ ДЕНЬ: 1 — костяная башня (30 маны)", 267, 205, 22, Color("f4d09b"))
                label("Выбери башню и нажми ЛКМ справа от крепости.", 267, 230, 19)
            if wall_hp > 0.0 and wall_hp <= 30.0:
                var alert_blink: float = 0.65 + 0.35 * sin(atmosphere_clock * 8.0)
                box(Rect2(320, 169, 515, 39), Color(0.49, 0.10, 0.14, 0.50 + alert_blink * 0.35))
                label("ТРЕВОГА! СТЕНЫ НА ГРАНИ — R: РЕМОНТ", 334, 196, 20, Color("ffe6d4"))
            if phase == "final_siege" and final_timer <= 10.0:
                box(Rect2(358, 222, 440, 38), Color(0.32, 0.17, 0.42, 0.85))
                label("ПОСЛЕДНИЕ %d СЕКУНД!" % ceili(maxf(final_timer, 0.0)), 398, 249, 24, Color("f4d0ff"))
            label("1/2: выбор башни  |  ЛКМ: строить  |  R: ремонт стен (20)  |  P: пауза", 24, 625, 18)
        elif phase == "night":
            draw_circle(Vector2(940, 115), 67.0, Color(0.67, 0.65, 0.94, 0.10))
            draw_circle(Vector2(940, 115), 53, Color("bbb6d6"))
            for ember in range(9):
                var ex := fmod(float(ember * 157) + atmosphere_clock * (8.0 + float(ember % 3) * 4.0), W)
                var ey := 170.0 + float((ember * 57) % 300) + sin(atmosphere_clock * 1.3 + float(ember)) * 13.0
                draw_circle(Vector2(ex, ey), 2.5, Color(0.72, 0.52, 0.87, 0.26))
            # Distinct architectural silhouettes and palettes for each night.
            var night_stone := Color("6c5c77")
            if current_day == 2:
                night_stone = Color("826479")
                for pillar in range(5):
                    box(Rect2(100 + pillar * 220, 215, 29, 335), Color("3c344d"))
                    box(Rect2(91 + pillar * 220, 213, 47, 12), Color("554562"))
            elif current_day == 3:
                night_stone = Color("70818b")
                for arch in range(4):
                    var ax := 120.0 + float(arch) * 255.0
                    box(Rect2(ax, 245, 28, 305), Color("344855"))
                    box(Rect2(ax + 145, 245, 28, 305), Color("344855"))
                    draw_arc(Vector2(ax + 86, 245), 86.0, PI, TAU, 24, Color("637b87"), 8.0)
            elif current_day == 4:
                night_stone = Color("92475a")
                box(Rect2(0, FLOOR - 16, W, 16), Color("5d2638"))
                for vein in range(7):
                    var vx := 80.0 + float(vein) * 168.0
                    draw_line(Vector2(vx, 190), Vector2(vx + 52, FLOOR - 20), Color(0.95, 0.23, 0.39, 0.3), 7.0)
                    draw_circle(Vector2(vx + 52, FLOOR - 20), 15.0 + sin(atmosphere_clock * 2.0 + vx) * 2.0, Color(0.94, 0.18, 0.35, 0.15))
            elif current_day == 5:
                night_stone = Color("65718e")
                for monument in range(4):
                    var mx := 125.0 + float(monument) * 285.0
                    box(Rect2(mx - 15, 260, 30, 290), Color("354258"))
                    box(Rect2(mx - 29, 246, 58, 17), Color("546584"))
                    draw_colored_polygon(PackedVector2Array([Vector2(mx - 35, 246), Vector2(mx, 190), Vector2(mx + 35, 246)]), Color("7189a9"))
                    draw_circle(Vector2(mx, 288), 10.0, Color(0.49, 0.90, 0.94, 0.33))
            else:
                for column in range(3):
                    var cx := 195.0 + float(column) * 315.0
                    box(Rect2(cx, 320, 18, FLOOR - 320), Color("30293d"))
                    box(Rect2(cx - 8, 313, 34, 9), Color("554760"))
            # Five location identities: cold catacombs, cursed crypt, light cathedral,
            # blood mines and the first king's tomb. All elements are decorative.
            if current_day == 1:
                for niche in range(5):
                    var nx: float = 105.0 + float(niche) * 224.0
                    draw_arc(Vector2(nx, 365.0), 35.0, PI, TAU, 18, Color("6a617d"), 5.0)
                    box(Rect2(nx - 16.0, 365.0, 32.0, 83.0), Color("25243a"))
                    draw_circle(Vector2(nx, 390.0), 8.0, Color(0.52, 0.83, 0.95, 0.22))
            elif current_day == 2:
                for coffin in range(4):
                    var cx_crypt: float = 160.0 + float(coffin) * 285.0
                    box(Rect2(cx_crypt - 28.0, FLOOR - 73.0, 56.0, 73.0), Color("4e3b54"))
                    draw_colored_polygon(PackedVector2Array([Vector2(cx_crypt - 32.0, FLOOR - 73.0), Vector2(cx_crypt, FLOOR - 101.0), Vector2(cx_crypt + 32.0, FLOOR - 73.0)]), Color("765773"))
                    draw_line(Vector2(cx_crypt, FLOOR - 65.0), Vector2(cx_crypt, FLOOR - 15.0), Color("a77c98"), 3.0)
            elif current_day == 3:
                for window in range(4):
                    var wx: float = 198.0 + float(window) * 255.0
                    draw_arc(Vector2(wx, 304.0), 21.0, PI, TAU, 16, Color("b5d9e7"), 4.0)
                    box(Rect2(wx - 18.0, 304.0, 36.0, 76.0), Color(0.44, 0.76, 0.94, 0.24))
                    draw_line(Vector2(wx, 284.0), Vector2(wx, 378.0), Color("8caebd"), 2.0)
                    draw_line(Vector2(wx - 18.0, 337.0), Vector2(wx + 18.0, 337.0), Color("8caebd"), 2.0)
            elif current_day == 4:
                for crystal in range(8):
                    var bx: float = 75.0 + float(crystal) * 150.0
                    var crystal_height: float = 30.0 + float(crystal % 3) * 16.0
                    draw_colored_polygon(PackedVector2Array([Vector2(bx - 17.0, FLOOR), Vector2(bx, FLOOR - crystal_height), Vector2(bx + 17.0, FLOOR)]), Color(0.85, 0.22, 0.37, 0.64))
                    draw_line(Vector2(bx, FLOOR - crystal_height), Vector2(bx, FLOOR - 3.0), Color("f08b9e"), 2.0)
            elif current_day == 5:
                for seal in range(4):
                    var king_x: float = 125.0 + float(seal) * 285.0
                    draw_arc(Vector2(king_x, 336.0), 24.0, 0.0, TAU, 28, Color("9acddd"), 3.0)
                    draw_colored_polygon(PackedVector2Array([Vector2(king_x, 322.0), Vector2(king_x + 12.0, 336.0), Vector2(king_x, 350.0), Vector2(king_x - 12.0, 336.0)]), Color(0.56, 0.87, 0.94, 0.50))
            # Hanging chains and masonry seams give the ruins a stronger silhouette.
            for chain in range(5):
                var chain_x: float = 145.0 + float(chain) * 208.0
                var chain_top: float = 128.0 + float(chain % 3) * 26.0
                for link in range(7):
                    var link_y: float = chain_top + float(link) * 13.0
                    draw_arc(Vector2(chain_x + sin(atmosphere_clock * 0.7 + float(chain)) * 2.0, link_y), 5.0, 0.0, TAU, 12, Color("6f6879"), 2.0)
            for p in platforms:
                box(p, night_stone)
                box(Rect2(p.position.x, p.position.y, p.size.x, 4.0), Color("aba0ac"))
                var brick_count: int = int(p.size.x / 29.0)
                for brick in range(brick_count):
                    var seam_x: float = p.position.x + 17.0 + float(brick) * 29.0
                    draw_line(Vector2(seam_x, p.position.y + 5.0), Vector2(seam_x, p.position.y + p.size.y - 2.0), Color("39354a"), 1.0)
            # A row of cracked masonry at the foot of each dungeon.
            for stone in range(19):
                var stone_x: float = float(stone) * 63.0
                box(Rect2(stone_x, FLOOR - 12.0, 61, 12), Color("494052"))
                draw_line(Vector2(stone_x + 22.0, FLOOR - 9.0), Vector2(stone_x + 17.0, FLOOR - 2.0), Color("776779"), 1.0)
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
                draw_circle(gem, 20.0 + sin(atmosphere_clock * 3.0 + gem.x) * 3.0, Color(0.32, 0.90, 1.0, 0.16))
                draw_colored_polygon(PackedVector2Array([gem + Vector2(0, -16), gem + Vector2(13, 0), gem + Vector2(0, 16), gem + Vector2(-13, 0)]), Color("5de0e9"))
            for e in night_enemies:
                if float(e["hp"]) <= 0.0:
                    continue
                var enemy_x: float = float(e["x"])
                var bob: float = sin(atmosphere_clock * 7.0 + enemy_x * 0.04) * 3.0
                box(Rect2(enemy_x - 15.0, FLOOR - 39.0 + bob, 30, 38), Color("557a66"))
                draw_circle(Vector2(enemy_x, FLOOR - 43.0 + bob), 13, Color("9cc09b"))
                draw_colored_polygon(PackedVector2Array([Vector2(enemy_x - 14, FLOOR - 48 + bob), Vector2(enemy_x - 20, FLOOR - 64 + bob), Vector2(enemy_x - 5, FLOOR - 53 + bob)]), Color("71917f"))
                draw_colored_polygon(PackedVector2Array([Vector2(enemy_x + 14, FLOOR - 48 + bob), Vector2(enemy_x + 20, FLOOR - 64 + bob), Vector2(enemy_x + 5, FLOOR - 53 + bob)]), Color("71917f"))
                box(Rect2(enemy_x - 8, FLOOR - 46 + bob, 5, 3), Color("f5c877"))
                box(Rect2(enemy_x + 3, FLOOR - 46 + bob, 5, 3), Color("f5c877"))
            if mage["hp"] > 0.0:
                var mage_x: float = float(mage["x"])
                var mage_float: float = sin(atmosphere_clock * 3.2) * 4.0
                draw_circle(Vector2(mage_x, FLOOR - 64 + mage_float), 32, Color(0.35, 0.71, 1.0, 0.12))
                draw_texture_rect(preload("res://assets/enemies/light_mage.svg"), Rect2(mage_x - 27.0, FLOOR - 109.0 + mage_float, 54.0, 92.0), false)
                box(Rect2(mage_x - 19, FLOOR - 96, 38.0 * clampf(float(mage["hp"]) / (60.0 if current_day == 1 else (120.0 if current_day == 4 else (145.0 if current_day == 5 else (105.0 if current_day == 3 else 85.0)))), 0.0, 1.0), 4), Color("71b7ff"))
            for bolt in mage_bolts:
                draw_circle(bolt["pos"], 8.0, Color("7bd9ff"))
            if boss_hp > 0.0:
                if boss_windup > 0.0:
                    box(Rect2(boss_pos.x - 85, FLOOR - 10, 170, 10), Color("eb5c60"))
                    label("УДАР!", boss_pos.x - 30, 405, 20, Color("f4a2a2"))
                    draw_arc(boss_pos, 94.0 + sin(atmosphere_clock * 17.0) * 3.0, 0.0, TAU, 40, Color(1.0, 0.27, 0.34, 0.47), 4.0)
                draw_texture_rect(preload("res://assets/enemies/abyss_guardian.svg"), Rect2(boss_pos.x - 52.0, boss_pos.y - 89.0, 104.0, 133.0), false)
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
            draw_gothic_hud_panel(181.0)
            label("НОЧЬ %d / 5  •  %s" % [current_day, "КАТАКОМБЫ" if current_day == 1 else ("ПРОКЛЯТАЯ УСЫПАЛЬНИЦА" if current_day == 2 else ("СОБОР СВЕТА" if current_day == 3 else ("КРОВАВЫЕ ШАХТЫ" if current_day == 4 else "ГРОБНИЦА ПЕРВОГО КОРОЛЯ")))], 25, 35, 27, Color("b9afea"))
            box(Rect2(24, 78, 260, 9), Color("413345"))
            box(Rect2(24, 78, 260.0 * clampf(player_hp / 100.0, 0.0, 1.0), 9), Color("dc6e83") if player_hp <= 25.0 else Color("b37fd2"))
            label("Здоровье: %d    Мана: %d    Души: %d    Камень: %s" % [maxi(0, ceili(player_hp)), mana, souls, "ДА" if stone_taken else "НЕТ"], 25, 71, 22)
            var trap_warning := "ШИПЫ АКТИВНЫ — уйди с опасного участка!" if spike_phase >= 2.1 else ("Шипы скоро активируются!" if spike_phase >= 1.4 else "Шипы сейчас безопасны")
            label(trap_warning, 25, 106, 18, Color("f38c95") if spike_phase >= 2.1 else (Color("f1c780") if spike_phase >= 1.4 else Color("9fd7bd")))
            box(Rect2(25, 117, 250, 7), Color("383748"))
            box(Rect2(25, 117, 250.0 * clampf(spike_phase / 3.1, 0.0, 1.0), 7), Color("e8797a") if spike_phase >= 2.1 else Color("d9b67b"))
            var can_heal: bool = mana >= 20 and player_hp < 100.0
            var can_dash: bool = mana >= 15 and dash_cooldown <= 0.0
            label("H: лечение 20 маны %s  |  Shift: рывок 15 маны %s" % ["[ГОТОВО]" if can_heal else "[НЕДОСТУПНО]", "[ГОТОВО]" if can_dash else "[НЕДОСТУПНО]"], 25, 152, 17, Color("c8bedf"))
            if current_day == 1 and boss_hp > 0.0 and not stone_taken:
                label("ЦЕЛЬ: победи хранителя справа, затем забери Камень Бездны.", 25, 181, 17, Color("f4d29a"))
            elif boss_hp <= 0.0 and not stone_taken:
                label("ЦЕЛЬ: забери светящийся камень справа!", 25, 181, 19, Color("f4d29a"))
            elif stone_taken:
                label("ЦЕЛЬ: камень твой! Вернись к ПОРТАЛУ слева.", 25, 181, 19, Color("a8e9d0"))
            if player_hp > 0.0 and player_hp <= 25.0:
                var danger_blink: float = 0.60 + 0.40 * sin(atmosphere_clock * 8.0)
                box(Rect2(310, 212, 530, 43), Color(0.54, 0.09, 0.18, 0.40 + danger_blink * 0.40))
                label("КРИТИЧЕСКОЕ ЗДОРОВЬЕ! H — ЛЕЧЕНИЕ", 332, 240, 21, Color("ffe0dd"))
            label("A/D: ходьба | W / Space: прыжок | J: удар | H: лечение | Shift: рывок | P: пауза", 20, 625, 18)
    for particle in particles:
        var alpha: float = clampf(float(particle["life"]) / 0.55, 0.0, 1.0)
        var tint: Color = particle["color"]
        tint.a = alpha
        draw_circle(particle["pos"], float(particle["radius"]) * alpha, tint)
    for impact in impacts:
        var fade: float = clampf(float(impact["life"]) / 0.23, 0.0, 1.0)
        var effect_color: Color = impact["color"]
        effect_color.a = fade
        draw_arc(impact["pos"], float(impact["radius"]) * (1.3 - fade * 0.3), 0.0, TAU, 20, effect_color, 3.0)
    if notice_timer > 0.0:
        box(Rect2(190, 97, 775, 50), Color("39283d"))
        label(notice, 215, 131, 19, Color("f5dcaf"))
    if paused:
        box(Rect2(190, 155, 775, 340), Color("171425"))
        box(Rect2(201, 166, 753, 318), Color("30253f"))
        label("ПАУЗА", 485, 216, 42, Color("e3b3e9"))
        var pause_goal := ""
        var pause_controls := ""
        if phase == "day":
            pause_goal = "ЦЕЛЬ: защити крепость до наступления ночи."
            pause_controls = "1/2 — башни  |  ЛКМ — построить  |  R — ремонт (20 маны)"
        elif phase == "final_siege":
            pause_goal = "ЦЕЛЬ: продержись до завершения финального ритуала!"
            pause_controls = "1/2 — башни  |  ЛКМ — построить  |  R — ремонт (20 маны)"
        elif phase == "night":
            pause_goal = "ЦЕЛЬ: вернись к порталу слева." if stone_taken else ("ЦЕЛЬ: забери камень справа." if boss_hp <= 0.0 else "ЦЕЛЬ: победи хранителя и забери камень.")
            pause_controls = "A/D — ходить  |  W/Space — прыгать  |  J — удар"
        else:
            pause_goal = "ЦЕЛЬ: усиливай крепость и продолжай ритуал."
            pause_controls = "1/2 — улучшения  |  C — обмен маны  |  Enter — дальше"
        label(pause_goal, 235, 278, 21, Color("f5d39e"))
        label(pause_controls, 235, 328, 18)
        if phase == "night":
            label("H — лечение (20 маны)  |  Shift — рывок (15 маны)", 235, 361, 18)
        label("M — фон  |  N — эффекты  |  P — продолжить", 235, 414, 20, Color("c9addd"))
