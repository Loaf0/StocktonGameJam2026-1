extends Node

var sfx_volume : float = 1.0
var music_volume : float = 1.0

#show flashes on character to help time beats
var beat_assist : bool = true

#move player 2 to arrow keys
var two_player_mode : bool = false


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

func add_score(value : int):
	curr_score += value * score_multiplier

#connect some signal to show when failed actions

func _ready() -> void:
	Save.load_settings()
