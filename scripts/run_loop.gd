extends Node2D
## First playable day/night run coordinator. Run-only upgrades persist between phases.
const NIGHT_SCENE: PackedScene = preload("res://scenes/topdown_night_prototype.tscn")
const TD_SCENE: PackedScene = preload("res://scenes/topdown_td_prototype.tscn")
const META_SCRIPT = preload("res://scripts/meta_progression.gd")
var meta = META_SCRIPT.new()
var phase := "hub" # hub, day, night, reward, victory, defeat
var phase_count := 0
var completed_phases := 0
var run_damage_bonus := 0
var run_speed_bonus := 0.0
var run_gold_bonus := 0
var run_fire_bonus := 0
var run_bone_tower_bonus := 0
var run_necro_kill_bonus := 0
var active_game: Node2D
var last_phase := "day"
const META_HERO_BUTTON := Rect2(270, 510, 260, 65)
const META_TREASURY_BUTTON := Rect2(620, 510, 260, 65)
const DAY_BUTTON := Rect2(240, 330, 280, 90)
const NIGHT_BUTTON := Rect2(630, 330, 280, 90)
const REWARD_BUTTONS := [Rect2(80, 370, 225, 100), Rect2(350, 370, 225, 100), Rect2(620, 370, 225, 100), Rect2(890, 370, 225, 100)]

func _ready() -> void:
    meta.load_profile()
    queue_redraw()

func expected_phase() -> String:
    return "day" if phase_count % 2 == 0 else "night"

func start_phase(kind: String) -> bool:
    if phase != "hub" or kind != expected_phase():
        return false
    if active_game != null:
        active_game.queue_free()
    if phase_count == 0:
        meta.record_start()
        meta.save_profile()
    last_phase = kind
    active_game = TD_SCENE.instantiate() if kind == "day" else NIGHT_SCENE.instantiate()
    add_child(active_game)
    if kind == "day":
        active_game.coins += run_gold_bonus + meta.treasury_level * 10
        active_game.fire_synergy_bonus = run_fire_bonus
        active_game.bone_synergy_bonus = run_bone_tower_bonus
        active_game.necro_kill_bonus = run_necro_kill_bonus
    else:
        active_game.attack_damage += run_damage_bonus + meta.hero_level
        active_game.attack_speed_multiplier += run_speed_bonus
    phase = kind
    queue_redraw()
    return true

func finish_phase(won: bool) -> void:
    if phase != "day" and phase != "night":
        return
    if active_game != null:
        active_game.queue_free()
        active_game = null
    if not won:
        phase = "defeat"
        meta.record_result(false)
    else:
        completed_phases += 1
        meta.record_phase_clear()
        meta.award(1)
        phase_count += 1
        phase = "victory" if phase_count >= 6 else "reward"
        if phase == "victory":
            meta.record_result(true)
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
        if expected_phase() == "day" and DAY_BUTTON.has_point(point):
            start_phase("day")
            get_viewport().set_input_as_handled()
        elif expected_phase() == "night" and NIGHT_BUTTON.has_point(point):
            start_phase("night")
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
    phase_count = 0
    completed_phases = 0
    run_damage_bonus = 0
    run_speed_bonus = 0.0
    run_gold_bonus = 0
    run_fire_bonus = 0
    run_bone_tower_bonus = 0
    run_necro_kill_bonus = 0
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1152, 648), Color("#141927"))
    draw_string(ThemeDB.fallback_font, Vector2(360, 105), "LAST RITUAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color("#e7d3a8"))
    match phase:
        "hub":
            draw_string(ThemeDB.fallback_font, Vector2(360, 210), "RUN %d / 6  |  Choose the next phase" % (phase_count + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
            var next_phase := expected_phase()
            draw_rect(DAY_BUTTON, Color("#527d70") if next_phase == "day" else Color("#343b47"))
            draw_rect(NIGHT_BUTTON, Color("#594d78") if next_phase == "night" else Color("#343b47"))
            draw_string(ThemeDB.fallback_font, Vector2(290, 382), "DAY: DEFEND" if next_phase == "day" else "DAY: COMPLETE", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
            draw_string(ThemeDB.fallback_font, Vector2(665, 382), "NIGHT: EXPLORE" if next_phase == "night" else "NIGHT: LOCKED", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
            draw_string(ThemeDB.fallback_font, Vector2(120, 455), "Run relics: +%d damage, +%d gold, +%d fire, +%d bone, +%d necro gold" % [run_damage_bonus, run_gold_bonus, run_fire_bonus, run_bone_tower_bonus, run_necro_kill_bonus], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#c7c9d1"))
            draw_string(ThemeDB.fallback_font, Vector2(390, 485), "SOUL FRAGMENTS: %d  (1 per completed phase)" % meta.fragments, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#e7d3a8"))
            draw_string(ThemeDB.fallback_font, Vector2(270, 602), "RUNS %d   WINS %d   LOSSES %d   CLEARED %d" % [meta.runs_started, meta.runs_won, meta.runs_lost, meta.phases_cleared], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#c7c9d1"))
            var badges := []
            if meta.achievement_unlocked("first_steps"):
                badges.append("FIRST STEPS")
            if meta.achievement_unlocked("survivor"):
                badges.append("SURVIVOR")
            if meta.achievement_unlocked("ritual_master"):
                badges.append("RITUAL MASTER")
            draw_string(ThemeDB.fallback_font, Vector2(270, 629), "ACHIEVEMENTS: " + (", ".join(badges) if not badges.is_empty() else "LOCKED"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e7d3a8"))
            draw_rect(META_HERO_BUTTON, Color("#526d9b") if meta.hero_level < 3 and meta.fragments >= meta.hero_level + 1 else Color("#343b47"))
            draw_rect(META_TREASURY_BUTTON, Color("#527d70") if meta.treasury_level < 3 and meta.fragments >= meta.treasury_level + 1 else Color("#343b47"))
            draw_string(ThemeDB.fallback_font, META_HERO_BUTTON.position + Vector2(9, 39), "HERO +1 DMG  Lv%d/3  %d FR" % [meta.hero_level, meta.hero_level + 1], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
            draw_string(ThemeDB.fallback_font, META_TREASURY_BUTTON.position + Vector2(9, 39), "DAY +10 GOLD  Lv%d/3  %d FR" % [meta.treasury_level, meta.treasury_level + 1], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
        "reward":
            draw_string(ThemeDB.fallback_font, Vector2(410, 235), "CHOOSE A RUN RELIC", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
            var names := ["BONE: +1 HERO/TOWER", "EMBER: SPEED + FIRE", "GOLD: +30 START GOLD", "NECRO: +3 KILL GOLD"]
            for i in range(REWARD_BUTTONS.size()):
                draw_rect(REWARD_BUTTONS[i], [Color("#526d9b"), Color("#a16a36"), Color("#927447"), Color("#4e7668")][i])
                draw_string(ThemeDB.fallback_font, REWARD_BUTTONS[i].position + Vector2(12, 55), names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
        "defeat", "victory":
            draw_string(ThemeDB.fallback_font, Vector2(400, 260), "RUN COMPLETE" if phase == "victory" else "RUN ENDED", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
            draw_string(ThemeDB.fallback_font, Vector2(400, 320), "Phases survived: %d / 6" % completed_phases, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#c7c9d1"))
            draw_rect(Rect2(430, 480, 290, 70), Color("#527d70"))
            draw_string(ThemeDB.fallback_font, Vector2(485, 523), "START NEW RUN", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
