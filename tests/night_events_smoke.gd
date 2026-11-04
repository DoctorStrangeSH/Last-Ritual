extends SceneTree
## Night events: catalogue, per-floor variety and every option's effect.

const EVENTS = preload("res://scripts/night_events.gd")
const TROPHIES = preload("res://scripts/run_trophies.gd")
const NIGHT_SCENE = preload("res://scenes/topdown_night_prototype.tscn")
var failures := 0

func check(value: bool, description: String) -> void:
    if not value:
        failures += 1
        push_error("FAIL " + description)
    else:
        print("PASS " + description)

func _initialize() -> void:
    call_deferred("run")

## A night standing in its first event room, showing `kind`.
func at_event(kind: String, seed_value: int = 1101):
    var night = NIGHT_SCENE.instantiate()
    root.add_child(night)
    night.set_process(false)
    night.enable_floor_exploration(seed_value)
    night.event_override = kind
    for room in night.floor_data["rooms"]:
        if str(room["kind"]) == "СОБЫТИЕ":
            night.open_room(int(room["id"]))
            break
    night.player_hp = 60
    night.night_souls = 4
    return night

func drop(node) -> void:
    node.get_parent().remove_child(node)
    node.free()

func run() -> void:
    check(EVENTS.ORDER.size() == 4, "Four night events")
    for id in EVENTS.ORDER:
        check(EVENTS.title(id) != "" and EVENTS.text(id) != "" and EVENTS.options(id).size() == 3, "Event has title, text and three options: " + id)
    var icons := load(EVENTS.ICON_PATH) as Texture2D
    check(icons != null and icons.get_size() == Vector2(192, 48), "Event art strip holds four 48x48 frames")
    var seen := {}
    var repeats := false
    for floor_seed in range(200):
        seen[EVENTS.for_room(floor_seed, 0)] = true
        repeats = repeats or EVENTS.for_room(floor_seed, 0) == EVENTS.for_room(floor_seed, 1)
    check(seen.size() == 4, "Every event can be the first event of a night")
    check(not repeats, "Two event rooms on one night never show the same event")
    check(EVENTS.for_room(77, 1) == EVENTS.for_room(77, 1), "Event choice is deterministic")

    var night = NIGHT_SCENE.instantiate()
    root.add_child(night)
    night.set_process(false)
    night.enable_floor_exploration(1101)
    for room in night.floor_data["rooms"]:
        if str(room["kind"]) == "СОБЫТИЕ":
            night.open_room(int(room["id"]))
            check(night.shrine_open and EVENTS.CATALOG.has(night.event_kind), "An event room opens a catalogue event")
            break
    check(night.EVENT_ICONS != null, "Night keeps the event art alive")
    drop(night)

    # Grave: dig = souls + ambush that must be cleared like a fight.
    night = at_event("grave")
    var room_id: int = night.room_index
    check(night.choose_shrine_blessing(0) and night.night_souls == 4 + EVENTS.GRAVE_SOULS, "Digging the grave pays souls")
    check(night.enemies.size() == EVENTS.GRAVE_AMBUSH and not night.door_available() and not night.cleared_rooms.has(room_id), "The dead rise: an ambush blocks the doors")
    while night.enemies.size() > 1:
        night.enemies.remove_at(0)
    night.enemies[0]["hp"] = 1
    night.enemies[0]["pos"] = night.player_pos + Vector2(40, 0)
    night.attack(night.enemies[0]["pos"])
    check(night.reward_available and night.choose_relic("bone") and night.cleared_rooms.has(room_id), "Clearing the ambush gives a relic and clears the room")
    drop(night)
    night = at_event("grave")
    check(night.choose_shrine_blessing(1) and night.player_hp == 70 and night.cleared_rooms.has(night.room_index), "Praying at the grave heals 10")
    drop(night)

    # Fountain: drink trades health for souls, bathing trades souls for health.
    night = at_event("fountain")
    check(night.choose_shrine_blessing(0) and night.player_hp == 40 and night.night_souls == 4 + EVENTS.FOUNTAIN_DRINK_SOULS, "Drinking from the fountain: -20 HP, +6 souls")
    drop(night)
    night = at_event("fountain")
    check(night.choose_shrine_blessing(1) and night.player_hp == 90 and night.night_souls == 1, "Bathing: +30 HP for 3 souls")
    drop(night)
    night = at_event("fountain")
    night.night_souls = 2
    night.player_hp = 20
    check(not night.event_option_available(0) and not night.choose_shrine_blessing(0), "Cannot drink with 20 HP or less")
    check(not night.choose_shrine_blessing(1) and night.shrine_open, "Cannot bathe without 3 souls")
    check(night.choose_shrine_blessing(2) and not night.shrine_open, "Leaving the fountain always works")
    drop(night)

    # Mirror: gaze gives a trophy (blessing or curse); break trades health for damage.
    night = at_event("mirror")
    check(night.choose_shrine_blessing(0) and night.trophies_gained.size() == 1 and TROPHIES.is_valid(night.trophies_gained[0]), "Gazing into the mirror grants a trophy")
    drop(night)
    var blessings := 0
    var curses := 0
    for seed_value in range(1000, 1400, 7):
        night = at_event("mirror", seed_value)
        night.choose_shrine_blessing(0)
        if not night.trophies_gained.is_empty():
            if TROPHIES.is_curse(night.trophies_gained[0]):
                curses += 1
            else:
                blessings += 1
        drop(night)
    check(blessings > 10 and curses > 10, "The mirror is a real gamble (%d blessings, %d curses)" % [blessings, curses])
    night = at_event("mirror")
    night.trophies_owned.assign(TROPHIES.ORDER)
    check(night.choose_shrine_blessing(0) and night.trophies_gained.is_empty() and night.night_souls == 7, "An empty mirror pays 3 souls")
    drop(night)
    night = at_event("mirror")
    var damage: int = night.attack_damage
    check(night.choose_shrine_blessing(1) and night.attack_damage == damage + 2 and night.player_hp == 45, "Breaking the mirror: +2 damage, -15 HP")
    drop(night)

    # Altar keeps its old behaviour.
    night = at_event("altar")
    check(night.choose_shrine_blessing(0) and night.player_hp == 75, "Altar still heals 15")
    drop(night)
    night = at_event("altar")
    night.player_hp = 10
    check(not night.choose_shrine_blessing(1), "Altar still refuses the dark pact at 10 HP")
    drop(night)
    print("NIGHT EVENTS RESULT: ", "PASS" if failures == 0 else "FAIL")
    quit(1 if failures > 0 else 0)
