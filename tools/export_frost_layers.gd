extends SceneTree
## Candidate Frost Obelisk PNG exporter. No production art paths are touched.
const SRC := "res://assets/spire/towers/frost/source/layers/"
const OUT := "res://build/art-preview/frost/"
const SIZE := Vector2i(128, 128)

func _initialize() -> void:
    quit(export_all())

func export_all() -> int:
    var absolute: String = ProjectSettings.globalize_path(OUT)
    if DirAccess.make_dir_recursive_absolute(absolute) != OK:
        push_error("Cannot create frost preview output")
        return 1
    var previous_base: Image = null
    var previous_weapon: Image = null
    for level in range(1, 4):
        var base: Image = read_layer("base", level)
        var weapon: Image = read_layer("weapon", level)
        if base == null or weapon == null:
            return 1
        if not valid_layer(base) or not valid_layer(weapon):
            push_error("Frost source art has invalid alpha: level %d" % level)
            return 1
        if level > 1 and (changed_pixels(base, previous_base) < 25 or changed_pixels(weapon, previous_weapon) < 25):
            push_error("Frost levels must have distinguishable base and weapon art")
            return 1
        var assembled: Image = base.duplicate()
        assembled.blend_rect(weapon, Rect2i(Vector2i.ZERO, SIZE), Vector2i.ZERO)
        for key in ["base", "weapon", "assembled"]:
            var image: Image = base if key == "base" else weapon if key == "weapon" else assembled
            var path: String = absolute.path_join("%s_level_%d.png" % [key, level])
            if image.save_png(path) != OK:
                push_error("Cannot save frost PNG %s" % path)
                return 1
            var reloaded: Image = Image.load_from_file(path)
            if reloaded == null or not valid_layer(reloaded):
                push_error("Invalid exported frost PNG %s" % path)
                return 1
        previous_base = base
        previous_weapon = weapon
    print("FROST PREVIEW: 9 valid PNG candidates exported; no runtime art changed")
    return 0

func read_layer(kind: String, level: int) -> Image:
    var source: PackedByteArray = FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(SRC + "%s_level_%d.svg" % [kind, level]))
    if source.is_empty():
        push_error("Missing frost SVG")
        return null
    var image: Image = Image.new()
    if image.load_svg_from_buffer(source) != OK or image.get_size() != SIZE:
        push_error("Failed to parse frost SVG: %s L%d" % [kind, level])
        return null
    image.convert(Image.FORMAT_RGBA8)
    return image

func valid_layer(img: Image) -> bool:
    if img.get_size() != SIZE:
        return false
    var empty: int = 0
    var solid: int = 0
    for y in range(SIZE.y):
        for x in range(SIZE.x):
            var alpha: float = img.get_pixel(x, y).a
            if alpha < 0.01:
                empty += 1
            elif alpha > 0.5:
                solid += 1
    return empty > 100 and solid > 100

func changed_pixels(a: Image, b: Image) -> int:
    var result: int = 0
    for y in range(SIZE.y):
        for x in range(SIZE.x):
            if a.get_pixel(x, y) != b.get_pixel(x, y):
                result += 1
    return result
