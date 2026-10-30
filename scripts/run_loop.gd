extends Node2D
## First playable day/night run coordinator. Run-only upgrades persist between phases.
const NIGHT_SCENE: PackedScene = preload("res://scenes/topdown_night_prototype.tscn")
const TD_SCENE: PackedScene = preload("res://scenes/topdown_td_prototype.tscn")
const META_SCRIPT = preload("res://scripts/meta_progression.gd")
var meta = META_SCRIPT.new()
var audio_volume := 0.7
var audio_muted := false
var audio_settings_path := "user://last_ritual_audio.cfg"
var phase := "hub" # hub, day, transition, night, reward, victory, defeat
var transition_time := 0.0
const TRANSITION_DURATION := 1.25
var phase_count := 0
var difficulty := 0 # 0 normal, 1 hard, 2 nightmare
const DIFFICULTY_NAMES := ["НОРМА", "СЛОЖНО", "КОШМАР"]
const DIFFICULTY_BUTTONS := [Rect2(210, 242, 220, 55), Rect2(466, 242, 220, 55), Rect2(722, 242, 220, 55)]
var completed_phases := 0
var run_damage_bonus := 0
var run_speed_bonus := 0.0
var run_gold_bonus := 0
var run_fire_bonus := 0
var run_bone_tower_bonus := 0
var run_necro_kill_bonus := 0
var fortress_state: Dictionary = {}
var fortress_map_seed := 0
var pending_night_coins := 0
var active_game: Node2D
var last_phase := "day"
const META_HERO_BUTTON := Rect2(210, 510, 300, 65)
const META_TREASURY_BUTTON := Rect2(642, 510, 300, 65)
const START_RUN_BUTTON := Rect2(376, 337, 400, 85)
const REWARD_BUTTONS := [Rect2(80, 370, 225, 100), Rect2(350, 370, 225, 100), Rect2(620, 370, 225, 100), Rect2(890, 370, 225, 100)]
const AUDIO_MUTE_BUTTON := Rect2(810, 52, 96, 42)
const AUDIO_DOWN_BUTTON := Rect2(916, 52, 38, 42)
const AUDIO_UP_BUTTON := Rect2(962, 52, 38, 42)

func _ready() -> void:
    meta.load_profile()
    load_audio_settings()
    queue_redraw()

func load_audio_settings() -> void:
    var config := ConfigFile.new()
    if config.load(audio_settings_path) == OK:
        audio_volume = clampf(float(config.get_value("audio", "volume", 0.7)), 0.0, 1.0)
        audio_muted = bool(config.get_value("audio", "muted", false))
    apply_audio_settings()

func save_audio_settings() -> bool:
    var config := ConfigFile.new()
    config.set_value("audio", "volume", audio_volume)
    config.set_value("audio", "muted", audio_muted)
    return config.save(audio_settings_path) == OK

func apply_audio_settings() -> void:
    var master_bus := AudioServer.get_bus_index("Master")
    if master_bus < 0:
        return
    AudioServer.set_bus_mute(master_bus, audio_muted)
    AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(audio_volume, 0.001)))

func adjust_audio_volume(step: float) -> bool:
    var next_volume := clampf(audio_volume + step, 0.0, 1.0)
    if is_equal_approx(next_volume, audio_volume):
        return false
    audio_volume = next_volume
    apply_audio_settings()
    save_audio_settings()
    queue_redraw()
    return true

func toggle_audio_mute() -> void:
    audio_muted = not audio_muted
    apply_audio_settings()
    save_audio_settings()
    queue_redraw()

func set_difficulty(level: int) -> bool:
    if phase != "hub" or phase_count != 0 or level < 0 or level > 2:
        return false
    difficulty = level
    queue_redraw()
    return true

func expected_phase() -> String:
    return "day" if phase_count % 2 == 0 else "night"

func start_phase(kind: String) -> bool:
    if (phase != "hub" and phase != "transition") or kind != expected_phase():
        return false
    if active_game != null:
        active_game.queue_free()
    if phase_count == 0:
        meta.record_start()
        meta.save_profile()
    last_phase = kind
    active_game = TD_SCENE.instantiate() if kind == "day" else NIGHT_SCENE.instantiate()
    active_game.difficulty = difficulty
    add_child(active_game)
    if kind == "day":
        active_game.siege_day = mini(3, int(phase_count / 2) + 1)
        active_game.set_fortress_map_seed(fortress_map_seed)
        if not fortress_state.is_empty():
            active_game.import_fortress_state(fortress_state)
        active_game.coins += pending_night_coins
        pending_night_coins = 0
        active_game.coins += run_gold_bonus + meta.treasury_level * 10
        active_game.fire_synergy_bonus = run_fire_bonus
        active_game.bone_synergy_bonus = run_bone_tower_bonus
        active_game.necro_kill_bonus = run_necro_kill_bonus
    else:
        active_game.enable_floor_exploration(1000 + phase_count * 101 + difficulty * 13)
        active_game.attack_damage += run_damage_bonus + meta.hero_level
        active_game.attack_speed_multiplier += run_speed_bonus
    phase = kind
    queue_redraw()
    return true

func begin_transition() -> void:
    if phase != "day" and phase != "reward":
        return
    phase = "transition"
    transition_time = TRANSITION_DURATION
    queue_redraw()

func complete_transition() -> bool:
    if phase != "transition":
        return false
    transition_time = 0.0
    return start_phase(expected_phase())

func start_run() -> bool:
    if phase != "hub" or phase_count != 0:
        return false
    fortress_map_seed = randi()
    return start_phase("day")

func finish_phase(won: bool) -> void:
    # A phase can be resolved only once, and only while its scene exists.
    if (phase != "day" and phase != "night") or active_game == null:
        return
    if active_game != null:
        if won and phase == "day":
            fortress_state = active_game.export_fortress_state()
        elif won and phase == "night":
            pending_night_coins += int(active_game.night_souls) * 5
        active_game.queue_free()
        active_game = null
    if not won:
        phase = "defeat"
        meta.record_result(false)
    else:
        completed_phases += 1
        meta.record_phase_clear()
        meta.award(1 + difficulty)
        phase_count += 1
        if phase_count >= 6:
            phase = "victory"
            meta.record_result(true)
        elif expected_phase() == "night":
            begin_transition()
        else:
            phase = "reward"
    meta.save_profile()
    queue_redraw()

func choose_run_reward(kind: String) -> bool:
    if phase != "reward":
        return false
    match kind:
        "bone":
            run_damage_bonus += 1
            run_bone_tower_bonus += 1
        "ember":
            run_speed_bonus += 0.25
            run_fire_bonus += 1
        "gold":
            run_gold_bonus += 30
        "necro":
            run_necro_kill_bonus += 3
        _:
            return false
    begin_transition()
    return true

func _process(delta: float) -> void:
    if phase == "transition":
        transition_time -= delta
        if transition_time <= 0.0:
            complete_transition()
        return
    if active_game == null:
        return
    if phase == "day":
        if active_game.defense_state == "won":
            finish_phase(true)
        elif active_game.defense_state == "lost":
            finish_phase(false)
    elif phase == "night":
        if active_game.run_state == "won":
            finish_phase(true)
        elif active_game.run_state == "lost":
            finish_phase(false)

func _input(event: InputEvent) -> void:
    if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
        return
    var point: Vector2 = event.position
    if phase == "hub":
        if AUDIO_MUTE_BUTTON.has_point(point):
            toggle_audio_mute()
            get_viewport().set_input_as_handled()
            return
        if AUDIO_DOWN_BUTTON.has_point(point):
            adjust_audio_volume(-0.1)
            get_viewport().set_input_as_handled()
            return
        if AUDIO_UP_BUTTON.has_point(point):
            adjust_audio_volume(0.1)
            get_viewport().set_input_as_handled()
            return
        for i in range(DIFFICULTY_BUTTONS.size()):
            if DIFFICULTY_BUTTONS[i].has_point(point) and set_difficulty(i):
                get_viewport().set_input_as_handled()
                return
        if META_HERO_BUTTON.has_point(point) and meta.buy_upgrade("hero"):
            meta.save_profile()
            queue_redraw()
            get_viewport().set_input_as_handled()
            return
        if META_TREASURY_BUTTON.has_point(point) and meta.buy_upgrade("treasury"):
            meta.save_profile()
            queue_redraw()
            get_viewport().set_input_as_handled()
            return
        if START_RUN_BUTTON.has_point(point):
            start_run()
            get_viewport().set_input_as_handled()
    elif phase == "reward":
        for i in range(REWARD_BUTTONS.size()):
            if REWARD_BUTTONS[i].has_point(point):
                choose_run_reward(["bone", "ember", "gold", "necro"][i])
                get_viewport().set_input_as_handled()
                return
    elif phase == "defeat" or phase == "victory":
        if Rect2(430, 480, 290, 70).has_point(point):
            reset_run()
            get_viewport().set_input_as_handled()

func reset_run() -> void:
    if active_game != null:
        active_game.queue_free()
        active_game = null
    phase = "hub"
    transition_time = 0.0
    phase_count = 0
    difficulty = 0
    completed_phases = 0
    run_damage_bonus = 0
    run_speed_bonus = 0.0
    run_gold_bonus = 0
    run_fire_bonus = 0
    run_bone_tower_bonus = 0
    run_necro_kill_bonus = 0
    fortress_state.clear()
    fortress_map_seed = 0
    pending_night_coins = 0
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1152, 648), Color("#101521"))
    for x in [35.0, 1117.0]:
        draw_rect(Rect2(x - 14.0, 18, 28, 612), Color("#313946"))
        for y in range(30, 620, 80):
            draw_rect(Rect2(x - 19.0, y, 38, 13), Color("#646270"))
    draw_rect(Rect2(72, 32, 1008, 112), Color("#20283a"))
    draw_string(ThemeDB.fallback_font, Vector2(386, 83), "ПОСЛЕДНИЙ РИТУАЛ", HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color("#e7d3a8"))
    draw_string(ThemeDB.fallback_font, Vector2(355, 116), "ОБОРОНА КРЕПОСТИ И НОЧНЫЕ ВЫЛАЗКИ", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#9da9bf"))
    match phase:
        "transition":
            var coming_night: bool = expected_phase() == "night"
            var accent: Color = Color("#bb7691") if coming_night else Color("#e8be80")
            draw_rect(Rect2(144, 180, 864, 288), Color("#202838"))
            draw_rect(Rect2(144, 180, 864, 288), accent, false, 3.0)
            draw_circle(Vector2(576, 263), 47.0, accent)
            if coming_night:
                draw_circle(Vector2(597, 249), 42.0, Color("#202838"))
            draw_string(ThemeDB.fallback_font, Vector2(440, 365), "НАСТУПАЕТ НОЧЬ" if coming_night else "НАСТУПАЕТ РАССВЕТ", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#f2e4ca"))
            draw_string(ThemeDB.fallback_font, Vector2(355, 409), "Вперёд, к подземелью..." if coming_night else "Возвращение к обороне крепости...", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#b6c6d7"))
        "hub":
            draw_rect(AUDIO_MUTE_BUTTON, Color("#526d9b") if not audio_muted else Color("#754452"))
            draw_string(ThemeDB.fallback_font, AUDIO_MUTE_BUTTON.position + Vector2(8, 26), "ЗВУК ВКЛ" if not audio_muted else "ЗВУК ВЫКЛ", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
            draw_rect(AUDIO_DOWN_BUTTON, Color("#343b47"))
            draw_rect(AUDIO_UP_BUTTON, Color("#343b47"))
            draw_string(ThemeDB.fallback_font, AUDIO_DOWN_BUTTON.position + Vector2(13, 27), "-", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color.WHITE)
            draw_string(ThemeDB.fallback_font, AUDIO_UP_BUTTON.position + Vector2(13, 27), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color.WHITE)
            draw_string(ThemeDB.fallback_font, Vector2(810, 118), "ГРОМКОСТЬ %d%%" % roundi(audio_volume * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e7d3a8"))
            draw_rect(Rect2(72, 160, 1008, 299), Color("#1a2232"))
            draw_string(ThemeDB.fallback_font, Vector2(104, 198), "НОВЫЙ ЗАБЕГ", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#e7d3a8"))
            draw_string(ThemeDB.fallback_font, Vector2(104, 223), "3 дня обороны и 3 ночи в подземелье", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#b5c9d3"))
            draw_string(ThemeDB.fallback_font, Vector2(104, 273), "СЛОЖНОСТЬ", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d3c6ad"))
            for i in range(DIFFICULTY_BUTTONS.size()):
                draw_rect(DIFFICULTY_BUTTONS[i], Color("#906a3d") if difficulty == i else Color("#343b47"))
                draw_rect(DIFFICULTY_BUTTONS[i], Color("#d8c59b") if difficulty == i else Color("#606b75"), false, 2.0)
                draw_string(ThemeDB.fallback_font, DIFFICULTY_BUTTONS[i].position + Vector2(35, 35), DIFFICULTY_NAMES[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
            draw_rect(START_RUN_BUTTON, Color("#527d70"))
            draw_rect(START_RUN_BUTTON, Color("#b5dfbf"), false, 3.0)
            draw_string(ThemeDB.fallback_font, START_RUN_BUTTON.position + Vector2(91, 48), "НАЧАТЬ ЗАБЕГ", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color.WHITE)
            draw_string(ThemeDB.fallback_font, Vector2(245, 444), "День → ночь → награда → следующий день", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#c7d5d0"))
            draw_rect(Rect2(72, 474, 1008, 105), Color("#1a2232"))
            draw_string(ThemeDB.fallback_font, Vector2(100, 500), "УЛУЧШЕНИЯ МЕЖДУ ЗАБЕГАМИ", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#9da9bf"))
            draw_string(ThemeDB.fallback_font, Vector2(820, 500), "ОСКОЛКИ: %d" % meta.fragments, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#e7d3a8"))
            draw_rect(META_HERO_BUTTON, Color("#526d9b") if meta.hero_level < 3 and meta.fragments >= meta.hero_level + 1 else Color("#343b47"))
            draw_rect(META_TREASURY_BUTTON, Color("#527d70") if meta.treasury_level < 3 and meta.fragments >= meta.treasury_level + 1 else Color("#343b47"))
            draw_string(ThemeDB.fallback_font, META_HERO_BUTTON.position + Vector2(12, 39), "ГЕРОЙ +1 УРОН  %d/3  ЦЕНА %d" % [meta.hero_level, meta.hero_level + 1], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
            draw_string(ThemeDB.fallback_font, META_TREASURY_BUTTON.position + Vector2(12, 39), "ДЕНЬ +10 ЗОЛОТА  %d/3  ЦЕНА %d" % [meta.treasury_level, meta.treasury_level + 1], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
            draw_string(ThemeDB.fallback_font, Vector2(104, 606), "ИСТОРИЯ: ЗАБЕГИ %d  ПОБЕДЫ %d  ПОРАЖЕНИЯ %d  ЭТАПЫ %d" % [meta.runs_started, meta.runs_won, meta.runs_lost, meta.phases_cleared], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#c7c9d1"))
            var badges := []
            if meta.achievement_unlocked("first_steps"):
                badges.append("ПЕРВЫЕ ШАГИ +2")
            if meta.achievement_unlocked("survivor"):
                badges.append("ВЫЖИВШИЙ +4")
            if meta.achievement_unlocked("ritual_master"):
                badges.append("МАСТЕР РИТУАЛА +6")
            draw_string(ThemeDB.fallback_font, Vector2(104, 630), "ДОСТИЖЕНИЯ: " + (", ".join(badges) if not badges.is_empty() else "Проходите этапы для открытия"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e7d3a8"))
        "reward":
            draw_string(ThemeDB.fallback_font, Vector2(312, 226), "НОЧЬ ПРОЙДЕНА", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("#e7d3a8"))
            draw_string(ThemeDB.fallback_font, Vector2(312, 264), "Выберите усиление перед следующим днём", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#b5c9d3"))
            var names := ["КОСТИ", "УГОЛЬ", "ЗОЛОТО", "НЕКРОМАНТИЯ"]
            var descriptions := ["Герою +1 урон", "Герою +25% скорости атак", "Казна: +30 золота", "Некромант: +3 золота"]
            var details := ["Костяным башням +1 урон", "Огненным башням +1 урон", "В начале каждого дня", "За каждого убитого врага"]
            for i in range(REWARD_BUTTONS.size()):
                var card: Rect2 = REWARD_BUTTONS[i]
                draw_rect(card, [Color("#526d9b"), Color("#a16a36"), Color("#927447"), Color("#4e7668")][i])
                draw_rect(card, Color("#e3d2ac"), false, 2.0)
                draw_string(ThemeDB.fallback_font, card.position + Vector2(12, 33), names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
                draw_string(ThemeDB.fallback_font, card.position + Vector2(12, 61), descriptions[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#f4e9d9"))
                draw_string(ThemeDB.fallback_font, card.position + Vector2(12, 82), details[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#f4e9d9"))
            draw_rect(Rect2(237, 497, 680, 47), Color("#263b3c"))
            draw_string(ThemeDB.fallback_font, Vector2(255, 527), "После выбора награды следующий день начнётся сам", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d5e9df"))
        "defeat", "victory":
            draw_string(ThemeDB.fallback_font, Vector2(400, 260), "РИТУАЛ ЗАВЕРШЁН" if phase == "victory" else "ЗАБЕГ ОКОНЧЕН", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
            draw_string(ThemeDB.fallback_font, Vector2(400, 320), "Пройдено этапов: %d / 6" % completed_phases, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#c7c9d1"))
            draw_rect(Rect2(430, 480, 290, 70), Color("#527d70"))
            draw_string(ThemeDB.fallback_font, Vector2(485, 523), "НОВЫЙ ЗАБЕГ", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
