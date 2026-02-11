extends Node

signal beat(beat_count: int)
signal phase_changed(phase: int)

@export var bpm: float = 120.0

#both players + enemies + attack all
const PHASES := 4

var beat_count := 0
var phase := -1

var _timer: Timer
var test_sfx = preload("res://assets/audio/beep.mp3")
var _audio_player: AudioStreamPlayer

func _ready():
	_timer = Timer.new()
	_timer.wait_time = 60.0 / bpm
	_timer.autostart = true
	_timer.timeout.connect(_on_beat)
	add_child(_timer)
	
	_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = test_sfx
	_audio_player.bus = "Music"
	add_child(_audio_player)

func _on_beat():
	beat_count += 1
	phase = (phase + 1) % PHASES
	
	emit_signal("beat", beat_count)
	emit_signal("phase_changed", phase)
	print("Beat : ", beat_count, " Phase : ", phase)
	
	if _audio_player.stream:
		var pitch_variation := 1.0
		match phase:
			0: pitch_variation = 1.0
			1: pitch_variation = 0.8
			2: pitch_variation = 0.9
			3: pitch_variation = 0.5
		_audio_player.pitch_scale = pitch_variation
		_audio_player.play(0.05)
