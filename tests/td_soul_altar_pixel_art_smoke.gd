extends SceneTree

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
    var visuals = load("res://scripts/td/td_tower_visuals.gd")
    check(visuals != null, "Tower visual resolver loads")
    if visuals != null:
        check(visuals.approved_necro_pixel_art_ready(), "Approved Soul Altar Pixel Art atlas exists")
        var atlas_path: String = visuals.approved_necro_pixel_art_atlas_path()
        check(atlas_path == "res://assets/spire/towers/necro/production/pixel_art/soul_altar_approved_atlas.png", "Approved atlas path is stable")
        check(visuals.approved_necro_pixel_art_frame_index(1, "") == 0, "Level 1 maps to frame 0")
        check(visuals.approved_necro_pixel_art_frame_index(2, "") == 1, "Level 2 maps to frame 1")
        check(visuals.approved_necro_pixel_art_frame_index(3, "") == 2, "Level 3 maps to frame 2")
        check(visuals.approved_necro_pixel_art_frame_index(3, "siege") == 3, "Reaper maps to frame 3")
        check(visuals.approved_necro_pixel_art_frame_index(3, "swarm") == 4, "Legion maps to frame 4")
        check(visuals.approved_necro_pixel_art_frame_index(4, "") == -1, "Invalid level is rejected")
        var atlas_image: Image = Image.load_from_file(atlas_path)
        check(atlas_image != null, "Approved atlas imports as PNG")
        if atlas_image != null:
            check(atlas_image.get_size() == Vector2i(320, 88), "Atlas uses five 64x88 frames")
            check(atlas_image.has_alpha(), "Atlas has alpha transparency")
            check(atlas_image.get_pixel(0, 0).a == 0.0, "Atlas background is fully transparent")
            check(visuals.approved_necro_pixel_art_region(3, "siege").position.x == 192.0, "Reaper region is the fourth cell")
            check(visuals.approved_necro_pixel_art_region(3, "swarm").position.x == 256.0, "Legion region is the fifth cell")
        var td_scene = load("res://scenes/topdown_td_prototype.tscn")
        if td_scene != null:
            var td_game = td_scene.instantiate()
            root.add_child(td_game)
            check(td_game.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Top-down TD renders sprites with nearest-neighbour filtering")
            td_game.queue_free()
    print("Soul Altar Pixel Art smoke failures: %d" % failures)
    quit(1 if failures > 0 else 0)
