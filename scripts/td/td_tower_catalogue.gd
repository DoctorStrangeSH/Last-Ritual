extends RefCounted
## Canonical six-tower design catalogue.
## Values for the four legacy gameplay IDs remain owned by TD_TOWER_STATS.
## New spark/pulse values are proposals until their combat implementation is merged.
const TOWERS := {
    "ballista": {
        "name": "КОСТЯНАЯ БАЛЛИСТА", "role": "Точный пробивной урон",
        "asset_id": "ballista", "legacy_id": "bone",
        "cost": 30, "range": 135.0, "damage": 2,
        "specializations": ["ОСАДНАЯ", "РОЙ КОСТЕЙ"],
        "status": "legacy_gameplay"
    },
    "fire": {
        "name": "ОГНЕННАЯ ТУРЕЛЬ", "role": "Урон по небольшой области",
        "asset_id": "fire", "legacy_id": "fire",
        "cost": 45, "range": 160.0, "damage": 1,
        "specializations": ["ИНФЕРНО", "ИСКРЫ"],
        "status": "legacy_gameplay"
    },
    "spark": {
        "name": "ИСКРОВОЙ РАЗРЯДНИК", "role": "Электрические цепные атаки",
        "asset_id": "spark", "legacy_id": "",
        "cost": 55, "range": 150.0, "damage": 2,
        "specializations": ["ЦЕПНАЯ МОЛНИЯ", "ПЕРЕГРУЗКА"],
        "status": "art_ready_combat_pending"
    },
    "pulse": {
        "name": "ИМПУЛЬСНЫЙ ИЗЛУЧАТЕЛЬ", "role": "Энергетические импульсы",
        "asset_id": "pulse", "legacy_id": "",
        "cost": 60, "range": 140.0, "damage": 2,
        "specializations": ["ГРАВИТАЦИЯ", "РЕЗОНАНС"],
        "status": "art_ready_combat_pending"
    },
    "necro": {
        "name": "АЛТАРЬ ДУШ", "role": "Некромантия и призыв духов",
        "asset_id": "necro", "legacy_id": "",
        "cost": 65, "range": 125.0, "damage": 3,
        "specializations": ["ЖНЕЦ", "ЛЕГИОН"],
        "status": "concept_only"
    },
    "frost": {
        "name": "ЛЕДЯНОЙ ОБЕЛИСК", "role": "Замедление и контроль",
        "asset_id": "frost", "legacy_id": "",
        "cost": 50, "range": 145.0, "damage": 1,
        "specializations": ["МОРОЗ", "МЕТЕЛЬ"],
        "status": "concept_only"
    }
}
const ORDER := ["ballista", "fire", "spark", "pulse", "necro", "frost"]

static func get_tower(id: String) -> Dictionary:
    return TOWERS.get(id, {}).duplicate(true)

static func is_combat_ready(id: String) -> bool:
    return str(TOWERS.get(id, {}).get("status", "")) == "legacy_gameplay"
