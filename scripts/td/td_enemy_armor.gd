extends RefCounted
## Tactical armor: only late-day brutes resist physical tower strikes.
## Fire magic remains the readable counter.
static func tower_hit_damage(role: String, kind: String, day: int, raw_damage: int) -> int:
    if role == "brute" and day >= 3 and kind != "fire":
        return maxi(1, raw_damage - 1)
    return maxi(1, raw_damage)
