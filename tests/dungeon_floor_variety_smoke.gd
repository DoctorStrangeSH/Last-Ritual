extends SceneTree
## Night floors: roles come from the graph's shape, and floors really differ.

const FLOOR = preload("res://scripts/dungeon_floor_graph.gd")
var failures := 0

func check(value: bool, description: String) -> void:
    if not value:
        failures += 1
        push_error("FAIL " + description)
    else:
        print("PASS " + description)

func _initialize() -> void:
    call_deferred("run")

func depths(floor_data: Dictionary) -> Dictionary:
    var result := {0: 0}
    var queue := [0]
    while not queue.is_empty():
        var id: int = queue.pop_front()
        for next_id in floor_data["rooms"][id]["neighbors"]:
            if not result.has(int(next_id)):
                result[int(next_id)] = int(result[id]) + 1
                queue.append(int(next_id))
    return result

func run() -> void:
    var seeds := 300
    var ok_shape := true
    var ok_roles := true
    var ok_boss := true
    var ok_secret := true
    var ok_entrance_neighbors := true
    var layouts := {}
    var second_elite := 0
    var second_event := 0
    var treasury_leaf := 0
    for seed in range(seeds):
        var floor_data: Dictionary = FLOOR.generate_floor(1000 + seed * 101)
        ok_shape = ok_shape and floor_data["rooms"].size() == 10 and FLOOR.reachable(floor_data) and floor_data == FLOOR.generate_floor(1000 + seed * 101)
        var count := {}
        var signature := ""
        for room in floor_data["rooms"]:
            count[room["kind"]] = int(count.get(room["kind"], 0)) + 1
            signature += str(room["kind"]).substr(0, 2)
        layouts[signature] = true
        for kind in ["ВХОД", "БОСС", "МАГАЗИН", "СОКРОВИЩНИЦА", "ТАЙНИК"]:
            ok_roles = ok_roles and int(count.get(kind, 0)) == 1
        var elites: int = int(count.get("ЭЛИТА", 0))
        var events: int = int(count.get("СОБЫТИЕ", 0))
        ok_roles = ok_roles and elites >= 1 and elites <= 2 and events >= 1 and events <= 2 and int(count.get("БОЙ", 0)) >= 2
        second_elite += 1 if elites == 2 else 0
        second_event += 1 if events == 2 else 0
        var depth := depths(floor_data)
        var boss: int = int(floor_data["boss"])
        for id in depth.keys():
            ok_boss = ok_boss and int(depth[id]) <= int(depth[boss])
        ok_boss = ok_boss and str(floor_data["rooms"][boss]["kind"]) == "БОСС" and floor_data["rooms"][boss]["neighbors"].size() == 1
        for room in floor_data["rooms"]:
            if str(room["kind"]) == "ТАЙНИК":
                ok_secret = ok_secret and room["neighbors"].size() == 1
            if str(room["kind"]) == "СОКРОВИЩНИЦА" and room["neighbors"].size() == 1:
                treasury_leaf += 1
            if str(room["kind"]) == "ЭЛИТА":
                ok_entrance_neighbors = ok_entrance_neighbors and not floor_data["rooms"][0]["neighbors"].has(int(room["id"]))
    check(ok_shape, "Every floor has 10 connected rooms and is reproducible by seed")
    check(ok_roles, "Every floor has exactly one entrance/boss/shop/treasury/secret, 1-2 elites, 1-2 events and at least 2 fights")
    check(ok_boss, "The boss waits in the farthest room, a dead end")
    check(ok_secret, "The secret room is always a dead end (never blocks the way)")
    check(treasury_leaf >= seeds * 9 / 10, "The treasury is a dead-end detour on almost every floor (%d/%d)" % [treasury_leaf, seeds])
    check(ok_entrance_neighbors, "No elite room right next to the entrance")
    check(layouts.size() >= seeds / 2, "Room layouts vary between floors (%d distinct of %d)" % [layouts.size(), seeds])
    check(second_elite > seeds * 15 / 100 and second_elite < seeds * 45 / 100, "About 30%% of floors hold a second elite (%d)" % second_elite)
    check(second_event > seeds * 25 / 100 and second_event < seeds * 60 / 100, "A second event appears on a good share of floors (%d)" % second_event)
    print("DUNGEON FLOOR VARIETY RESULT: ", "PASS" if failures == 0 else "FAIL")
    quit(1 if failures > 0 else 0)
