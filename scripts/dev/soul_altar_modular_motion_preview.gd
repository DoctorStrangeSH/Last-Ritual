extends Node2D
## Isolated review-only scene. It never changes the production tower renderer.
## Run: godot --path . scenes/dev/soul_altar_modular_motion_preview.tscn

const MANIFEST_PATH := "res://assets/spire/towers/necro/candidate/manifest.json"
const ASSET_ROOT := "res://assets/spire/towers/necro/"
const CONTRACT := preload("res://scripts/td/td_modular_tower_assets.gd")
const FRAME_SIZE := Vector2(128.0, 128.0)
const PREVIEW_SCALE := 2.5
const TOWER_ORIGIN := Vector2(640.0, 410.0)
const GROUND_ANCHOR := Vector2(64.0, 118.0)
const WEAPON_PIVOT := Vector2(64.0, 90.0)
const SHOT_DURATION := 0.48
const DIRECTION_VECTORS := [
    Vector2.UP, Vector2(1, -1), Vector2.RIGHT, Vector2(1, 1),
    Vector2.DOWN, Vector2(-1, 1), Vector2.LEFT, Vector2(-1, -1)
]

var _manifest: Dictionary = {}
var _base_texture: Texture2D
var _weapon_texture: Texture2D
var _projectile_texture: Texture2D
var _impact_texture: Texture2D
var _projectile_frame_size := Vector2(32.0, 32.0)
var _impact_frame_size := Vector2(64.0, 64.0)
var _projectile_frame_count := 8
var _impact_frame_count := 8
var _projectile_fps := 24.0
var _impact_fps := 24.0
var _shot_active := false
var _impact_active := false
var _shot_elapsed := 0.0
var _impact_elapsed := 0.0
var _shot_origin := TOWER_ORIGIN
var _shot_target := TOWER_ORIGIN + Vector2.RIGHT * 240.0
var _level := 3
var _branch := "base"
var _elapsed := 0.0
var _target_position := TOWER_ORIGIN + Vector2(240.0, 0.0)
var _direction_index := 2
var _manual_direction := -1
var _show_alignment_guides := true
var _error_message := ""


func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    load_preview_assets()
    set_process(true)
    queue_redraw()


func load_preview_assets(manifest_path: String = MANIFEST_PATH) -> bool:
    _manifest.clear()
    _base_texture = null
    _weapon_texture = null
    _projectile_texture = null
    _impact_texture = null
    _shot_active = false
    _impact_active = false
    _error_message = ""

    var file := FileAccess.open(manifest_path, FileAccess.READ)
    if file == null:
        _set_error("Candidate manifest is missing: " + manifest_path)
        return false
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        _set_error("Candidate manifest is not a valid JSON dictionary")
        return false
    if bool(parsed.get("runtime_enabled", true)):
        _set_error("Review scene refuses a runtime-enabled candidate manifest")
        return false

    _manifest = parsed
    return _reload_selection()


func _reload_selection() -> bool:
    var levels: Dictionary = _manifest.get("base", {}).get("levels", {})
    var weapons: Dictionary = _manifest.get("weapon", {})
    if not levels.has(str(_level)) or not weapons.has(_branch):
        _set_error("Selected level or weapon branch is not present in the candidate manifest")
        return false

    var base_path := ASSET_ROOT + str(levels[str(_level)])
    var weapon_entry: Dictionary = weapons[_branch]
    var weapon_path := ASSET_ROOT + str(weapon_entry.get("path", ""))
    var projectiles: Dictionary = _manifest.get("projectiles", {})
    var impacts: Dictionary = _manifest.get("impacts", {})
    if not projectiles.has(_branch) or not impacts.has(_branch):
        _set_error("Candidate projectile or impact entry is missing for " + _branch)
        return false
    var projectile_entry: Dictionary = projectiles[_branch]
    var impact_entry: Dictionary = impacts[_branch]
    var projectile_path := ASSET_ROOT + str(projectile_entry.get("path", ""))
    var impact_path := ASSET_ROOT + str(impact_entry.get("path", ""))
    var base_candidate := load(base_path) as Texture2D
    var weapon_candidate := load(weapon_path) as Texture2D
    var projectile_candidate := load(projectile_path) as Texture2D
    var impact_candidate := load(impact_path) as Texture2D
    if base_candidate == null or weapon_candidate == null or projectile_candidate == null or impact_candidate == null:
        _set_error("Candidate base, weapon, projectile or impact texture is missing. Production art is untouched.")
        return false
    if base_candidate.get_size() != FRAME_SIZE:
        _set_error("Base texture must be 128x128")
        return false
    if weapon_candidate.get_size() != Vector2(1024.0, 128.0):
        _set_error("Weapon atlas must be 1024x128 (eight 128px frames)")
        return false

    var projectile_dimensions: Array = projectile_entry.get("frame_size", [32, 32])
    var impact_dimensions: Array = impact_entry.get("frame_size", [64, 64])
    var projectile_size := Vector2(float(projectile_dimensions[0]), float(projectile_dimensions[1]))
    var impact_size := Vector2(float(impact_dimensions[0]), float(impact_dimensions[1]))
    var projectile_count := int(projectile_entry.get("frame_count", 0))
    var impact_count := int(impact_entry.get("frame_count", 0))
    if projectile_count != 8 or impact_count != 8:
        _set_error("Candidate projectile and impact atlases must contain eight frames")
        return false
    if projectile_candidate.get_size() != Vector2(projectile_size.x * projectile_count, projectile_size.y):
        _set_error("Projectile atlas dimensions do not match its manifest")
        return false
    if impact_candidate.get_size() != Vector2(impact_size.x * impact_count, impact_size.y):
        _set_error("Impact atlas dimensions do not match its manifest")
        return false

    _base_texture = base_candidate
    _weapon_texture = weapon_candidate
    _projectile_texture = projectile_candidate
    _impact_texture = impact_candidate
    _projectile_frame_size = projectile_size
    _impact_frame_size = impact_size
    _projectile_frame_count = projectile_count
    _impact_frame_count = impact_count
    _projectile_fps = maxf(1.0, float(projectile_entry.get("fps", 24)))
    _impact_fps = maxf(1.0, float(impact_entry.get("fps", 24)))
    _error_message = ""
    queue_redraw()
    return true


func _process(delta: float) -> void:
    _elapsed += delta
    if _manual_direction < 0:
        _target_position = TOWER_ORIGIN + Vector2(
            cos(_elapsed * 0.72) * 245.0,
            sin(_elapsed * 0.51) * 170.0
        )
        _direction_index = preview_direction_for_target(_target_position)
    queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key := event as InputEventKey
    if not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_1:
            select_review_asset(1, _branch)
        KEY_2:
            select_review_asset(2, _branch)
        KEY_3:
            select_review_asset(3, _branch)
        KEY_B:
            select_review_asset(_level, "base")
        KEY_R:
            select_review_asset(_level, "reaper")
        KEY_L:
            select_review_asset(_level, "legion")
        KEY_KP_8:
            set_manual_direction(0)
        KEY_KP_9:
            set_manual_direction(1)
        KEY_KP_6:
            set_manual_direction(2)
        KEY_KP_3:
            set_manual_direction(3)
        KEY_KP_2:
            set_manual_direction(4)
        KEY_KP_1:
            set_manual_direction(5)
        KEY_KP_4:
            set_manual_direction(6)
        KEY_KP_7:
            set_manual_direction(7)
        KEY_A:
            resume_auto_target()
        KEY_H:
            _show_alignment_guides = not _show_alignment_guides
            queue_redraw()
        _:
            return


func select_review_asset(level: int, branch: String) -> bool:
    if level < 1 or level > 3 or not ["base", "reaper", "legion"].has(branch):
        return false
    _level = level
    _branch = branch
    return _reload_selection()


func set_manual_direction(index: int) -> void:
    _manual_direction = posmod(index, DIRECTION_VECTORS.size())
    _direction_index = _manual_direction
    _target_position = TOWER_ORIGIN + DIRECTION_VECTORS[_direction_index] * 245.0
    queue_redraw()


func resume_auto_target() -> void:
    _manual_direction = -1


func preview_direction_for_target(target: Vector2) -> int:
    return CONTRACT.direction_index(TOWER_ORIGIN, target)


func get_base_draw_rect() -> Rect2:
    return Rect2(
        TOWER_ORIGIN - GROUND_ANCHOR * PREVIEW_SCALE,
        FRAME_SIZE * PREVIEW_SCALE
    )


func get_weapon_draw_rect() -> Rect2:
    return Rect2(
        TOWER_ORIGIN - WEAPON_PIVOT * PREVIEW_SCALE,
        FRAME_SIZE * PREVIEW_SCALE
    )


func get_current_direction_index() -> int:
    return _direction_index


func get_tower_origin() -> Vector2:
    return TOWER_ORIGIN


func _set_error(message: String) -> void:
    _error_message = message
    _base_texture = null
    _weapon_texture = null
    queue_redraw()


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), Color("#100d19"))
    for x in range(0, 1280, 64):
        draw_line(Vector2(x, 0), Vector2(x, 720), Color("#211a2d"), 1.0)
    for y in range(0, 720, 64):
        draw_line(Vector2(0, y), Vector2(1280, y), Color("#211a2d"), 1.0)

    draw_string(ThemeDB.fallback_font, Vector2(32, 42), "LAST RITUAL  /  SOUL ALTAR MOTION REVIEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#f0d8ae"))
    draw_string(ThemeDB.fallback_font, Vector2(32, 72), "CANDIDATE ART ONLY  -  NOT USED BY THE GAME RENDERER", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#c39be8"))

    if _base_texture == null or _weapon_texture == null:
        draw_string(ThemeDB.fallback_font, Vector2(32, 130), "PREVIEW UNAVAILABLE: " + _error_message, HORIZONTAL_ALIGNMENT_LEFT, 1180, 18, Color("#ff8e9c"))
        return

    # The weapon pivot (64,90) and base ground anchor (64,118) meet at
    # the same world point. Therefore the weapon canvas starts 28px lower.
    draw_texture_rect(_base_texture, get_base_draw_rect(), false)
    var source := Rect2(float(_direction_index * 128), 0.0, 128.0, 128.0)
    draw_texture_rect_region(_weapon_texture, get_weapon_draw_rect(), source)

    if _show_alignment_guides:
        draw_rect(get_base_draw_rect(), Color("#75d9b0"), false, 1.5)
        draw_rect(get_weapon_draw_rect(), Color("#d9a5ff"), false, 1.5)
        draw_circle(TOWER_ORIGIN, 8.0, Color("#ffffff"))
        draw_arc(TOWER_ORIGIN, 14.0, 0.0, TAU, 24, Color("#ffffff"), 1.5)

    draw_line(TOWER_ORIGIN, _target_position, Color("#a879d7"), 2.0)
    draw_circle(_target_position, 13.0, Color("#ffcf74"))
    draw_arc(_target_position, 22.0, 0.0, TAU, 32, Color("#fff0bd"), 2.0)
    draw_circle(TOWER_ORIGIN, 5.0, Color("#ffffff"))

    var branch_label: String = str({"base": "Обычный Алтарь", "reaper": "Жнец", "legion": "Легион"}.get(_branch, _branch))
    draw_string(ThemeDB.fallback_font, Vector2(32, 630), "Уровень: %d    Оружие: %s    Направление: %s (%d)" % [_level, branch_label, CONTRACT.direction_name(_direction_index), _direction_index], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f0e8ff"))
    draw_string(ThemeDB.fallback_font, Vector2(32, 662), "1/2/3 — уровень     B — Алтарь     R — Жнец     L — Легион", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#c8bdd8"))
    draw_string(ThemeDB.fallback_font, Vector2(32, 684), "NumPad 8/9/6/3/2/1/4/7 — направление     A — авто     H — направляющие", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#c8bdd8"))
    draw_string(ThemeDB.fallback_font, Vector2(32, 706), "Review scene only. Approved production sprites and runtime manifest are unchanged.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#9e91ad"))
