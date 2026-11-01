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
        var atlas_texture: Texture2D = load(atlas_path)
        check(atlas_texture != null, "Approved atlas imports as a Texture2D")
        if atlas_texture != null:
            check(atlas_texture.get_width() == 320 and atlas_texture.get_height() == 88, "Atlas uses five 64x88 frames")
            check(visuals.approved_necro_pixel_art_region(3, "siege").position.x == 192.0, "Reaper region is the fourth cell")
            check(visuals.approved_necro_pixel_art_region(3, "swarm").position.x == 256.0, "Legion region is the fifth cell")
    print("Soul Altar Pixel Art smoke failures: %d" % failures)
    quit(1 if failures > 0 else 0)
