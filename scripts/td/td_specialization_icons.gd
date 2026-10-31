extends RefCounted
## Static visual compatibility: gameplay still has four legacy IDs.
## Six original icon pairs already exist in assets/spire/towers.
const ASSET_IDS := {"bone": "ballista", "fire": "fire", "necro": "necro", "frost": "frost"}

static func path_for(kind: String, specialization: String) -> String:
    if not ASSET_IDS.has(kind) or not specialization in ["siege", "swarm"]:
        return ""
    return "res://assets/spire/towers/%s/specializations/%s/icon.svg" % [ASSET_IDS[kind], specialization]
