extends SceneTree
## Headless SVG->PNG candidate preview exporter for three Necro art levels.
## Usage: godot --headless --path . --script res://tools/export_necro_layers.gd
## Exported PNG are QA candidates only: gameplay runtime paths remain unchanged.

const ROOT := "res://assets/spire/towers/necro/source/layers/"
const OUTPUT := "res://build/art-preview/necro/"
const SIZE := Vector2i(128, 128)

func _initialize() -> void:
    var code: int = run_export()
    quit(code)

func run_export() -> int:
    var output_absolute: String = ProjectSettings.globalize_path(OUTPUT)
    var dir_error: Error = DirAccess.make_dir_recursive_absolute(output_absolute)
    if dir_error != OK:
        push_error("Cannot create necro art-preview directory: %d" % dir_error)
        return 1
    var total: int = 0
    for level in range(1, 4):
        var base_image: Image = read_svg("base_level_%d.svg" % level)
        var weapon_image: Image = read_svg("weapon_level_%d.svg" % level)
        if base_image == null or weapon_image == null:
            return 1
        if not has_transparency_and_painted_pixels(base_image) or not has_transparency_and_painted_pixels(weapon_image):
            push_error("Necro level %d must have transparent background and visible pixels" % level)
            return 1
        if not save_checked_png(base_image, output_absolute.path_join("base_level_%d.png" % level)):
            return 1
        if not save_checked_png(weapon_image, output_absolute.path_join("weapon_level_%d.png" % level)):
            return 1
        var assembled: Image = base_image.duplicate()
        assembled.blend_rect(weapon_image, Rect2i(Vector2i.ZERO, SIZE), Vector2i.ZERO)
        if not has_transparency_and_painted_pixels(assembled):
            push_error("Necro assembled level %d has invalid alpha" % level)
            return 1
        if not save_checked_png(assembled, output_absolute.path_join("assembled_level_%d.png" % level)):
            return 1
        total += 3
        if level == 3:
            for branch in ["siege", "swarm"]:
                var overlay: Image = read_svg("specialization_%s.svg" % branch)
                if overlay == null or not has_transparency_and_painted_pixels(overlay):
                    push_error("Invalid necro specialization overlay: %s" % branch)
                    return 1
                var specialized: Image = assembled.duplicate()
                specialized.blend_rect(overlay, Rect2i(Vector2i.ZERO, SIZE), Vector2i.ZERO)
                if not save_checked_png(specialized, output_absolute.path_join("specialization_%s_level_3.png" % branch)):
                    return 1
                total += 1
    print("NECRO SOURCE PREVIEW: exported %d candidate PNGs; runtime and saves unchanged" % total)
    return 0

func read_svg(file_name: String) -> Image:
    var source_path: String = ProjectSettings.globalize_path(ROOT + file_name)
    if not FileAccess.file_exists(source_path):
        push_error("Missing necro source SVG: %s" % file_name)
        return null
    var bytes: PackedByteArray = FileAccess.get_file_as_bytes(source_path)
    var image: Image = Image.new()
    var error: Error = image.load_svg_from_buffer(bytes)
    if error != OK or image.get_size() != SIZE:
        push_error("Invalid necro SVG or dimensions: %s, error=%d" % [file_name, error])
        return null
    image.convert(Image.FORMAT_RGBA8)
    return image

func has_transparency_and_painted_pixels(image: Image) -> bool:
    if image.get_size() != SIZE:
        return false
    var transparent_count: int = 0
    var painted_count: int = 0
    for y in range(SIZE.y):
        for x in range(SIZE.x):
            var alpha: float = image.get_pixel(x, y).a
            if alpha <= 0.01:
                transparent_count += 1
            elif alpha >= 0.5:
                painted_count += 1
    return transparent_count > 100 and painted_count > 100

func save_checked_png(image: Image, path: String) -> bool:
    var save_error: Error = image.save_png(path)
    if save_error != OK:
        push_error("Failed to write PNG: %s (error=%d)" % [path, save_error])
        return false
    var reloaded: Image = Image.load_from_file(path)
    if reloaded == null or not has_transparency_and_painted_pixels(reloaded):
        push_error("Invalid reloaded PNG: %s" % path)
        return false
    print("OK source PNG candidate: %s" % path)
    return true
