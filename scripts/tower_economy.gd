extends RefCounted
## Pure tower sale refund calculation, independent of the game scene.

static func sell_refund(tower: Dictionary) -> int:
    var invested: int = 30 if tower["type"] == "bone" else (55 if tower["type"] == "fire" else 65)
    var level: int = int(tower.get("level", 1))
    for upgrade_step in range(1, level):
        invested += 25 * upgrade_step
    return int(floor(float(invested) * 0.5))
