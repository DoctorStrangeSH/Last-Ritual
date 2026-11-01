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

## Switchable preview gate: disable to instantly restore the original pulse art.
const NECRO_EXPERIMENTAL_ART := true
const NECRO_EXPERIMENTAL_ROOT := "res://assets/spire/towers/necro/experimental/"
## Frost art is still an experimental candidate. Flip false to restore Spark art.
const FROST_EXPERIMENTAL_ART := true
const FROST_EXPERIMENTAL_ROOT := "res://assets/spire/towers/frost/experimental/"

## Original detailed concept-derived PNGs are preferred only when the complete
## reviewed kit is actually committed. Never ship references to absent textures.
const NECRO_PRODUCTION_ROOT := "res://assets/spire/towers/necro/production/"

static func production_necro_ready() -> bool:
    for level in range(1, 4):
        if not ResourceLoader.exists(NECRO_PRODUCTION_ROOT + "level_%d_192.png" % level):
            return false
        if not ResourceLoader.exists(NECRO_PRODUCTION_ROOT + "level_%d_idle_8f.png" % level):
            return false
    for name in ["specialization_reaper_192.png", "specialization_legion_192.png", "soul_projectile_8f.png", "soul_impact_8f.png"]:
        if not ResourceLoader.exists(NECRO_PRODUCTION_ROOT + name):
            return false
    return true

static func production_necro_tower_path(level: int, specialization: String = "") -> String:
    if level < 1 or level > 3 or not production_necro_ready():
        return ""
    if level == 3 and specialization == "siege":
        return NECRO_PRODUCTION_ROOT + "specialization_reaper_192.png"
    if level == 3 and specialization == "swarm":
        return NECRO_PRODUCTION_ROOT + "specialization_legion_192.png"
    return NECRO_PRODUCTION_ROOT + "level_%d_192.png" % level

static func production_necro_idle_path(level: int) -> String:
    if level < 1 or level > 3 or not production_necro_ready():
        return ""
    return NECRO_PRODUCTION_ROOT + "level_%d_idle_8f.png" % level

static func uses_experimental_frost(kind: String) -> bool:
    return FROST_EXPERIMENTAL_ART and kind == "frost"

static func uses_experimental_necro(kind: String) -> bool:
    return NECRO_EXPERIMENTAL_ART and kind == "necro"

static func specialization_preview_path(kind: String, specialization: String) -> String:
    if not uses_experimental_necro(kind) or not ["siege", "swarm"].has(specialization):
        return ""
    return NECRO_EXPERIMENTAL_ROOT + "specialization_%s_level_3.png" % specialization

static func path_for(kind: String, level: int, layer: String) -> String:
    if uses_experimental_frost(kind) and level >= 1 and level <= 3 and ["base", "weapon"].has(layer):
        return FROST_EXPERIMENTAL_ROOT + "%s_level_%d.png" % [layer, level]
    if uses_experimental_necro(kind) and level >= 1 and level <= 3 and ["base", "weapon"].has(layer):
        return NECRO_EXPERIMENTAL_ROOT + "%s_level_%d.png" % [layer, level]
    if not FOLDERS.has(kind) or level < 1 or level > 3:
        return ""
    var root: String = "res://assets/spire/towers/%s/%s/level_%d/" % [FOLDERS[kind], layer, level]
    if layer == "base":
        return root + BASE_FILES[kind][level - 1]
    if layer == "weapon":
        return root + "%s - Level %02d - Weapon.png" % [WEAPON_PREFIX[kind], level]
    return ""

static func weapon_frame_region(kind: String) -> Rect2:
    if uses_experimental_frost(kind):
        return Rect2(0, 0, 128, 128)
    if uses_experimental_necro(kind):
        return Rect2(0, 0, 128, 128)
    if not WEAPON_CELL_WIDTH.has(kind):
        return Rect2()
    return Rect2(0, 0, float(WEAPON_CELL_WIDTH[kind]), float(WEAPON_CELL_HEIGHT[kind]))

## Return a valid atlas cell only when the texture actually contains it.
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
    if kind == "frost" and FROST_EXPERIMENTAL_ART and level >= 1 and level <= 3:
        if layer == "projectiles":
            return "res://assets/spire/towers/frost/vfx/ice_shard_projectile_8f.png"
        if layer == "weapon_impact":
            return "res://assets/spire/towers/frost/vfx/ice_burst_impact_8f.png"
    if kind == "necro" and level >= 1 and level <= 3 and production_necro_ready():
        if layer == "projectiles":
            return NECRO_PRODUCTION_ROOT + "soul_projectile_8f.png"
        if layer == "weapon_impact":
            return NECRO_PRODUCTION_ROOT + "soul_impact_8f.png"
    # Authored necromancer atlases are shared by all three upgrade levels.
    # Do not change base/weapon mapping or saved tower kinds.
    if kind == "necro" and level >= 1 and level <= 3:
        if layer == "projectiles":
            return "res://assets/spire/towers/necro/vfx/soul_projectile_8f.png"
        if layer == "weapon_impact":
            return "res://assets/spire/towers/necro/vfx/soul_impact_8f.png"
    if not FOLDERS.has(kind) or level < 1 or level > 3:
        return ""
    var root: String = "res://assets/spire/towers/%s/%s/level_%d/" % [FOLDERS[kind], layer, level]
    if layer == "projectiles":
        return root + (PROJECTILE_NAMES[kind] % level if kind != "fire" else PROJECTILE_NAMES[kind])
    if layer == "weapon_impact" and IMPACT_NAMES.has(kind):
        return root + (IMPACT_NAMES[kind] % level if kind == "frost" else IMPACT_NAMES[kind])
    return ""

static func vfx_frame_size(kind: String, layer: String) -> Vector2i:
    if kind == "frost" and FROST_EXPERIMENTAL_ART:
        if layer == "projectiles":
            return Vector2i(32, 32)
        if layer == "weapon_impact":
            return Vector2i(64, 64)
    if kind == "necro":
        if production_necro_ready():
            if layer == "projectiles":
                return Vector2i(128, 128)
            if layer == "weapon_impact":
                return Vector2i(128, 128)
        if layer == "projectiles":
            return Vector2i(32, 32)
        if layer == "weapon_impact":
            return Vector2i(64, 64)
    if layer == "projectiles":
        return PROJECTILE_CELL.get(kind, Vector2i.ZERO)
    if layer == "weapon_impact":
        return IMPACT_CELL.get(kind, Vector2i.ZERO)
    return Vector2i.ZERO
