extends SceneTree
## Dev tool: render a real TD frame to PNG (needs a GPU or software OpenGL, not --headless).
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --rendering-driver opengl3 --path . \
##       --script res://tools/capture_td_screenshot.gd -- --out=/tmp/td.png --seed=3 --mode=wave --art=1
##
## --mode=prep|omen|wave  --art=0|1 (force the pixel battlefield on)  --seed=N  --day=N
## Builds a small fortress so towers, pads and roads are all visible. Not used by CI.

var frames := 0
var out_path := "td_screenshot.png"

func _initialize() -> void:
    call_deferred("setup")

func option(name: String, fallback: String) -> String:
    for raw in OS.get_cmdline_user_args():
        if str(raw).begins_with("--" + name + "="):
            return str(raw).split("=", true, 1)[1]
    return fallback

func setup() -> void:
    out_path = option("out", out_path)
    var game = load("res://scenes/topdown_td_prototype.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.set_fortress_map_seed(int(option("seed", "3")))
    game.siege_day = int(option("day", "2"))
    if option("art", "0") == "1":
        game.set_battlefield_art_enabled(true)
    game.coins = 400
    for plan in [["necro", 0], ["fire", 2], ["bone", 5], ["frost", 6], ["necro", 3]]:
        game.choose_tower(plan[0])
        game.build_tower(plan[1])
    game.select_slot(0)
    for step in range(3):
        game.upgrade_selected()
    game.choose_specialization("swarm")
    game.selected_slot = -1
    match option("mode", "prep"):
        "prep", "omen":
            game.start_wave()
            game.enemies.clear()
            if option("mode", "prep") == "omen":
                game.request_wave_start()
        "wave":
            game.wave_number = 1
            var offers: Array = game.wave_omen_offers()
            game.choose_wave_omen(str(offers[0]["id"]) if not offers.is_empty() else "")
            for i in range(120):
                game.advance_enemies(0.05)
                game.attack_with_towers(0.05)
                game.update_shot_trails(0.02)
    game.queue_redraw()

func _process(_delta) -> bool:
    frames += 1
    if frames == 8:
        root.get_texture().get_image().save_png(out_path)
        print("saved ", out_path)
        return true
    return false
