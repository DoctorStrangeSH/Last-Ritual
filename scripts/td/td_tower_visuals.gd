extends RefCounted
## Asset-only mapping for four existing gameplay IDs. Do not change saved tower IDs.
const FOLDERS := {"bone": "ballista", "fire": "fire", "necro": "pulse", "frost": "spark"}
const BASE_FILES := {
    "bone": ["Tower 01.png", "Tower 02.png", "Tower 03.png"],
    "fire": ["Tower 02.png", "Tower 01.png", "Tower 03.png"],
    "necro": ["Tower 01.png", "Tower 02.png", "Tower 03.png"],
    "frost": ["Tower 01.png", "Tower 02.png", "Tower 03.png"]
}
const WEAPON_PREFIX := {
    "bone": "Tower 01",
    "fire": "Tower 07",
    "necro": "Tower 08",
    "frost": "Tower 04"
}
const WEAPON_CELL_WIDTH := {"bone": 96, "fire": 64, "necro": 48, "frost": 128}
const WEAPON_CELL_HEIGHT := {"bone": 96, "fire": 64, "necro": 48, "frost": 128}

static func path_for(kind: String, level: int, layer: String) -> String:
    if not FOLDERS.has(kind) or level < 1 or level > 3:
        return ""
    var root: String = "res://assets/spire/towers/%s/%s/level_%d/" % [FOLDERS[kind], layer, level]
    if layer == "base":
        return root + BASE_FILES[kind][level - 1]
    if layer == "weapon":
        return root + "%s - Level %02d - Weapon.png" % [WEAPON_PREFIX[kind], level]
    return ""

static func weapon_frame_region(kind: String) -> Rect2:
    if not WEAPON_CELL_WIDTH.has(kind):
        return Rect2()
    return Rect2(0, 0, float(WEAPON_CELL_WIDTH[kind]), float(WEAPON_CELL_HEIGHT[kind]))

## Return a valid atlas cell only when the texture actually contains it.
## A zero-sized Rect2 means the caller must not draw the sheet as a sprite.
static func first_frame_region(texture: Texture2D, cell_size: Vector2i) -> Rect2:
    if texture == null or cell_size.x <= 0 or cell_size.y <= 0:
        return Rect2()
    if texture.get_width() < cell_size.x or texture.get_height() < cell_size.y:
        return Rect2()
    return Rect2(Vector2.ZERO, Vector2(cell_size))

static func frame_region(texture: Texture2D, cell_size: Vector2i, frame_index: int) -> Rect2:
    if texture == null or cell_size.x <= 0 or cell_size.y <= 0 or frame_index < 0:
        return Rect2()
    var columns: int = texture.get_width() / cell_size.x
    var rows: int = texture.get_height() / cell_size.y
    if columns <= 0 or rows <= 0 or frame_index >= columns * rows:
        return Rect2()
    var column: int = frame_index % columns
    var row: int = frame_index / columns
    return Rect2(Vector2(column * cell_size.x, row * cell_size.y), Vector2(cell_size))

const PROJECTILE_NAMES := {
    "bone": "Tower 01 - Level %02d - Projectile.png",
    "fire": "Tower 07 - Level X - Projectile.png",
    "necro": "Tower 08 - Level %02d - Projectile.png",
    "frost": "Tower 04 - Level %02d - Projectile.png"
}
const IMPACT_NAMES := {
    "bone": "Tower 01 - Weapon - Impact.png",
    "fire": "Tower 07 - Level X - Projectile - Impact.png",
    "frost": "Tower 04 - Level %02d - Projectile - Impact.png"
}
# Source PNGs are sprite sheets: choose the first *cell*, not the whole sheet.
const PROJECTILE_CELL := {"bone": Vector2i(8, 8), "fire": Vector2i(32, 32), "necro": Vector2i(256, 256), "frost": Vector2i(8, 8)}
const IMPACT_CELL := {"bone": Vector2i(64, 64), "fire": Vector2i(64, 64), "frost": Vector2i(64, 64)}

static func vfx_path(kind: String, level: int, layer: String) -> String:
    if not FOLDERS.has(kind) or level < 1 or level > 3:
        return ""
    var root: String = "res://assets/spire/towers/%s/%s/level_%d/" % [FOLDERS[kind], layer, level]
    if layer == "projectiles":
        return root + (PROJECTILE_NAMES[kind] % level if kind != "fire" else PROJECTILE_NAMES[kind])
    if layer == "weapon_impact" and IMPACT_NAMES.has(kind):
        return root + (IMPACT_NAMES[kind] % level if kind == "frost" else IMPACT_NAMES[kind])
    return ""

static func vfx_frame_size(kind: String, layer: String) -> Vector2i:
    if layer == "projectiles":
        return PROJECTILE_CELL.get(kind, Vector2i.ZERO)
    if layer == "weapon_impact":
        return IMPACT_CELL.get(kind, Vector2i.ZERO)
    return Vector2i.ZERO
