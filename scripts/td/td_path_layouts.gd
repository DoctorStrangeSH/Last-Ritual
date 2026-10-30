extends RefCounted
## Deterministic layouts for a future per-run fortress map.
## Paths share the same entrances/exits and keep the current build slots safe.
const LAYOUTS := [
    [
        [Vector2(65, 285), Vector2(205, 285), Vector2(300, 260), Vector2(375, 302), Vector2(490, 263), Vector2(625, 292), Vector2(780, 260), Vector2(900, 295), Vector2(1070, 285)],
        [Vector2(65, 345), Vector2(200, 355), Vector2(325, 382), Vector2(425, 344), Vector2(550, 384), Vector2(705, 340), Vector2(845, 380), Vector2(950, 347), Vector2(1070, 345)]
    ],
    [
        [Vector2(65, 285), Vector2(185, 275), Vector2(275, 325), Vector2(355, 285), Vector2(475, 330), Vector2(595, 270), Vector2(715, 320), Vector2(875, 265), Vector2(1070, 285)],
        [Vector2(65, 345), Vector2(180, 370), Vector2(290, 345), Vector2(400, 395), Vector2(515, 342), Vector2(635, 390), Vector2(770, 335), Vector2(920, 390), Vector2(1070, 345)]
    ],
    [
        [Vector2(65, 285), Vector2(175, 315), Vector2(290, 255), Vector2(405, 315), Vector2(525, 262), Vector2(640, 315), Vector2(780, 255), Vector2(915, 315), Vector2(1070, 285)],
        [Vector2(65, 345), Vector2(175, 365), Vector2(295, 405), Vector2(410, 345), Vector2(525, 400), Vector2(665, 340), Vector2(805, 405), Vector2(945, 340), Vector2(1070, 345)]
    ]
]
static func layout_for_seed(seed_value: int) -> Array:
    return LAYOUTS[posmod(seed_value, LAYOUTS.size())].duplicate(true)
static func layout_count() -> int:
    return LAYOUTS.size()
