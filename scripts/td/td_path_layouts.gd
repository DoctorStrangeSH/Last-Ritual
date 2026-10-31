extends RefCounted
## Per-run deterministic fortress road catalog. A run keeps its seed across all days.
## First three layouts are repaired to avoid crossing tower pads/overlapping lanes.
## New layouts add meaningful bends and three-lane assaults without new build slots.
const LAYOUTS := [
    [
        [Vector2(65, 285), Vector2(205, 285), Vector2(300, 260), Vector2(375, 302), Vector2(490, 263), Vector2(625, 292), Vector2(780, 260), Vector2(900, 295), Vector2(1070, 285)],
        [Vector2(65, 345), Vector2(200, 355), Vector2(325, 382), Vector2(425, 344), Vector2(550, 384), Vector2(705, 340), Vector2(845, 380), Vector2(950, 347), Vector2(1070, 345)]
    ],
    [
        [Vector2(65, 285), Vector2(185, 275), Vector2(275, 300), Vector2(355, 260), Vector2(475, 288), Vector2(595, 255), Vector2(715, 300), Vector2(875, 260), Vector2(1070, 285)],
        [Vector2(65, 345), Vector2(180, 370), Vector2(290, 350), Vector2(400, 395), Vector2(515, 355), Vector2(635, 390), Vector2(770, 360), Vector2(920, 395), Vector2(1070, 345)]
    ],
    [
        [Vector2(65, 285), Vector2(175, 305), Vector2(290, 255), Vector2(405, 295), Vector2(525, 262), Vector2(640, 275), Vector2(780, 255), Vector2(915, 295), Vector2(1070, 285)],
        [Vector2(65, 345), Vector2(175, 365), Vector2(295, 380), Vector2(410, 375), Vector2(525, 400), Vector2(665, 350), Vector2(805, 395), Vector2(945, 355), Vector2(1070, 345)]
    ],
    [
        [Vector2(65, 285), Vector2(165, 265), Vector2(260, 250), Vector2(360, 290), Vector2(480, 260), Vector2(600, 305), Vector2(720, 255), Vector2(860, 288), Vector2(955, 268), Vector2(1070, 285)],
        [Vector2(65, 345), Vector2(165, 365), Vector2(260, 388), Vector2(360, 355), Vector2(480, 390), Vector2(600, 355), Vector2(720, 385), Vector2(860, 350), Vector2(955, 374), Vector2(1070, 345)]
    ],
    [
        [Vector2(65, 285), Vector2(175, 305), Vector2(285, 270), Vector2(385, 290), Vector2(480, 315), Vector2(590, 260), Vector2(705, 278), Vector2(830, 310), Vector2(950, 268), Vector2(1070, 285)],
        [Vector2(65, 345), Vector2(175, 373), Vector2(285, 384), Vector2(385, 370), Vector2(480, 392), Vector2(590, 365), Vector2(705, 392), Vector2(830, 360), Vector2(950, 385), Vector2(1070, 345)]
    ],
    [
        [Vector2(65, 285), Vector2(155, 290), Vector2(265, 275), Vector2(375, 260), Vector2(485, 305), Vector2(605, 255), Vector2(735, 275), Vector2(855, 305), Vector2(975, 290), Vector2(1070, 285)],
        [Vector2(65, 345), Vector2(155, 380), Vector2(265, 365), Vector2(375, 385), Vector2(485, 375), Vector2(605, 390), Vector2(735, 365), Vector2(855, 385), Vector2(975, 365), Vector2(1070, 345)]
    ],
    [
        [Vector2(65, 285), Vector2(160, 270), Vector2(260, 260), Vector2(375, 255), Vector2(485, 275), Vector2(585, 265), Vector2(700, 250), Vector2(820, 260), Vector2(955, 275), Vector2(1070, 285)],
        [Vector2(65, 345), Vector2(160, 330), Vector2(260, 320), Vector2(375, 315), Vector2(485, 335), Vector2(585, 325), Vector2(700, 310), Vector2(820, 320), Vector2(955, 335), Vector2(1070, 345)],
        [Vector2(65, 405), Vector2(160, 390), Vector2(260, 380), Vector2(375, 375), Vector2(485, 395), Vector2(585, 385), Vector2(700, 370), Vector2(820, 380), Vector2(955, 395), Vector2(1070, 405)]
    ],
    [
        [Vector2(65, 285), Vector2(160, 272), Vector2(270, 260), Vector2(375, 264), Vector2(480, 259), Vector2(590, 265), Vector2(715, 257), Vector2(845, 261), Vector2(965, 272), Vector2(1070, 285)],
        [Vector2(65, 345), Vector2(160, 332), Vector2(270, 320), Vector2(375, 324), Vector2(480, 319), Vector2(590, 325), Vector2(715, 317), Vector2(845, 321), Vector2(965, 332), Vector2(1070, 345)],
        [Vector2(65, 405), Vector2(160, 392), Vector2(270, 380), Vector2(375, 384), Vector2(480, 379), Vector2(590, 385), Vector2(715, 377), Vector2(845, 381), Vector2(965, 392), Vector2(1070, 405)]
    ]
]
static func layout_for_seed(seed_value: int) -> Array:
    return LAYOUTS[posmod(seed_value, LAYOUTS.size())].duplicate(true)

static func layout_count() -> int:
    return LAYOUTS.size()
