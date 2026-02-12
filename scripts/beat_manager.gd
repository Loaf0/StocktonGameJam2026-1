extends Node

signal beat(beat_count: int)
signal phase_changed(phase: int)
const BASE_BPM = 140
@export var bpm: float = BASE_BPM

#both players + enemies + attack all
const PHASES := 4

var beat_count := 0
var phase := -1

var _timer: Timer
var test_sfx = preload("res://assets/audio/beep.mp3")
var game_music = preload("res://assets/audio/songs/groovin.wav")
var _audio_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer

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
	
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = game_music
	_music_player.bus = "Music"
	add_child(_music_player)

func _on_beat():
	beat_count += 1
	phase = (phase + 1) % PHASES
	
	emit_signal("beat", beat_count)
	emit_signal("phase_changed", phase)
	print("Beat : ", beat_count, " Phase : ", phase)
	
	# I HATE THIS NOISE!!!!! 😡 🐴
	#if _audio_player.stream:
		#var pitch_variation := 1.0
		#match phase:
			#0: pitch_variation = 1.0
			#1: pitch_variation = 0.8
			#2: pitch_variation = 0.9
			#3: pitch_variation = 0.5
		#_audio_player.pitch_scale = pitch_variation
		#_audio_player.play(0.05)

func start_song(new_bpm: float) -> void:
	_music_player.volume_db = 0
	
	bpm = new_bpm
	
	beat_count = 0
	phase = -1
	
	_timer.wait_time = 60.0 / bpm
	
	var pitch_scale := bpm / BASE_BPM
	_music_player.pitch_scale = pitch_scale
	
	_music_player.play()
	await get_tree().process_frame
	_timer.start()

func fade_music() -> void:
	var tween := create_tween()
	tween.parallel().tween_property(
		game_music,
		"volume_db",
		-80,
		0.5
	)
