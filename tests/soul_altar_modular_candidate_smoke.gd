extends SceneTree
## Candidate pixel art QA. Candidate may be technically valid but is never approved/runtime-enabled.
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
    var original: Dictionary = contract.load_manifest("necro")
    check(not original.get("runtime_enabled", true), "Real production manifest is unchanged and disabled")
    check(original.get("base",{}).get("levels",{}).get("1","") == "base/level_1.png", "Candidate paths do not leak into production")
    print("Candidate art contract failures: %d" % failures)
    quit(1 if failures > 0 else 0)
