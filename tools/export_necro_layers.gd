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
    var previous_base: Image = null
    var previous_weapon: Image = null
    for level in range(1, 4):
        var base_image: Image = read_svg("base_level_%d.svg" % level)
        var weapon_image: Image = read_svg("weapon_level_%d.svg" % level)
        if base_image == null or weapon_image == null:
            return 1
        if not has_transparency_and_painted_pixels(base_image) or not has_transparency_and_painted_pixels(weapon_image):
            push_error("Necro level %d must have transparent background and visible pixels" % level)
            return 1
        if previous_base != null and count_changed_pixels(previous_base, base_image) < 25:
            push_error("Necro base L%d visually duplicates the previous level" % level)
            return 1
        if previous_weapon != null and count_changed_pixels(previous_weapon, weapon_image) < 25:
            push_error("Necro weapon L%d visually duplicates the previous level" % level)
            return 1
        previous_base = base_image.duplicate()
        previous_weapon = weapon_image.duplicate()
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
                if count_changed_pixels(assembled, specialized) < 25:
                    push_error("Necro %s specialization is not distinguishable from base L3" % branch)
                    return 1
                if not save_checked_png(specialized, output_absolute.path_join("specialization_%s_level_3.png" % branch)):
                    return 1
                total += 1
    if not export_contact_sheet(output_absolute):
        return 1
    print("NECRO SOURCE PREVIEW: exported %d candidate PNGs + contact sheet; runtime and saves unchanged" % total)
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

## Detect accidental duplicated level exports or visually ineffective overlays.
## Compare packed pixel bytes after the same RGBA8 SVG rasterization path.
func count_changed_pixels(first: Image, second: Image) -> int:
    if first.get_size() != second.get_size():
        return 0
    var changed: int = 0
    for y in range(SIZE.y):
        for x in range(SIZE.x):
            if first.get_pixel(x, y) != second.get_pixel(x, y):
                changed += 1
    return changed

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

## Contact sheet (not a source sprite sheet): rows 1–3 = level, columns
## = base, weapon, assembled. Last row = Reaper, Legion. Source still SVG.
func export_contact_sheet(output_absolute: String) -> bool:
    const PITCH := 144
    const PAD := 8
    var gallery: Image = Image.create_empty(PITCH * 3, PITCH * 4, false, Image.FORMAT_RGBA8)
    gallery.fill(Color("#171821"))
    for row in range(4):
        for col in range(3):
            var background: Color = Color("#30313c") if (row + col) % 2 == 0 else Color("#242530")
            gallery.fill_rect(Rect2i(col * PITCH + 2, row * PITCH + 2, 140, 140), background)
            for gy in range(16):
                for gx in range(16):
                    if (gx + gy) % 2 == 0:
                        gallery.fill_rect(Rect2i(col * PITCH + PAD + gx * 8, row * PITCH + PAD + gy * 8, 8, 8), Color("#383a44"))
    var names: Array[String] = []
    for level in range(1, 4):
        names.append("base_level_%d.png" % level)
        names.append("weapon_level_%d.png" % level)
        names.append("assembled_level_%d.png" % level)
    names.append("specialization_siege_level_3.png")
    names.append("specialization_swarm_level_3.png")
    for index in range(names.size()):
        var tile: Image = Image.load_from_file(output_absolute.path_join(names[index]))
        if tile == null or tile.get_size() != SIZE:
            push_error("Contact sheet missing/invalid tile %s" % names[index])
            return false
        var col: int = index % 3
        var row: int = index / 3
        gallery.blend_rect(tile, Rect2i(Vector2i.ZERO, SIZE), Vector2i(col * PITCH + PAD, row * PITCH + PAD))
    var sheet_path: String = output_absolute.path_join("contact_sheet.png")
    if gallery.save_png(sheet_path) != OK:
        push_error("Cannot save contact sheet")
        return false
    var again: Image = Image.load_from_file(sheet_path)
    if again == null or again.get_size() != Vector2i(PITCH * 3, PITCH * 4):
        push_error("Invalid saved contact sheet")
        return false
    print("OK necro art contact sheet: %s" % sheet_path)
    return true
