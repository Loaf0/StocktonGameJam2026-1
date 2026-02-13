extends Node

signal health_changed

const HURT_SFX = preload("res://assets/audio/hit_player.wav")

var sfx_volume : float = 1.0
var music_volume : float = 1.0

#show flashes on character to help time beats
var beat_assist : bool = true

#move player 2 to arrow keys
var two_player_mode : bool = false
var max_player_health : int = 3
var player_health : int = max_player_health

#ai + nav + collision
var occupied_cells : Dictionary = {}
var enemy_intent_cells : Dictionary = {}

# gameplay
var max_distance_tiles = 16
const max_score_multiplier = 6
var score_multiplier = 1
var curr_score = 0
var high_score = 0
var do_not_act : bool = false

var difficulty : float = 1.0

func add_score(value : int):
	curr_score += value * score_multiplier

#connect some signal to show when failed actions

func _ready() -> void:
	Save.load_settings()

func take_damage(damage_amt : int):
	player_health -= damage_amt
	health_changed.emit()
	_play_one_shot_sfx(HURT_SFX, 0.05, 0.0, 0.0,"SFX")
	if player_health <= 0:
		death()

func death():
	LevelTransition.death_fade("res://scenes/ui/death_menu.tscn", )

func _play_one_shot_sfx(sfx: AudioStream, pitch_range: float = 0.05, start_time: float = 0.0, volume_db: float = 0.0, bus_name: String = "SFX") -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = sfx
	player.bus = bus_name
	pitch_range = clamp(pitch_range, 0.0, 0.08)
	player.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	player.play(start_time)
