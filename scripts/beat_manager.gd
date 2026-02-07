extends Node

signal beat(beat_count: int)
signal phase_changed(phase: int)

@export var bpm: float = 120.0

#both players + enemies
const PHASES := 3

var beat_count := 0
var phase := 0

var _timer: Timer

func _ready():
	_timer = Timer.new()
	_timer.wait_time = 60.0 / bpm
	_timer.autostart = true
	_timer.timeout.connect(_on_beat)
	add_child(_timer)

func _on_beat():
	beat_count += 1
	phase = (phase + 1) % PHASES

	emit_signal("beat", beat_count)
	emit_signal("phase_changed", phase)
