extends SceneTree
## Archived source QA. Candidate manifest stays disabled; production manifest controls the approved live kit.
var failures := 0

func check(ok: bool, description: String) -> void:
    if ok:
        print("PASS " + description)
    else:
        failures += 1
        push_error("FAIL " + description)

func _initialize() -> void:
    call_deferred("verify")

func verify() -> void:
    var path := "res://assets/spire/towers/necro/candidate/manifest.json"
    var file := FileAccess.open(path, FileAccess.READ)
    check(file != null, "Candidate manifest exists")
    if file == null:
        quit(1)
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    check(typeof(parsed) == TYPE_DICTIONARY, "Candidate manifest JSON is a dictionary")
    if typeof(parsed) != TYPE_DICTIONARY:
        quit(1)
        return
    var manifest: Dictionary = parsed
    var contract = load("res://scripts/td/td_modular_tower_assets.gd")
    check(bool(contract.validate_manifest(manifest).get("valid", false)), "Candidate follows modular contract")
    check(not bool(manifest.get("runtime_enabled", true)), "Candidate remains disabled")
    check(not contract.runtime_ready(manifest), "Candidate cannot turn on live game art")
    var missing: Array[String] = contract.missing_runtime_art(manifest)
    check(missing.is_empty(), "Three bases, three 8-way weapons and existing VFX meet technical readiness")
    for level in ["1", "2", "3"]:
        var base_path := "res://assets/spire/towers/necro/" + str(manifest["base"]["levels"][level])
        check(contract._transparent_png_ready(base_path, Vector2i(128,128), 1), "Candidate base level " + level)
    for branch in ["base","reaper","legion"]:
        var weapon_path := "res://assets/spire/towers/necro/" + str(manifest["weapon"][branch]["path"])
        check(contract._weapon_sheet_ready(weapon_path, Vector2i(128,128)), "Eight distinct candidate poses: " + branch)
    # Integration contract: all three bases and all three weapons must share
    # a 128px canvas, one pivot, one ground anchor, and stable layer positions.
    var canvas: Dictionary = manifest["canvas"]
    check(Vector2i(int(canvas["width"]), int(canvas["height"])) == Vector2i(128,128), "Layer canvas remains exactly 128x128")
    check(Vector2(canvas["pivot"][0], canvas["pivot"][1]) == Vector2(64,90), "Common weapon pivot remains stable")
    check(Vector2(canvas["ground_anchor"][0], canvas["ground_anchor"][1]) == Vector2(64,118), "Common base ground anchor remains stable")
    var origin := Vector2(400,300)
    var offsets := [Vector2.UP, Vector2(1,-1), Vector2.RIGHT, Vector2.ONE, Vector2.DOWN, Vector2(-1,1), Vector2.LEFT, Vector2(-1,-1)]
    var branches := {"": "base", "siege": "reaper", "swarm": "legion"}
    for specialization in branches:
        for level in range(1,4):
            for direction in range(8):
                var target: Vector2 = origin + offsets[direction] * 100.0
                var layers: Dictionary = contract.resolve_tower_layers(manifest, level, specialization, origin, target)
                check(not layers.is_empty(), "Resolve candidate layers L%d %s dir%d" % [level, specialization, direction])
                if layers.is_empty():
                    continue
                check(int(layers["weapon_frame"]) == direction, "Eight-way direction index matches aim")
                check(str(layers["branch"]) == str(branches[specialization]), "Combat specialization maps to correct weapon branch")
                check(layers["weapon_frame_size"] == Vector2i(128,128), "Layer uses shared canvas size")
                check(layers["pivot"] == Vector2(64,90), "Weapon pivot matches every base level")
                var weapon_texture := load(str(layers["weapon_path"])) as Texture2D
                var base_texture := load(str(layers["base_path"])) as Texture2D
                check(base_texture != null and base_texture.get_size() == Vector2(128,128), "Base texture alignment verified")
                check(weapon_texture != null and weapon_texture.get_size() == Vector2(1024,128), "Eight-frame weapon texture alignment verified")
    check(contract.resolve_tower_layers(manifest, 4, "", origin, origin + Vector2.RIGHT).is_empty(), "Invalid level cannot resolve layers")
    check(contract.resolve_tower_layers(manifest, 3, "invalid", origin, origin + Vector2.RIGHT).is_empty(), "Unknown specialization cannot resolve layers")
    var original: Dictionary = contract.load_manifest("necro")
    check(bool(original.get("runtime_enabled", false)), "Owner-approved production manifest enables modular runtime")
    check(original.get("base",{}).get("levels",{}).get("1","") == "base/level_1.png" and contract.runtime_ready(original), "Production manifest resolves only approved production paths")
    print("Candidate art contract failures: %d" % failures)
    quit(1 if failures > 0 else 0)
