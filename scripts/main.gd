extends Node2D
## Last Ritual v2.2-rc57: enemy hit reactions, lane-aligned health bars and combat feedback
const W := 1152.0
const H := 648.0
const FLOOR := 550.0
const DAY_LENGTH := 56.0
const MAX_WALL := 100.0
const SAVE_PATH := "user://campaign_v1.json"
const META_PATH := "user://ritual_legacy.json"
var difficulty := 1
var legacy_shards := 0
var legacy_level := 0
var achievement_wins := 0
var achievement_best_day := 1
var meta_paid_this_run := false
var reward_bone_bonus := 0
var reward_mana_bonus := 0
var reward_ward_bonus := 0
var menu_page := "main"
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
var skeletons: Array[Dictionary] = []
var spawn_timer := 0.0
var wave_count := 0
var siege_event := 0
var elite_kills := 0
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
var selected_build := ""
var selected_lane := 1
const LANE_OFFSETS := [-110.0, -55.0, 0.0]
var selected_tower_index := -1
var dragging_tower := false
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
var damage_popups: Array[Dictionary] = []
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
    load_meta()

func save_meta() -> void:
    var file := FileAccess.open(META_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify({"difficulty": difficulty, "shards": legacy_shards, "level": legacy_level, "wins": achievement_wins, "best_day": achievement_best_day}))

func load_meta() -> void:
    if not FileAccess.file_exists(META_PATH):
        return
    var file := FileAccess.open(META_PATH, FileAccess.READ)
    if file == null or file.get_length() > 4096:
        return
    var data: Variant = JSON.parse_string(file.get_as_text())
    if not data is Dictionary:
        return
    difficulty = clampi(int(data.get("difficulty", 1)), 0, 4)
    legacy_shards = clampi(int(data.get("shards", 0)), 0, 99999)
    legacy_level = clampi(int(data.get("level", 0)), 0, 10)
    achievement_wins = clampi(int(data.get("wins", 0)), 0, 99999)
    achievement_best_day = clampi(int(data.get("best_day", 1)), 1, 5)

func start_run() -> void:
    reset_all()
    phase = "day"
    mana += legacy_level * 12
    wall_hp = minf(MAX_WALL, wall_hp + legacy_level * 3.0)

func buy_legacy() -> void:
    var cost: int = 2 + legacy_level * 2
    if legacy_level >= 10 or legacy_shards < cost:
        show_notice("Нужно %d осколков, максимум уровня 10" % cost)
        return
    legacy_shards -= cost
    legacy_level += 1
    save_meta()
    show_notice("Наследие улучшено до %d уровня!" % legacy_level)

func award_run(is_win: bool) -> void:
    if meta_paid_this_run:
        return
    meta_paid_this_run = true
    legacy_shards += maxi(1, stones_collected + (4 if is_win else 0)) * (difficulty + 1)
    achievement_best_day = maxi(achievement_best_day, current_day)
    if is_win:
        achievement_wins += 1
    save_meta()

func reset_all() -> void:
    phase = "title"
    paused = false
    kills_today = 0
    campaign_kills = 0
    towers_built = 0
    repairs_today = 0
    meta_paid_this_run = false
    reward_bone_bonus = 0
    reward_mana_bonus = 0
    reward_ward_bonus = 0
    selected_build = ""
    selected_lane = 1
    selected_tower_index = -1
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
    damage_popups.clear()
    atmosphere_clock = 0.0
    hit_sound_cooldown = 0.0
    time_left = DAY_LENGTH
    wall_hp = MAX_WALL
    mana = 70
    souls = 0
    enemies.clear()
    towers.clear()
    shots.clear()
    skeletons.clear()
    wave_count = 0
    siege_event = 0
    elite_kills = 0
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
    for enemy in enemies:
        enemy["hit_flash"] = maxf(0.0, float(enemy.get("hit_flash", 0.0)) - delta)
    for i in range(damage_popups.size() - 1, -1, -1):
        damage_popups[i]["life"] = float(damage_popups[i]["life"]) - delta
        damage_popups[i]["pos"] = damage_popups[i]["pos"] + Vector2(0.0, -34.0 * delta)
        if damage_popups[i]["life"] <= 0.0:
            damage_popups.remove_at(i)
    if phase == "day":
        update_day(delta)
    elif phase == "night":
        update_night(delta)
    elif phase == "final_siege":
        final_timer = maxf(0.0, final_timer - delta)
        update_day(delta)
        if phase == "final_siege" and wall_hp > 0.0 and final_timer <= 0.0:
            phase = "win"
            award_run(true)
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
                start_run()
            elif phase == "ritual":
                resolve_altar()
        if phase == "day" or phase == "final_siege":
            if event.keycode == KEY_R:
                repair_wall()

        elif phase == "night":
            if event.keycode == KEY_H:
                heal_player()
            elif event.keycode == KEY_SHIFT:
                shadow_dash()
        elif phase == "ritual" and event.keycode == KEY_C:
            if mana >= 25:
                mana -= 25
                souls += 1
                show_notice("Алтарь преобразовал ману в душу")
                save_campaign()
            else:
                show_notice("Не хватает маны для преобразования")

func choose_reward(choice: int) -> void:
    if phase != "reward" or choice < 0 or choice > 2:
        return
    if choice == 0:
        reward_bone_bonus += 1
        show_notice("Дар: башни наносят больше урона в этом походе!")
    elif choice == 1:
        reward_mana_bonus += 1
        mana += 35
        show_notice("Дар: +35 маны сейчас и +5 за каждую победу!")
    else:
        reward_ward_bonus += 1
        wall_hp = minf(MAX_WALL, wall_hp + 35.0)
        show_notice("Дар: стены восстановлены и укреплены!")
    phase = "ritual"
    save_campaign()

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
        siege_event = 0
        kills_today = 0
        repairs_today = 0
        enemies.clear()
        shots.clear()
        skeletons.clear()
        player_hp = 100.0
        towers.clear()
        selected_tower_index = -1
        show_notice("День %d: башни прошлого дня исчезли. Построй новую оборону!" % current_day)
    elif mana >= 50 and souls >= 8:
        mana -= 50
        souls -= 8
        phase = "final_siege"
        play_cue("ritual")
        final_timer = 45.0
        enemies.clear()
        shots.clear()
        skeletons.clear()
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
        saved_towers.append({"x": float(tower["x"]), "type": str(tower["type"]), "lane": int(tower.get("lane", 1)), "level": int(tower.get("level", 1)), "hp": float(tower.get("hp", tower_max_hp(tower)))})
    var data := {
        "version": 1, "day": current_day, "stones": stones_collected,
        "mana": mana, "souls": souls, "wall_hp": wall_hp,
        "tower_power": tower_power_level, "wall_ward": wall_ward_level,
        "towers": saved_towers,
        "campaign_kills": campaign_kills, "towers_built": maxi(towers_built, towers.size()),
        "reward_bone": reward_bone_bonus, "reward_mana": reward_mana_bonus, "reward_ward": reward_ward_bonus
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
        if item["type"] != "bone" and item["type"] != "fire" and item["type"] != "necro":
            return false
        var saved_lane: int = int(item.get("lane", 1))
        var saved_level: int = int(item.get("level", 1))
        if saved_lane < 0 or saved_lane > 2 or saved_level < 1 or saved_level > 3:
            return false
        for placed in checked_towers:
            if int(placed.get("lane", 1)) == saved_lane and absf(float(placed["x"]) - float(item["x"])) < 65.0:
                return false
        var loaded_tower: Dictionary = {"x": float(item["x"]), "type": item["type"], "lane": saved_lane, "level": saved_level, "cooldown": 0.0}
        loaded_tower["hp"] = float(item.get("hp", tower_max_hp(loaded_tower)))
        if not is_finite(float(loaded_tower["hp"])) or loaded_tower["hp"] <= 0.0 or loaded_tower["hp"] > tower_max_hp(loaded_tower):
            return false
        checked_towers.append(loaded_tower)
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
    reward_bone_bonus = clampi(int(data.get("reward_bone", 0)), 0, 5)
    reward_mana_bonus = clampi(int(data.get("reward_mana", 0)), 0, 5)
    reward_ward_bonus = clampi(int(data.get("reward_ward", 0)), 0, 5)
    towers = []
    phase = "ritual"
    stone_taken = true
    show_notice("Сохранение загружено: камней %d / 5" % stones_collected)
    return true

func _input(event: InputEvent) -> void:
    if paused:
        dragging_tower = false
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and (phase == "title" or phase == "win" or phase == "lose"):
        var menu_click := get_global_mouse_position()
        if phase != "title":
            if menu_click.y > 485.0:
                menu_page = "main"
                phase = "title"
            return
        if menu_page == "achievements":
            menu_page = "main"
            return
        if menu_click.y >= 300.0 and menu_click.y < 345.0:
            if menu_page == "main":
                start_run()
            else:
                difficulty = (difficulty + 1) % 5
                save_meta()
        elif menu_click.y >= 350.0 and menu_click.y < 395.0:
            if menu_page == "main":
                if not load_campaign():
                    show_notice("Нет сохранённой кампании")
            else:
                buy_legacy()
        elif menu_click.y >= 400.0 and menu_click.y < 445.0:
            menu_page = "legacy" if menu_page == "main" else "main"
        elif menu_click.y >= 450.0 and menu_click.y < 495.0:
            menu_page = "achievements" if menu_page == "main" else "main"
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and phase == "night":
        var attack_target: Vector2 = get_global_mouse_position()
        if absf(attack_target.x - player.x) > 10.0:
            facing = signf(attack_target.x - player.x)
        attack()
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and phase == "reward":
        var reward_click: Vector2 = get_global_mouse_position()
        if reward_click.y >= 270.0 and reward_click.y <= 455.0:
            choose_reward(int(floor((reward_click.x - 140.0) / 297.0)))
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and phase == "ritual":
        var altar_click: Vector2 = get_global_mouse_position()
        if altar_click.x >= 278.0 and altar_click.x <= 894.0 and altar_click.y >= 387.0 and altar_click.y < 426.0:
            buy_upgrade("tower")
        elif altar_click.x >= 278.0 and altar_click.x <= 894.0 and altar_click.y >= 426.0 and altar_click.y <= 464.0:
            buy_upgrade("ward")
        elif altar_click.x >= 200.0 and altar_click.x <= 955.0 and altar_click.y >= 479.0 and altar_click.y <= 584.0:
            resolve_altar()
        return
    if phase != "day" and phase != "final_siege":
        dragging_tower = false
        return
    if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT:
        return
    var mouse: Vector2 = get_global_mouse_position()
    if event.pressed:
        # Press a card to select it; drag and release over a lane to build immediately.
        if mouse.y >= 554.0:
            if mouse.x >= 14.0 and mouse.x <= 184.0:
                selected_build = "bone"
                selected_tower_index = -1
                dragging_tower = true
            elif mouse.x >= 192.0 and mouse.x <= 362.0:
                selected_build = "fire"
                selected_tower_index = -1
                dragging_tower = true
            elif mouse.x >= 370.0 and mouse.x <= 540.0:
                selected_build = "necro"
                selected_tower_index = -1
                dragging_tower = true
            elif mouse.x >= 900.0 and mouse.x <= 1015.0 and selected_tower_index >= 0 and selected_tower_index < towers.size():
                var tower: Dictionary = towers[selected_tower_index]
                upgrade_tower(float(tower["x"]), int(tower.get("lane", 1)))
            elif mouse.x >= 1020.0 and mouse.x <= 1138.0:
                sell_selected_tower()
            return
        # Hit-test the whole tower sprite first, not just the center of its lane.
        for i in range(towers.size()):
            var tower_lane: int = int(towers[i].get("lane", 1))
            var tower_base_y: float = FLOOR + float(LANE_OFFSETS[tower_lane])
            if absf(float(towers[i]["x"]) - mouse.x) <= 35.0 and mouse.y >= tower_base_y - 112.0 and mouse.y <= tower_base_y + 8.0:
                selected_tower_index = i
                selected_lane = tower_lane
                dragging_tower = false
                show_notice("Башня выбрана. Все характеристики — в нижней панели.")
                return
        var lane: int = lane_for_y(mouse.y)
        selected_lane = lane
        selected_tower_index = -1
        dragging_tower = false
        if selected_build == "":
            show_notice("Сначала выбери башню в нижней панели")
        else:
            build_tower(selected_build, mouse.x, lane)
    else:
        if dragging_tower:
            dragging_tower = false
            if mouse.y < 551.0:
                selected_lane = lane_for_y(mouse.y)
                build_tower(selected_build, mouse.x, selected_lane)

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

func tower_max_hp(tower: Dictionary) -> float:
    return (120.0 if tower["type"] == "bone" else (165.0 if tower["type"] == "fire" else 140.0)) + float(int(tower.get("level", 1)) - 1) * 55.0

func lane_for_y(y: float) -> int:
    var best_lane: int = 0
    var best_distance: float = INF
    for lane_index in range(3):
        var distance: float = absf(y - (FLOOR + float(LANE_OFFSETS[lane_index]) - 48.0))
        if distance < best_distance:
            best_distance = distance
            best_lane = lane_index
    return best_lane

func tower_sell_refund(tower: Dictionary) -> int:
    var invested: int = 30 if tower["type"] == "bone" else (55 if tower["type"] == "fire" else 65)
    var level: int = int(tower.get("level", 1))
    for upgrade_step in range(1, level):
        invested += 25 * upgrade_step
    return int(floor(float(invested) * 0.5))

func sell_selected_tower() -> void:
    if selected_tower_index < 0 or selected_tower_index >= towers.size():
        show_notice("Сначала выбери башню")
        return
    var tower: Dictionary = towers[selected_tower_index]
    var refund: int = tower_sell_refund(tower)
    var tower_name: String = "Костяная башня" if tower["type"] == "bone" else ("Адская баллиста" if tower["type"] == "fire" else "Некромантская башня")
    burst_particles(Vector2(float(tower["x"]), FLOOR + float(LANE_OFFSETS[int(tower.get("lane", 1))]) - 55.0), Color("e3c1a0"), 8)
    towers.remove_at(selected_tower_index)
    selected_tower_index = -1
    mana += refund
    show_notice("%s продана: возвращено %d маны" % [tower_name, refund])

func upgrade_tower(mx: float, lane: int) -> void:
    for tower in towers:
        if int(tower.get("lane", 1)) != lane or absf(float(tower["x"]) - mx) > 35.0:
            continue
        if int(tower.get("level", 1)) >= 3:
            show_notice("Башня уже максимального уровня")
            return
        var price: int = 25 * int(tower.get("level", 1))
        if mana < price:
            show_notice("Улучшение требует %d маны" % price)
            return
        mana -= price
        tower["level"] = int(tower.get("level", 1)) + 1
        tower["hp"] = minf(tower_max_hp(tower), float(tower.get("hp", 0.0)) + 55.0)
        show_notice("Башня улучшена до уровня %d!" % int(tower["level"]))
        return
    show_notice("Нет башни для улучшения на выбранной линии")

func build_tower(kind: String, mx: float, lane: int = 1) -> void:
    var cost := 30 if kind == "bone" else (55 if kind == "fire" else 65)
    if mx < 245 or mx > 1020:
        show_notice("Ставь башни между крепостью и врагом")
        return
    if mana < cost:
        show_notice("Не хватает %d маны для башни (нужно %d)" % [cost - mana, cost])
        return
    for tower in towers:
        if int(tower.get("lane", 1)) == lane and absf(tower["x"] - mx) < 65.0:
            show_notice("Слишком близко: оставь между башнями не меньше 65 шагов")
            return
    mana -= cost
    towers.append({"x": mx, "type": kind, "lane": lane, "level": 1, "hp": 120.0 if kind == "bone" else (165.0 if kind == "fire" else 140.0), "cooldown": 0.0})
    selected_tower_index = towers.size() - 1
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
    selected_tower_index = -1
    towers.clear()
    skeletons.clear()
    stone_taken = false
    player = Vector2(95, FLOOR - 25)
    vel = Vector2.ZERO
    grounded = true
    jump_was_down = false
    player_hp = 100.0
    boss_hp = 140.0 if current_day == 1 else (190.0 if current_day == 2 else (230.0 if current_day == 3 else (270.0 if current_day == 4 else 340.0)))
    boss_hp *= 0.8 + float(difficulty) * 0.2
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
        platforms = [Rect2(145, 476, 175, 16), Rect2(345, 425, 155, 16), Rect2(555, 450, 160, 16), Rect2(765, 395, 150, 16)]
        trap_positions = [315.0, 645.0, 930.0]
        gems = [Vector2(230, 405), Vector2(415, 340), Vector2(650, 396), Vector2(845, 310), Vector2(1025, 519)]
        mage["x"] = 715.0
        night_enemies = [{"x": 250.0, "hp": 70.0, "dir": 1.0}, {"x": 845.0, "hp": 80.0, "dir": -1.0}]
    else:
        platforms = [Rect2(205, 473, 135, 16), Rect2(415, 413, 145, 16), Rect2(640, 462, 130, 16), Rect2(830, 396, 135, 16)]
        trap_positions = [375.0, 775.0]
    show_notice("Ночь %d: победи хранителя, забери камень и вернись к порталу слева!" % current_day)

func tower_ability_description(kind: String, level: int = 1) -> String:
    if kind == "bone":
        return "Замедление %.1f с" % (2.5 + 0.35 * float(level - 1))
    if kind == "necro":
        return "Скелет: %.0f HP / 6 с" % (65.0 + float(level - 1) * 30.0)
    return "Крит %.0f%% + взрыв" % ((0.18 + 0.04 * float(level - 1)) * 100.0)

func apply_tower_shot(shot: Dictionary, target_index: int) -> void:
    if target_index < 0 or target_index >= enemies.size():
        return
    var target_x: float = float(enemies[target_index]["x"])
    var lane: int = int(shot.get("lane", 1))
    var kind: String = str(shot.get("type", "bone"))
    var level: int = int(shot.get("level", 1))
    var critical: bool = bool(shot.get("critical", false))
    var power_multiplier: float = (1.35 if tower_power_level > 0 else 1.0) * (1.0 + 0.12 * float(reward_bone_bonus))
    var critical_multiplier: float = 1.8 if critical else 1.0
    var damage: float = float(shot["damage"]) * power_multiplier * critical_multiplier
    enemies[target_index]["hp"] = float(enemies[target_index]["hp"]) - damage
    enemies[target_index]["hit_flash"] = 0.16
    enemies[target_index]["hit_flash_color"] = Color("ffe18a") if critical else (Color("a8e8f0") if kind == "bone" else Color("ffb26e"))
    var target_pos := Vector2(target_x, FLOOR - 32.0 + float(LANE_OFFSETS[lane]))
    var hit_tint: Color = Color("ffe18a") if critical else (Color("a8e8f0") if kind == "bone" else Color("ffbf82"))
    spawn_damage_popup(target_pos, damage, hit_tint, critical)
    if kind == "bone":
        enemies[target_index]["slow_timer"] = maxf(float(enemies[target_index].get("slow_timer", 0.0)), 2.5 + 0.35 * float(level - 1))
        enemies[target_index]["slow_factor"] = 0.62
        emit_impact(target_pos, Color("8de1e7"), 25.0)
    else:
        emit_impact(target_pos, Color("ffe18a") if critical else Color("ffb36b"), 31.0 if critical else 25.0)
        var splash_radius: float = 78.0 + float(level - 1) * 4.0
        for splash_index in range(enemies.size()):
            if splash_index == target_index or int(enemies[splash_index].get("lane", 1)) != lane:
                continue
            if absf(float(enemies[splash_index]["x"]) - target_x) <= splash_radius:
                var splash_damage: float = float(shot["damage"]) * 0.35 * power_multiplier * critical_multiplier
                enemies[splash_index]["hp"] = float(enemies[splash_index]["hp"]) - splash_damage
                enemies[splash_index]["hit_flash"] = 0.13
                enemies[splash_index]["hit_flash_color"] = Color("ffb26e")
                var splash_pos := Vector2(float(enemies[splash_index]["x"]), FLOOR - 32.0 + float(LANE_OFFSETS[lane]))
                emit_impact(splash_pos, Color("ff9d59"), 16.0)
                spawn_damage_popup(splash_pos, splash_damage, Color("ffb26e"), critical)
    if hit_sound_cooldown <= 0.0:
        play_cue("hit")
        hit_sound_cooldown = 0.13

func update_day(delta: float) -> void:
    day_elapsed += delta
    if phase == "day":
        time_left -= delta
    spawn_timer -= delta
    if spawn_timer <= 0.0:
        wave_count += 1
        if wave_count % 8 == 0:
            siege_event = randi_range(0, 2)
            show_notice("СОБЫТИЕ: %s" % (["Багровая орда", "Проклятый туман", "Души павших"][siege_event]))
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
        health *= 0.8 + float(difficulty) * 0.2
        damage *= 0.8 + float(difficulty) * 0.2
        var elite: bool = wave_count >= 4 and wave_count % 6 == 0
        if elite:
            health *= 2.2
            damage *= 1.5
        if siege_event == 0:
            speed *= 1.15
        elif siege_event == 1:
            health *= 1.12
        enemies.append({"x": W + 32.0, "hp": health, "max_hp": health, "speed": speed, "damage": damage, "hit_cd": 0.0, "kind": kind, "lane": randi_range(0, 2), "sabotaged": false, "elite": elite})
    for tower in towers:
        tower["disabled"] = maxf(0.0, float(tower.get("disabled", 0.0)) - delta)
        tower["flash"] = maxf(0.0, float(tower.get("flash", 0.0)) - delta)
        tower["cooldown"] -= delta
        if tower["type"] == "necro":
            if tower["cooldown"] <= 0.0 and tower["disabled"] <= 0.0:
                var summon_level: int = int(tower.get("level", 1))
                skeletons.append({"x": float(tower["x"]) + 55.0, "lane": int(tower.get("lane", 1)), "hp": 65.0 + 30.0 * float(summon_level - 1), "life": 6.0})
                tower["flash"] = 0.18
                tower["flash_target_x"] = float(tower["x"]) + 55.0
                tower["cooldown"] = maxf(4.0, 7.0 - float(summon_level - 1))
            continue
        if tower["cooldown"] <= 0.0 and tower["disabled"] <= 0.0:
            var target_x := INF
            for enemy in enemies:
                if int(enemy.get("lane", 1)) == int(tower.get("lane", 1)) and absf(enemy["x"] - tower["x"]) <= (260.0 if tower["type"] == "bone" else 375.0) and enemy["x"] < target_x:
                    target_x = enemy["x"]
            if target_x != INF:
                tower["cooldown"] = 0.9 if tower["type"] == "bone" else 1.8
                tower["flash"] = 0.16
                tower["flash_target_x"] = target_x
                var tower_level: int = int(tower.get("level", 1))
                var is_critical: bool = tower["type"] == "fire" and randf() < (0.18 + 0.04 * float(tower_level - 1))
                shots.append({"x": tower["x"], "target": target_x, "lane": int(tower.get("lane", 1)), "damage": (22.0 if tower["type"] == "bone" else 65.0) * (1.0 + 0.45 * float(tower_level - 1)), "type": tower["type"], "level": tower_level, "critical": is_critical})
    for shot in shots:
        var closest_index := -1
        var distance := INF
        for i in range(enemies.size()):
            var d: float = absf(enemies[i]["x"] - shot["target"])
            if int(enemies[i].get("lane", 1)) == int(shot.get("lane", 1)) and d < distance:
                distance = d
                closest_index = i
        if closest_index >= 0:
            apply_tower_shot(shot, closest_index)
    shots.clear()
    for sk in skeletons:
        sk["life"] = float(sk["life"]) - delta
    for i in range(enemies.size() - 1, -1, -1):
        var enemy := enemies[i]
        if enemy["hp"] <= 0.0:
            var elite_bonus: int = 16 if bool(enemy.get("elite", false)) else 0
            if elite_bonus > 0:
                elite_kills += 1
            mana += 9 + reward_mana_bonus * 5 + elite_bonus
            souls += 2 if elite_bonus > 0 or siege_event == 2 else 1
            kills_today += 1
            campaign_kills += 1
            if enemy["kind"] == "saboteur":
                saboteurs_defeated += 1
            burst_particles(Vector2(float(enemy["x"]), FLOOR - 30.0 + float(LANE_OFFSETS[int(enemy.get("lane", 1))])), Color("a2d5e0") if enemy["kind"] == "saboteur" else Color("d9a1a8"), 9)
            enemies.remove_at(i)
            continue
        if enemy["kind"] == "saboteur" and not enemy["sabotaged"]:
            for tower in towers:
                if int(enemy.get("lane", 1)) == int(tower.get("lane", 1)) and absf(enemy["x"] - tower["x"]) < 95.0:
                    tower["disabled"] = 4.5
                    enemy["sabotaged"] = true
                    show_notice("Диверсант отключил башню на 4,5 секунды!")
                    break
        var blocked_by_tower := false
        for sk in skeletons:
            if int(sk["lane"]) == int(enemy.get("lane", 1)) and absf(float(sk["x"]) - float(enemy["x"])) < 35.0 and float(sk["hp"]) > 0.0:
                sk["hp"] = float(sk["hp"]) - float(enemy["damage"]) * delta * 2.0
                blocked_by_tower = true
                break
        if not blocked_by_tower:
            for tower in towers:
                if int(tower.get("lane", 1)) == int(enemy.get("lane", 1)) and absf(float(tower["x"]) - float(enemy["x"])) < 31.0 and float(tower.get("hp", tower_max_hp(tower))) > 0.0:
                    tower["hp"] = float(tower.get("hp", tower_max_hp(tower))) - float(enemy["damage"]) * delta * 1.5
                    blocked_by_tower = true
                    break
        enemy["slow_timer"] = maxf(0.0, float(enemy.get("slow_timer", 0.0)) - delta)
        var slow_factor: float = float(enemy.get("slow_factor", 1.0)) if float(enemy.get("slow_timer", 0.0)) > 0.0 else 1.0
        if enemy["x"] > 191.0 and not blocked_by_tower:
            enemy["x"] -= enemy["speed"] * slow_factor * delta
        else:
            enemy["hit_cd"] -= delta
            if enemy["hit_cd"] <= 0.0:
                wall_hp -= enemy["damage"] * (0.75 if wall_ward_level > 0 else 1.0)
                enemy["hit_cd"] = 1.3
    for sk_index in range(skeletons.size() - 1, -1, -1):
        if float(skeletons[sk_index]["life"]) <= 0.0 or float(skeletons[sk_index]["hp"]) <= 0.0:
            skeletons.remove_at(sk_index)
    for tower_index in range(towers.size() - 1, -1, -1):
        if float(towers[tower_index].get("hp", 1.0)) <= 0.0:
            burst_particles(Vector2(float(towers[tower_index]["x"]), FLOOR - 68.0), Color("f5a47d"), 12)
            towers.remove_at(tower_index)
            if selected_tower_index == tower_index:
                selected_tower_index = -1
            elif selected_tower_index > tower_index:
                selected_tower_index -= 1
    if wall_hp <= 0.0:
        wall_hp = 0.0
        phase = "lose"
        award_run(false)
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
        vel.y = -490.0
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
        phase = "reward"
        show_notice("Выбери один из трёх даров Бездны!")

func hurt(amount: float) -> void:
    if hurt_cooldown > 0.0:
        return
    hurt_cooldown = 1.2
    player_hp -= amount
    play_cue("damage")
    if player_hp <= 0.0:
        player_hp = 0.0
        phase = "lose"
        award_run(false)

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
            var enemy_hit_pos := Vector2(float(e["x"]), FLOOR - 25.0)
            spawn_damage_popup(enemy_hit_pos, 24.0, Color("d7b0fa"))
            emit_impact(enemy_hit_pos, Color("d7b0fa"), 19.0)
            burst_particles(Vector2(float(e["x"]), FLOOR - 25.0), Color("bc8cec"), 5)
    if mage["hp"] > 0.0 and (mage["x"] - player.x) * facing >= -10.0 and (mage["x"] - player.x) * facing < reach and absf(player.y - (FLOOR - 60.0)) < 95.0:
        mage["hp"] -= 24.0
        var mage_hit_pos := Vector2(float(mage["x"]), FLOOR - 55.0)
        spawn_damage_popup(mage_hit_pos, 24.0, Color("b4eaff"))
        emit_impact(mage_hit_pos, Color("d7b0fa"), 22.0)
        burst_particles(Vector2(float(mage["x"]), FLOOR - 55.0), Color("b4eaff"), 7)
        if mage["hp"] <= 0.0:
            mana += 18
            souls += 2
            burst_particles(Vector2(float(mage["x"]), FLOOR - 54.0), Color("8acfff"), 17)
            show_notice("Маг Света повержен!")
    if boss_hp > 0.0 and (boss_pos.x - player.x) * facing >= -10.0 and (boss_pos.x - player.x) * facing < reach and absf(player.y - boss_pos.y) < 85.0:
        boss_hp -= 18.0
        spawn_damage_popup(boss_pos, 18.0, Color("ff9db9"))
        emit_impact(boss_pos, Color("f67ba2"), 28.0)
        burst_particles(boss_pos, Color("fb97bd"), 10)
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

func spawn_damage_popup(pos: Vector2, amount: float, tint: Color, critical: bool = false) -> void:
    if damage_popups.size() >= 24:
        damage_popups.pop_front()
    damage_popups.append({
        "pos": pos,
        "text": ("CRIT! " if critical else "") + str(ceili(amount)),
        "color": tint,
        "life": 0.72,
        "max_life": 0.72
    })

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
    var stride: float = clampf(absf(vel.x) / 230.0, 0.0, 1.0)
    var bounce: float = sin(atmosphere_clock * 11.0) * 2.8 * stride
    var breathe: float = sin(atmosphere_clock * 2.5) * 1.0
    var sprite_width: float = 62.0 + stride * 1.6
    draw_texture_rect(preload("res://assets/characters/dark_lord.svg"), Rect2(pos.x - sprite_width * 0.5, pos.y - 57.0 + bounce + breathe, sprite_width, 83.0 - stride * 1.2), false)

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
        for menu_i in range(4):
            var menu_y: float = 300.0 + float(menu_i) * 50.0
            box(Rect2(340.0, menu_y, 475.0, 43.0), Color(0.22, 0.15, 0.30, 0.94))
            draw_rect(Rect2(340.0, menu_y, 475.0, 43.0), Color("997da6"), false, 2.0)
        label("ПОСЛЕДНИЙ РИТУАЛ", 224, 245, 46, Color("e4b9ed"))
        if menu_page == "main":
            label("НОВАЯ ИГРА", 422, 330, 23, Color("ffdcae"))
            label("ПРОДОЛЖИТЬ", 422, 380, 23)
            label("НАСЛЕДИЕ И СЛОЖНОСТЬ", 356, 430, 23)
            label("ДОСТИЖЕНИЯ", 422, 480, 23)
        elif menu_page == "legacy":
            label("СЛОЖНОСТЬ: %d / 4   [НАЖАТЬ]" % difficulty, 355, 330, 21, Color("ffdcae"))
            label("ПОВЫСИТЬ НАСЛЕДИЕ: %d оск." % (2 + legacy_level * 2), 355, 380, 21)
            label("НАЗАД", 480, 430, 21)
            label("Осколки: %d  •  Наследие: %d/10" % [legacy_shards, legacy_level], 340, 478, 20)
        else:
            label("ПОБЕД: %d" % achievement_wins, 430, 337, 23, Color("ffdcae"))
            label("ЛУЧШИЙ ДЕНЬ: %d / 5" % achievement_best_day, 407, 385, 22)
            label("НАЖМИ ДЛЯ ВОЗВРАТА", 385, 460, 20)
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
        label("ЛКМ — вернуться в главное меню", 365, 509, 22, Color("f5cf84"))
        label("Осколки наследия: %d" % legacy_shards, 413, 469, 18)
        return
    if phase == "reward":
        box(Rect2(112, 142, 928, 374), Color(0.095, 0.07, 0.15, 0.96))
        draw_rect(Rect2(112, 142, 928, 374), Color("ad85c9"), false, 3.0)
        label("ВЫБЕРИ ДАР БЕЗДНЫ", 320, 210, 36, Color("e9beff"))
        label("Один дар после каждой ночи • действует до конца похода", 205, 250, 19, Color("cfc2dc"))
        for reward_i in range(3):
            var reward_x: float = 140.0 + float(reward_i) * 297.0
            box(Rect2(reward_x, 270.0, 276.0, 185.0), Color("322442"))
            draw_rect(Rect2(reward_x, 270.0, 276.0, 185.0), Color("a68bb9"), false, 2.0)
            label("МОЩЬ БАШЕН" if reward_i == 0 else ("ЗАПАС МАНЫ" if reward_i == 1 else "КРЕПОСТЬ"), reward_x + 24.0, 324.0, 21, Color("f3dbba"))
            label("+12% урона башен" if reward_i == 0 else ("+35 маны сейчас" if reward_i == 1 else "+35 здоровья стен"), reward_x + 22.0, 370.0, 19)
            label("до конца забега" if reward_i == 0 else ("+5 маны за врага" if reward_i == 1 else "восстановление стен"), reward_x + 22.0, 406.0, 18, Color("bbdfcc"))
            label("НАЖМИ", reward_x + 87.0, 437.0, 17, Color("ffe1ad"))
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
            box(Rect2(286.0, 391.0, 600.0, 32.0), Color("35283f"))
            draw_rect(Rect2(286.0, 391.0, 600.0, 32.0), Color("9874a7"), false, 1.0)
            box(Rect2(286.0, 427.0, 600.0, 32.0), Color("35283f"))
            draw_rect(Rect2(286.0, 427.0, 600.0, 32.0), Color("9874a7"), false, 1.0)
            label("УСИЛЕНИЕ БАШЕН — 45 маны %s" % ["[КУПЛЕНО]" if tower_power_level > 0 else ""], 310, 415, 18)
            label("ЗАЩИТНАЯ ПЕЧАТЬ — 4 души %s" % ["[КУПЛЕНО]" if wall_ward_level > 0 else ""], 310, 449, 18)
        label("Кликни нижнюю панель, чтобы продолжить  •  C — обмен маны", 310, 600, 17)
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
            # Three visible siege lanes; selected lane is outlined.
            for lane_index in range(3):
                var lane_y: float = FLOOR + float(LANE_OFFSETS[lane_index])
                draw_line(Vector2(239.0, lane_y), Vector2(1125.0, lane_y), Color("b7a5ad", 0.47 if selected_lane == lane_index else 0.22), 2.0)
                label("%d" % (lane_index + 1), 224.0, lane_y - 7.0, 15, Color("f1c6d3"))
            for tower_i in range(towers.size()):
                var tower: Dictionary = towers[tower_i]
                var tx: float = tower["x"]
                var tower_lane: int = int(tower.get("lane", 1))
                var tower_y: float = FLOOR + float(LANE_OFFSETS[tower_lane])
                var fire_flash: float = clampf(float(tower.get("flash", 0.0)) / 0.18, 0.0, 1.0)
                if fire_flash > 0.0:
                    var glow_color: Color = Color("86e6f0") if tower["type"] == "bone" else (Color("ffc17a") if tower["type"] == "fire" else Color("d9a2ff"))
                    glow_color.a = 0.12 + fire_flash * 0.22
                    draw_circle(Vector2(tx, tower_y - 54.0), 34.0 + (1.0 - fire_flash) * 8.0, glow_color)
                    var tracer_color: Color = glow_color
                    tracer_color.a = fire_flash * 0.68
                    draw_line(Vector2(tx + 5.0, tower_y - 78.0), Vector2(float(tower.get("flash_target_x", tx)), FLOOR - 32.0 + float(LANE_OFFSETS[tower_lane])), tracer_color, 3.0 if tower["type"] == "fire" else 2.0)
                var tower_art: Texture2D = preload("res://assets/towers/bone_tower.svg") if tower["type"] == "bone" else (preload("res://assets/towers/infernal_ballista.svg") if tower["type"] == "fire" else preload("res://assets/towers/necromancer_tower.svg"))
                draw_texture_rect(tower_art, Rect2(tx - 30.0, tower_y - 106.0, 60.0, 106.0), false)
                if selected_tower_index == tower_i:
                    draw_rect(Rect2(tx - 34.0, tower_y - 111.0, 68.0, 115.0), Color("f7dfad"), false, 2.0)
                var hp_ratio: float = clampf(float(tower.get("hp", tower_max_hp(tower))) / tower_max_hp(tower), 0.0, 1.0)
                box(Rect2(tx - 24.0, tower_y - 120.0, 48.0, 6.0), Color("442b36"))
                box(Rect2(tx - 24.0, tower_y - 120.0, 48.0 * hp_ratio, 6.0), Color("88d0a2") if hp_ratio > 0.3 else Color("ec7778"))
                label("%d" % int(tower.get("level", 1)), tx - 5.0, tower_y - 126.0, 16, Color("ffe3a5"))
                if float(tower.get("disabled", 0.0)) > 0.0:
                    draw_line(Vector2(tx - 12, tower_y - 96), Vector2(tx + 12, tower_y - 72), Color("e1bac3"), 3.0)
            for sk in skeletons:
                var sk_y: float = FLOOR + float(LANE_OFFSETS[int(sk["lane"])])
                draw_circle(Vector2(float(sk["x"]), sk_y - 23.0), 12.0, Color("b7d3b2"))
                draw_line(Vector2(float(sk["x"]), sk_y - 10.0), Vector2(float(sk["x"]), sk_y - 45.0), Color("e0e7cb"), 4.0)
                draw_line(Vector2(float(sk["x"]) - 11.0, sk_y - 29.0), Vector2(float(sk["x"]) + 11.0, sk_y - 29.0), Color("e0e7cb"), 3.0)
            for e in enemies:
                var ex: float = e["x"]
                var enemy_lane_offset: float = float(LANE_OFFSETS[int(e.get("lane", 1))])
                var enemy_color := Color("7adbe4") if e["kind"] == "saboteur" else (Color("edc265") if e["kind"] == "runner" else (Color("d66c69") if e["kind"] == "brute" else Color("b0af9b")))
                var flash_amount: float = clampf(float(e.get("hit_flash", 0.0)) / 0.16, 0.0, 1.0)
                var flash_color: Color = e.get("hit_flash_color", Color.WHITE)
                var sprite_tint: Color = (Color("e4b9fa") if bool(e.get("elite", false)) else Color.WHITE).lerp(flash_color, flash_amount)
                if bool(e.get("elite", false)):
                    draw_arc(Vector2(ex, FLOOR - 37.0 + enemy_lane_offset), 36.0, 0.0, TAU, 28, Color("b78be2", 0.62), 2.0)
                if e["kind"] == "raider":
                    var step_y: float = sin(atmosphere_clock * 7.0 + ex * 0.08) * 2.0
                    draw_texture_rect(preload("res://assets/enemies/raider.svg"), Rect2(ex - 21.0, FLOOR - 62.0 + step_y + enemy_lane_offset, 42.0, 62.0), false, sprite_tint)
                    box(Rect2(ex - 17, FLOOR - 67 + enemy_lane_offset, 34.0 * clampf(float(e["hp"]) / float(e["max_hp"]), 0.0, 1.0), 4), Color("f57c79"))
                    continue
                if e["kind"] == "saboteur":
                    var step_y: float = sin(atmosphere_clock * 9.0 + ex * 0.08) * 2.0
                    draw_texture_rect(preload("res://assets/enemies/saboteur.svg"), Rect2(ex - 21.0, FLOOR - 62.0 + step_y + enemy_lane_offset, 42.0, 62.0), false, sprite_tint)
                    box(Rect2(ex - 17, FLOOR - 67 + enemy_lane_offset, 34.0 * clampf(float(e["hp"]) / float(e["max_hp"]), 0.0, 1.0), 4), Color("f57c79"))
                    continue
                if e["kind"] == "runner" or e["kind"] == "brute":
                    var sprite_path := preload("res://assets/enemies/runner.svg") if e["kind"] == "runner" else preload("res://assets/enemies/brute.svg")
                    var sprite_size := Vector2(41.0, 57.0) if e["kind"] == "runner" else Vector2(62.0, 77.0)
                    var gait: float = sin(atmosphere_clock * (13.0 if e["kind"] == "runner" else 5.0) + ex * 0.07) * (3.0 if e["kind"] == "runner" else 1.5)
                    draw_texture_rect(sprite_path, Rect2(ex - sprite_size.x * 0.5, FLOOR - sprite_size.y + gait + enemy_lane_offset, sprite_size.x, sprite_size.y), false, sprite_tint)
                    box(Rect2(ex - 17.0, FLOOR - sprite_size.y - 7.0 + enemy_lane_offset, 34.0 * clampf(float(e["hp"]) / float(e["max_hp"]), 0.0, 1.0), 4.0), Color("f57c79"))
                    continue
                enemy_color = enemy_color.lerp(flash_color, flash_amount)
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
                box(Rect2(ex - 17, FLOOR - 53 + enemy_lane_offset, 34 * clampf(float(e["hp"]) / float(e["max_hp"]), 0.0, 1.0), 4), Color("f57c79"))
            var cursor: Vector2 = get_global_mouse_position()
            var cursor_x: float = cursor.x
            var preview_lane: int = lane_for_y(cursor.y)
            var cursor_lane_y: float = FLOOR + float(LANE_OFFSETS[preview_lane])
            if dragging_tower and cursor.y < 548.0 and cursor_x >= 245.0 and cursor_x <= 1020.0:
                var range_radius: float = 260.0 if selected_build == "bone" else (375.0 if selected_build == "fire" else 0.0)
                var can_place: bool = mana >= (30 if selected_build == "bone" else (55 if selected_build == "fire" else 65))
                for placed_tower in towers:
                    if int(placed_tower.get("lane", 1)) == preview_lane and absf(float(placed_tower["x"]) - cursor_x) < 65.0:
                        can_place = false
                draw_line(Vector2(239.0, cursor_lane_y), Vector2(1125.0, cursor_lane_y), Color("c8e5a0", 0.75), 4.0)
                if range_radius > 0.0:
                    draw_arc(Vector2(cursor_x, cursor_lane_y - 67.0), range_radius, PI, TAU, 32, Color(0.48, 0.85, 0.69, 0.27) if can_place else Color(0.95, 0.30, 0.34, 0.22), 2.0)
                var preview_art: Texture2D = preload("res://assets/towers/bone_tower.svg") if selected_build == "bone" else (preload("res://assets/towers/infernal_ballista.svg") if selected_build == "fire" else preload("res://assets/towers/necromancer_tower.svg"))
                draw_texture_rect(preview_art, Rect2(cursor_x - 30.0, cursor_lane_y - 106.0, 60.0, 106.0), false, Color(0.68, 1.0, 0.72, 0.76) if can_place else Color(1.0, 0.38, 0.38, 0.72))
                label("МОЖНО ПОСТРОИТЬ" if can_place else "НЕТ МЕСТА / МАНЫ", clampf(cursor_x - 90.0, 245.0, 920.0), cursor_lane_y - 126.0, 15, Color("b8f1c0") if can_place else Color("ffaaa9"))
            draw_gothic_hud_panel(150.0)
            label("ФИНАЛЬНЫЙ ШТУРМ — %d с" % ceili(maxf(0.0, final_timer)) if phase == "final_siege" else "ДЕНЬ %d / 5  •  ОСАДА" % current_day, 25, 35, 27, Color("f8c59e"))
            var siege_status := "Ритуал: %02d с" % ceili(maxf(final_timer, 0.0)) if phase == "final_siege" else "До ночи: %02d с" % ceili(maxf(time_left, 0.0))
            label("%s    Мана: %d    Души: %d" % [siege_status, mana, souls], 25, 71, 22)
            if phase == "final_siege":
                box(Rect2(680, 84, 310, 13), Color("543c54"))
                box(Rect2(680, 84, 310.0 * clampf(1.0 - final_timer / 45.0, 0.0, 1.0), 13), Color("d8a6e8"))
                label("ЗАЩИЩАЙ АЛТАРЬ!", 700, 125, 18, Color("edc2f7"))
            box(Rect2(25, 82, 260, 13), Color("553840"))
            box(Rect2(25, 82, 260.0 * clampf(wall_hp / MAX_WALL, 0.0, 1.0), 13), Color("8cbe88") if wall_hp > 30.0 else Color("ed6b73"))
            label("Стены %d%%   •   Убийств %d   •   Врагов %d" % [ceili(wall_hp), kills_today, enemies.size()], 25, 126, 17)

            # RTS-style mouse palette: build cards and contextual tower inspection.
            box(Rect2(0.0, 551.0, W, 97.0), Color(0.08, 0.065, 0.13, 0.96))
            draw_line(Vector2(0, 551), Vector2(W, 551), Color("b59ab9"), 3.0)
            for card_index in range(3):
                var card_x: float = 14.0 + float(card_index) * 178.0
                var card_kind: String = "bone" if card_index == 0 else ("fire" if card_index == 1 else "necro")
                box(Rect2(card_x, 557.0, 170.0, 85.0), Color("4a394f") if selected_build == card_kind else Color("282536"))
                draw_rect(Rect2(card_x, 557.0, 170.0, 85.0), Color("d0b1d4") if selected_build == card_kind else Color("66586f"), false, 1.5)
                var card_art: Texture2D = preload("res://assets/towers/bone_tower.svg") if card_index == 0 else (preload("res://assets/towers/infernal_ballista.svg") if card_index == 1 else preload("res://assets/towers/necromancer_tower.svg"))
                draw_texture_rect(card_art, Rect2(card_x + 6.0, 565.0, 30.0, 48.0), false)
                label("КОСТЯНАЯ" if card_index == 0 else ("БАЛЛИСТА" if card_index == 1 else "НЕКРОМАНТ"), card_x + 42.0, 579.0, 15, Color("f4d2af"))
                label("30 маны" if card_index == 0 else ("55 маны" if card_index == 1 else "65 маны"), card_x + 42.0, 601.0, 15)
                label("Замедляет" if card_index == 0 else ("Крит + взрыв" if card_index == 1 else "Призывает скелетов"), card_x + 42.0, 624.0, 12, Color("a9dce2") if card_index == 0 else Color("ffbf8a"))
            box(Rect2(550.0, 557.0, 340.0, 85.0), Color("211e2d"))
            draw_rect(Rect2(550.0, 557.0, 340.0, 85.0), Color("66586f"), false, 1.5)
            if selected_tower_index >= 0 and selected_tower_index < towers.size():
                var inspected: Dictionary = towers[selected_tower_index]
                var level: int = int(inspected.get("level", 1))
                var tower_type: String = str(inspected["type"])
                var tower_name: String = "КОСТЯНАЯ" if tower_type == "bone" else ("БАЛЛИСТА" if tower_type == "fire" else "НЕКРОМАНТ")
                var damage: float = (22.0 if tower_type == "bone" else (65.0 if tower_type == "fire" else 0.0)) * (1.0 + 0.45 * float(level - 1)) * (1.35 if tower_power_level > 0 else 1.0)
                label("%s  •  УР. %d" % [tower_name, level], 562.0, 576.0, 15, Color("eed3b4"))
                label("HP %d/%d  •  Линия %d" % [ceili(float(inspected.get("hp", 0.0))), ceili(tower_max_hp(inspected)), int(inspected.get("lane", 1)) + 1], 562.0, 597.0, 14)
                label("Урон %d  •  Дальность %d" % [ceili(damage), 260 if tower_type == "bone" else (375 if tower_type == "fire" else 0)], 562.0, 617.0, 14)
                label(tower_ability_description(tower_type, level), 562.0, 636.0, 13, Color("a9dce2") if tower_type == "bone" else Color("ffbf8a"))
            else:
                label("ВЫБЕРИ БАШНЮ НА ПОЛЕ", 565.0, 589.0, 16, Color("d0c3d8"))
                label("HP • уровень • урон • способность", 565.0, 614.0, 13, Color("a59aaf"))
            box(Rect2(900.0, 557.0, 115.0, 85.0), Color("3d354b") if selected_tower_index >= 0 and selected_tower_index < towers.size() else Color("24222f"))
            draw_rect(Rect2(900.0, 557.0, 115.0, 85.0), Color("b89ac7") if selected_tower_index >= 0 and selected_tower_index < towers.size() else Color("51485c"), false, 1.5)
            if selected_tower_index >= 0 and selected_tower_index < towers.size():
                var level_for_button: int = int(towers[selected_tower_index].get("level", 1))
                label("УЛУЧШИТЬ" if level_for_button < 3 else "МАКС. УР.", 909.0, 588.0, 14, Color("f1d8ff"))
                label("%d маны" % (25 * level_for_button) if level_for_button < 3 else "3 / 3", 914.0, 614.0, 14)
            else:
                label("УЛУЧШИТЬ", 908.0, 588.0, 13, Color("8e8497"))
                label("Выбери башню", 906.0, 614.0, 11, Color("8e8497"))
            box(Rect2(1020.0, 557.0, 118.0, 85.0), Color("49303f") if selected_tower_index >= 0 and selected_tower_index < towers.size() else Color("24222f"))
            draw_rect(Rect2(1020.0, 557.0, 118.0, 85.0), Color("cf9d9d") if selected_tower_index >= 0 and selected_tower_index < towers.size() else Color("51485c"), false, 1.5)
            if selected_tower_index >= 0 and selected_tower_index < towers.size():
                label("ПРОДАТЬ", 1040.0, 588.0, 15, Color("f3c1bb"))
                label("+%d маны" % tower_sell_refund(towers[selected_tower_index]), 1036.0, 614.0, 14)
            else:
                label("ПРОДАТЬ", 1042.0, 588.0, 14, Color("8e8497"))
                label("Выбери башню", 1030.0, 614.0, 11, Color("8e8497"))
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
            if hurt_cooldown > 0.0 and sin(atmosphere_clock * 26.0) > 0.15:
                draw_rect(Rect2(player.x - 31.0, player.y - 57.0, 62.0, 83.0), Color(1.0, 0.29, 0.38, 0.35), false, 3.0)
            if swing_timer > 0.0:
                var swing_progress: float = 1.0 - swing_timer / 0.16
                var start_angle: float = -1.2 + swing_progress * 1.8 if facing > 0.0 else PI + 0.5 - swing_progress * 1.8
                draw_arc(player + Vector2(facing * 24.0, -14.0), 62.0, start_angle, start_angle + 1.0, 22, Color(0.85, 0.62, 1.0, 0.85), 7.0)
                draw_arc(player + Vector2(facing * 24.0, -14.0), 68.0, start_angle + 0.1, start_angle + 0.8, 18, Color(0.96, 0.87, 1.0, 0.48), 3.0)
            draw_gothic_hud_panel(156.0)
            label("НОЧЬ %d / 5  •  %s" % [current_day, "КАТАКОМБЫ" if current_day == 1 else ("ПРОКЛЯТАЯ УСЫПАЛЬНИЦА" if current_day == 2 else ("СОБОР СВЕТА" if current_day == 3 else ("КРОВАВЫЕ ШАХТЫ" if current_day == 4 else "ГРОБНИЦА ПЕРВОГО КОРОЛЯ")))], 25, 35, 27, Color("b9afea"))
            box(Rect2(24, 78, 260, 9), Color("413345"))
            box(Rect2(24, 78, 260.0 * clampf(player_hp / 100.0, 0.0, 1.0), 9), Color("dc6e83") if player_hp <= 25.0 else Color("b37fd2"))
            label("HP %d/100    Мана %d    Души %d    Камень %s" % [maxi(0, ceili(player_hp)), mana, souls, "ДА" if stone_taken else "НЕТ"], 25, 71, 21)
            label("ЛОВУШКИ", 25, 106, 15, Color("f38c95") if spike_phase >= 2.1 else Color("f1c780"))
            box(Rect2(105, 96, 180, 9), Color("383748"))
            box(Rect2(105, 96, 180.0 * clampf(spike_phase / 3.1, 0.0, 1.0), 9), Color("e8797a") if spike_phase >= 2.1 else Color("d9b67b"))
            if current_day == 1 and boss_hp > 0.0 and not stone_taken:
                label("ЦЕЛЬ: победи хранителя справа и забери Камень Бездны.", 25, 145, 16, Color("f4d29a"))
            elif boss_hp <= 0.0 and not stone_taken:
                label("ЦЕЛЬ: забери светящийся камень справа!", 25, 145, 17, Color("f4d29a"))
            elif stone_taken:
                label("ЦЕЛЬ: вернись с камнем к ПОРТАЛУ слева.", 25, 145, 17, Color("a8e9d0"))
            if player_hp > 0.0 and player_hp <= 25.0:
                var danger_blink: float = 0.60 + 0.40 * sin(atmosphere_clock * 8.0)
                box(Rect2(310, 212, 530, 43), Color(0.54, 0.09, 0.18, 0.40 + danger_blink * 0.40))
                label("КРИТИЧЕСКОЕ ЗДОРОВЬЕ! H — ЛЕЧЕНИЕ", 332, 240, 21, Color("ffe0dd"))
            label("ЛКМ: атака  •  A/D: движение  •  W/Space: прыжок  •  H: лечение  •  Shift: рывок", 20, 625, 17)
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
        var hit_center: Vector2 = impact["pos"]
        var ray_size: float = float(impact["radius"]) * (1.65 - fade * 0.5)
        for spark_index in range(6):
            var angle: float = TAU * float(spark_index) / 6.0 + atmosphere_clock * 0.7
            var direction: Vector2 = Vector2(cos(angle), sin(angle))
            draw_line(hit_center + direction * ray_size * 0.5, hit_center + direction * ray_size, effect_color, 2.0 * fade)
    for popup in damage_popups:
        var popup_alpha: float = clampf(float(popup["life"]) / float(popup["max_life"]), 0.0, 1.0)
        var popup_color: Color = popup["color"]
        popup_color.a = popup_alpha
        var popup_text: String = str(popup["text"])
        var popup_size: int = 17 if popup_text.begins_with("CRIT") else 15
        label(popup_text, float(popup["pos"].x) - (30.0 if popup_text.begins_with("CRIT") else 10.0), float(popup["pos"].y) - 9.0, popup_size, popup_color)
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
            pause_controls = "Карточки мышью — башни  |  R — ремонт стен (20 маны)"
        elif phase == "final_siege":
            pause_goal = "ЦЕЛЬ: продержись до завершения финального ритуала!"
            pause_controls = "Карточки мышью — башни  |  R — ремонт стен (20 маны)"
        elif phase == "night":
            pause_goal = "ЦЕЛЬ: вернись к порталу слева." if stone_taken else ("ЦЕЛЬ: забери камень справа." if boss_hp <= 0.0 else "ЦЕЛЬ: победи хранителя и забери камень.")
            pause_controls = "ЛКМ — атака  |  A/D — ходить  |  W/Space — прыгать"
        else:
            pause_goal = "ЦЕЛЬ: усиливай крепость и продолжай ритуал."
            pause_controls = "ЛКМ — улучшение / продолжение  |  C — обмен маны"
        label(pause_goal, 235, 278, 21, Color("f5d39e"))
        label(pause_controls, 235, 328, 18)
        if phase == "night":
            label("H — лечение (20 маны)  |  Shift — рывок (15 маны)", 235, 361, 18)
        label("M — фон  |  N — эффекты  |  P — продолжить", 235, 414, 20, Color("c9addd"))
