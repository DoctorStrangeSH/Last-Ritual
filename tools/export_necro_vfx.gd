extends SceneTree
## Export eight-frame necromancer VFX candidate atlases from committed SVG sources.
## No runtime replacement. Godot 4.4.1 headless:
## godot --headless --path . --script res://tools/export_necro_vfx.gd

const SOURCE := "res://assets/spire/towers/necro/source/vfx/"
const OUTPUT := "res://build/art-preview/necro-vfx/"
const ITEMS := {
    "soul_projectile_8f": Vector2i(32, 32),
    "soul_impact_8f": Vector2i(64, 64)
}

func _initialize() -> void:
    quit(export_all())

func export_all() -> int:
    var absolute: String = ProjectSettings.globalize_path(OUTPUT)
    if DirAccess.make_dir_recursive_absolute(absolute) != OK:
        push_error("Could not create necro VFX output directory")
        return 1
    for kind in ITEMS:
        var cell: Vector2i = ITEMS[kind]
        var source_file: String = ProjectSettings.globalize_path(SOURCE + kind + ".svg")
        var data: PackedByteArray = FileAccess.get_file_as_bytes(source_file)
        if data.is_empty():
            push_error("Missing VFX source: %s" % source_file)
            return 1
        var atlas: Image = Image.new()
        var error: Error = atlas.load_svg_from_buffer(data)
        if error != OK or atlas.get_size() != Vector2i(cell.x * 8, cell.y):
            push_error("Invalid necro atlas: %s, error %d" % [kind, error])
            return 1
        atlas.convert(Image.FORMAT_RGBA8)
        var frame_signatures: Array[int] = []
        for frame in range(8):
            var section: Image = atlas.get_region(Rect2i(frame * cell.x, 0, cell.x, cell.y))
            var transparent: int = 0
            var opaque: int = 0
            for y in range(cell.y):
                for x in range(cell.x):
                    var a: float = section.get_pixel(x, y).a
                    if a <= 0.01:
                        transparent += 1
                    if a >= 0.5:
                        opaque += 1
            if transparent < 20 or opaque < 10:
                push_error("Empty or non-transparent VFX frame: %s:%d" % [kind, frame])
                return 1
            var signature: int = hash(section.get_data())
            if frame_signatures.has(signature):
                push_error("Duplicated VFX frame in %s: %d" % [kind, frame])
                return 1
            frame_signatures.append(signature)
        var output_file: String = absolute.path_join(kind + ".png")
        if atlas.save_png(output_file) != OK:
            push_error("Failed to write VFX atlas: %s" % output_file)
            return 1
        var result: Image = Image.load_from_file(output_file)
        if result == null or result.get_size() != Vector2i(cell.x * 8, cell.y):
            push_error("Invalid exported VFX PNG: %s" % output_file)
            return 1
        print("OK: %s 8 frames at %dx%d, with alpha" % [kind, cell.x, cell.y])
    return 0
