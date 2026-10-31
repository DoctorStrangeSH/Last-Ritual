extends Node
## Small synthesized SFX so the prototype needs no external audio assets.
const SAMPLE_RATE := 22050
const EFFECTS := {
    "hit": {"frequency": 180.0, "duration": 0.09, "sweep": -90.0, "volume": 0.24},
    "kill": {"frequency": 520.0, "duration": 0.13, "sweep": -190.0, "volume": 0.20},
    "damage": {"frequency": 105.0, "duration": 0.18, "sweep": -55.0, "volume": 0.30},
    "relic": {"frequency": 660.0, "duration": 0.24, "sweep": 300.0, "volume": 0.20},
    "interrupt": {"frequency": 380.0, "duration": 0.22, "sweep": 440.0, "volume": 0.22},
    "blast": {"frequency": 85.0, "duration": 0.28, "sweep": -45.0, "volume": 0.30}
}
var _streams: Dictionary = {}
var _player: AudioStreamPlayer

func _ready() -> void:
    _player = AudioStreamPlayer.new()
    _player.bus = "Master"
    add_child(_player)
    for kind in EFFECTS:
        _streams[kind] = _make_stream(EFFECTS[kind])

func play_effect(kind: String) -> bool:
    if not EFFECTS.has(kind):
        return false
    if _player == null:
        return false
    _player.stream = _streams.get(kind)
    _player.play()
    return true

func _make_stream(spec: Dictionary) -> AudioStreamWAV:
    var count := int(float(spec["duration"]) * SAMPLE_RATE)
    var bytes := PackedByteArray()
    bytes.resize(count * 2)
    var frequency: float = spec["frequency"]
    var sweep: float = spec["sweep"]
    var volume: float = spec["volume"]
    for i in range(count):
        var t := float(i) / SAMPLE_RATE
        var progress := float(i) / maxf(1.0, float(count - 1))
        var envelope := pow(1.0 - progress, 1.8)
        var phase := TAU * (frequency * t + 0.5 * sweep * t * progress)
        var sample := sin(phase) * envelope * volume
        bytes.encode_s16(i * 2, int(clampi(roundi(sample * 32767.0), -32768, 32767)))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = SAMPLE_RATE
    stream.stereo = false
    stream.data = bytes
    return stream

func has_effect(kind: String) -> bool:
    return _streams.has(kind) and _streams[kind] is AudioStreamWAV and not (_streams[kind] as AudioStreamWAV).data.is_empty()
