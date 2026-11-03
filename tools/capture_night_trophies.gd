extends SceneTree
## Dev tool: render the night elite-room trophy pick to PNG (needs xvfb + opengl3).
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --rendering-driver opengl3 --path . \
##       --script res://tools/capture_night_trophies.gd -- --out=/tmp/night.png --seed=1203
## Not used by CI.

var frames := 0
var out_path := "night_trophies.png"

func _initialize() -> void:
    call_deferred("setup")

func option(name: String, fallback: String) -> String:
    for raw in OS.get_cmdline_user_args():
        if str(raw).begins_with("--" + name + "="):
            return str(raw).split("=", true, 1)[1]
    return fallback

func setup() -> void:
    out_path = option("out", out_path)
    var night = load("res://scenes/topdown_night_prototype.tscn").instantiate()
    root.add_child(night)
    night.set_process(false)
    night.enable_floor_exploration(int(option("seed", "1203")))
    for room in night.floor_data["rooms"]:
        if str(room["kind"]) == "ЭЛИТА":
            night.open_room(int(room["id"]))
            break
    while night.enemies.size() > 1:
        night.enemies.remove_at(0)
    night.enemies[0]["hp"] = 1
    night.enemies[0]["pos"] = night.player_pos + Vector2(40, 0)
    night.attack(night.enemies[0]["pos"])
    night.reward_notice_time = 0.0
    night.queue_redraw()

func _process(_delta) -> bool:
    frames += 1
    if frames == 8:
        root.get_texture().get_image().save_png(out_path)
        print("saved ", out_path)
        return true
    return false
