extends Node2D
## First playable day/night run coordinator. Run-only upgrades persist between phases.
const NIGHT_SCENE: PackedScene = preload("res://scenes/topdown_night_prototype.tscn")
const TD_SCENE: PackedScene = preload("res://scenes/topdown_td_prototype.tscn")
var phase := "hub" # hub, day, night, reward, victory, defeat
var phase_count := 0
var completed_phases := 0
var run_damage_bonus := 0
var run_speed_bonus := 0.0
var run_gold_bonus := 0
var active_game: Node2D
var last_phase := "day"
const DAY_BUTTON := Rect2(240, 330, 280, 90)
const NIGHT_BUTTON := Rect2(630, 330, 280, 90)
const REWARD_BUTTONS := [Rect2(170, 370, 250, 100), Rect2(450, 370, 250, 100), Rect2(730, 370, 250, 100)]

func _ready() -> void:
    queue_redraw()

func start_phase(kind: String) -> bool:
    if kind != "day" and kind != "night":
        return false
    if active_game != null:
        active_game.queue_free()
    last_phase = kind
    active_game = TD_SCENE.instantiate() if kind == "day" else NIGHT_SCENE.instantiate()
    add_child(active_game)
    if kind == "day":
        active_game.coins += run_gold_bonus
    else:
        active_game.attack_damage += run_damage_bonus
        active_game.attack_speed_multiplier += run_speed_bonus
    phase = kind
    queue_redraw()
    return true

func finish_phase(won: bool) -> void:
    if active_game != null:
        active_game.queue_free()
        active_game = null
    if not won:
        phase = "defeat"
    else:
        completed_phases += 1
        phase_count += 1
        phase = "victory" if phase_count >= 4 else "reward"
    queue_redraw()

func choose_run_reward(kind: String) -> bool:
    if phase != "reward":
        return false
    match kind:
        "bone":
            run_damage_bonus += 1
        "ember":
            run_speed_bonus += 0.25
        "gold":
            run_gold_bonus += 30
        _:
            return false
    phase = "hub"
    queue_redraw()
    return true

func _process(_delta: float) -> void:
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
        if DAY_BUTTON.has_point(point):
            start_phase("day")
            get_viewport().set_input_as_handled()
        elif NIGHT_BUTTON.has_point(point):
            start_phase("night")
            get_viewport().set_input_as_handled()
    elif phase == "reward":
        for i in range(REWARD_BUTTONS.size()):
            if REWARD_BUTTONS[i].has_point(point):
                choose_run_reward(["bone", "ember", "gold"][i])
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
    phase_count = 0
    completed_phases = 0
    run_damage_bonus = 0
    run_speed_bonus = 0.0
    run_gold_bonus = 0
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1152, 648), Color("#141927"))
    draw_string(ThemeDB.fallback_font, Vector2(360, 105), "LAST RITUAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color("#e7d3a8"))
    match phase:
        "hub":
            draw_string(ThemeDB.fallback_font, Vector2(360, 210), "RUN %d / 4  |  Choose the next phase" % (phase_count + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
            draw_rect(DAY_BUTTON, Color("#527d70"))
            draw_rect(NIGHT_BUTTON, Color("#594d78"))
            draw_string(ThemeDB.fallback_font, Vector2(290, 382), "DAY: DEFEND", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
            draw_string(ThemeDB.fallback_font, Vector2(665, 382), "NIGHT: EXPLORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
            draw_string(ThemeDB.fallback_font, Vector2(300, 490), "Relics carried: +%d damage, +%d gold" % [run_damage_bonus, run_gold_bonus], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#c7c9d1"))
        "reward":
            draw_string(ThemeDB.fallback_font, Vector2(410, 235), "CHOOSE A RUN RELIC", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
            var names := ["BONE: +1 DAMAGE", "EMBER: +25% SPEED", "GOLD: +30 START GOLD"]
            for i in range(REWARD_BUTTONS.size()):
                draw_rect(REWARD_BUTTONS[i], [Color("#526d9b"), Color("#a16a36"), Color("#927447")][i])
                draw_string(ThemeDB.fallback_font, REWARD_BUTTONS[i].position + Vector2(12, 55), names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
        "defeat", "victory":
            draw_string(ThemeDB.fallback_font, Vector2(400, 260), "RUN COMPLETE" if phase == "victory" else "RUN ENDED", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
            draw_string(ThemeDB.fallback_font, Vector2(400, 320), "Phases survived: %d / 4" % completed_phases, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#c7c9d1"))
            draw_rect(Rect2(430, 480, 290, 70), Color("#527d70"))
            draw_string(ThemeDB.fallback_font, Vector2(485, 523), "START NEW RUN", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
