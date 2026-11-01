extends SceneTree
## Review-only preservation gate: no effect on the actual TD renderer.
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
    var path := "res://assets/spire/towers/necro/review/approved_assembled_5f.png"
    var texture := load(path) as Texture2D
    check(texture != null, "Review atlas loads")
    if texture != null:
        check(texture.get_size() == Vector2(320, 88), "Five 64x88 assembled frames")
        var image := texture.get_image()
        check(image != null and image.detect_alpha(), "Review source has alpha")
        if image != null:
            var fingerprints: Dictionary = {}
            for i in range(5):
                var transparent := false
                var visible := false
                var frame_bytes := PackedByteArray()
                for y in range(88):
                    for x in range(64):
                        var color := image.get_pixel(i * 64 + x, y)
                        var alpha := clampi(roundi(color.a * 255.0), 0, 255)
                        if alpha <= 1:
                            transparent = true
                            frame_bytes.append_array(PackedByteArray([0, 0, 0, 0]))
                        else:
                            visible = true
                            frame_bytes.append(clampi(roundi(color.r * 255.0), 0, 255))
                            frame_bytes.append(clampi(roundi(color.g * 255.0), 0, 255))
                            frame_bytes.append(clampi(roundi(color.b * 255.0), 0, 255))
                            frame_bytes.append(alpha)
                check(transparent and visible, "Assembled frame %d has transparent background and visible art" % i)
                var key := frame_bytes.hex_encode()
                check(not fingerprints.has(key), "Assembled frame %d is visually distinct" % i)
                fingerprints[key] = true
    var modular = load("res://scripts/td/td_modular_tower_assets.gd")
    var manifest: Dictionary = modular.load_manifest("necro")
    check(not modular.runtime_ready(manifest), "Review atlas never enables modular renderer")
    check(modular.missing_runtime_art(manifest).size() == 6, "Six modular base and weapon assets are still missing")
    quit(1 if failures > 0 else 0)
