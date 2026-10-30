extends RefCounted
## Central source for base TD tower stats; keep values stable during refactor.
const COSTS := {"bone": 30, "fire": 45, "necro": 60}
const RANGES := {"bone": 135.0, "fire": 160.0, "necro": 125.0}
const DAMAGES := {"bone": 2, "fire": 1, "necro": 3}
const SPECIALIZATION_LABELS := {
    "bone": ["БАЛЛИСТА: +2 УРОН", "РОЙ: СКОРОСТЬ"],
    "fire": ["ИНФЕРНО: ПЛАМЯ", "ИСКРЫ: 3 ЦЕЛИ"],
    "necro": ["ЖНЕЦ: СИЛА ДУХОВ", "ЛЕГИОН: БОЛЬШЕ ДУХОВ"]
}

# Ordered catalogue shared by tower shop input and rendering.
const SHOP_ORDER := ["bone", "fire", "necro"]
const DISPLAY_NAMES := {"bone": "КОСТЯНАЯ", "fire": "ОГНЕННАЯ", "necro": "НЕКРОМАНТ"}
