extends SceneTree
## Prevent accidentally shipping a painted background as approved Pixel Art.
var failures := 0

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error("FAIL " + label)
	else:
		print("PASS " + label)

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var resolver = load("res://scripts/td/td_modular_tower_assets.gd")
	var manifest: Dictionary = resolver.load_manifest("necro")
	check(not manifest.is_empty(), "Soul Altar manifest loads")
	check(not resolver.runtime_ready(manifest), "Incomplete approved sprite set cannot enable live runtime")
	var tex_size := Vector2i(16, 16)
	var good := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	good.fill(Color(0, 0, 0, 0))
	good.fill_rect(Rect2i(3, 3, 10, 10), Color(0.8, 0.3, 1, 1))
	var bad := good.duplicate()
	bad.fill(Color("#682c89"))
	var dir_path := "user://soul_altar_gate/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var ok_path := dir_path + "valid.png"
	var bad_path := dir_path + "painted.png"
	check(good.save_png(ok_path) == OK, "Write transparent fixture")
	check(bad.save_png(bad_path) == OK, "Write painted-background fixture")
	# Call through a dedicated Image test helper: no Godot asset import needed.
	check(resolver._alpha_frame_valid(good, tex_size, 1), "Accept clean RGBA frame")
	check(not resolver._alpha_frame_valid(bad, tex_size, 1), "Reject painted opaque background")
	check(not resolver._alpha_frame_valid(good, Vector2i(8, 16), 1), "Reject wrong frame size")
	quit(1 if failures > 0 else 0)
