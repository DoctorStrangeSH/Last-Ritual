extends RefCounted
## Specialization icon lookup.
## Legacy SVG icons were removed. Return an empty path until approved transparent
## Pixel Art PNG icons are committed; the UI keeps its Russian text labels meanwhile.

static func path_for(_kind: String, _specialization: String) -> String:
    return ""
