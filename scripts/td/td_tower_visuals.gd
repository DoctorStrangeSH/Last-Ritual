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
