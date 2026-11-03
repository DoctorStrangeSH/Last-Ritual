extends SceneTree
## Pixel-art battlefield: manifest gate, road geometry and seeded prop placement.

const ART = preload("res://scripts/td/td_battlefield_art.gd")
const MAP = preload("res://scripts/td/td_run_map_generator.gd")
var failures := 0

func check(value: bool, description: String) -> void:
    if not value:
        failures += 1
        push_error("FAIL " + description)
    else:
        print("PASS " + description)

func _initialize() -> void:
    call_deferred("run_tests")

func run_tests() -> void:
    var manifest: Dictionary = ART.load_manifest()
    check(not manifest.is_empty(), "Battlefield manifest loads")
    check(ART.missing_textures(manifest).is_empty(), "Every battlefield texture referenced by the manifest exists")
    check(str(manifest.get("status", "")) == "review_candidate" and not bool(manifest.get("runtime_enabled", true)), "Candidate art stays disabled until owner approval")
    check(not ART.runtime_ready(manifest), "Runtime gate is closed while runtime_enabled=false")
    var forced: Dictionary = manifest.duplicate(true)
    forced["runtime_enabled"] = true
    check(ART.runtime_ready(forced), "Gate opens once enabled with a complete texture set")
    var broken: Dictionary = forced.duplicate(true)
    broken["textures"]["road"] = "missing.png"
    check(not ART.runtime_ready(broken) and ART.missing_textures(broken) == ["road"], "A missing texture keeps the gate closed and is reported")

    for key in ["ground", "road", "pad_empty", "pad_built", "altar", "props", "gate", "wall"]:
        var texture := load(ART.texture_path(manifest, key)) as Texture2D
        check(texture != null, "Texture loads: " + key)
    var props := load(ART.texture_path(manifest, "props")) as Texture2D
    check(props != null and props.get_size() == Vector2(ART.PROP_SIZE * ART.PROP_COUNT, ART.PROP_SIZE), "Prop strip holds 8 frames of 32x32")

    var path := [Vector2(0, 0), Vector2(100, 0), Vector2(100, 80), Vector2(100, 80)]
    var quads: Array = ART.road_quads(path, 26.0)
    check(quads.size() == 2, "Road quads skip zero-length segments")
    check(is_equal_approx((quads[0][0] as Vector2).distance_to(quads[0][3]), 26.0), "Road quad has the requested width")
    check(ART.uvs_for(PackedVector2Array([Vector2(64, 128)]), 64.0)[0] == Vector2(1, 2), "UVs are world pixels divided by tile size")

    var all_clear := true
    var all_deterministic := true
    var enough := true
    for seed_value in range(128):
        var generated: Dictionary = MAP.generate_map(seed_value)
        var altar := Vector2(1041, 314)
        var layout: Array = ART.prop_layout(seed_value, generated["paths"], generated["slots"], altar)
        all_deterministic = all_deterministic and layout == ART.prop_layout(seed_value, generated["paths"], generated["slots"], altar)
        enough = enough and layout.size() >= 8
        for prop in layout:
            var pos: Vector2 = prop["pos"]
            for lane in generated["paths"]:
                all_clear = all_clear and ART.distance_to_path(pos, lane) >= 36.0
            for slot_pos in generated["slots"]:
                all_clear = all_clear and not Rect2(Vector2(slot_pos) + Vector2(-58, -112), Vector2(116, 160)).has_point(pos)
            all_clear = all_clear and pos.distance_to(altar) >= 80.0 and ART.FIELD.has_point(pos)
            all_clear = all_clear and int(prop["frame"]) >= 0 and int(prop["frame"]) < ART.PROP_COUNT
    check(all_deterministic, "Prop layout is reproducible for 128 map seeds")
    check(enough, "Every map gets at least 8 decorative props")
    check(all_clear, "Props never touch roads, tower silhouettes, the altar or leave the field")

    var scene: PackedScene = load("res://scenes/topdown_td_prototype.tscn")
    var game = scene.instantiate()
    root.add_child(game)
    check(not game.battlefield_art_enabled, "Live game keeps the procedural battlefield while the candidate is disabled")
    game.set_battlefield_art_enabled(true)
    check(game.battlefield_art_enabled and game.texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED and game.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Preview toggle enables crisp, tiling pixel art")
    check(game.battlefield_props.size() >= 8, "Scene computes props for its seeded map")
    game.set_battlefield_art_enabled(false)
    check(not game.battlefield_art_enabled and game.texture_filter == CanvasItem.TEXTURE_FILTER_PARENT_NODE, "Toggle restores the original rendering")
    game.queue_free()

    print("TD BATTLEFIELD ART RESULT: ", "PASS" if failures == 0 else str(failures) + " FAILURES")
    quit(0 if failures == 0 else 1)
