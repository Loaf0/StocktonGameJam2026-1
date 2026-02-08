extends Node

#show flashes on character to help time beats
var beat_assist : bool = true

#move player 2 to arrow keys
var two_player_mode : bool = false

var max_distance_tiles = 16

var occupied_cells : Dictionary = {}

const max_score_multiplier = 6
var score_multiplier = 1
var curr_score = 0
var high_score = 0

func add_score(value : int):
	curr_score += value * score_multiplier

#connect some signal to show when failed actions
