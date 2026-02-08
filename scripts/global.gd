extends Node

#show flashes on character to help time beats
var beat_assist : bool = true

#move player 2 to arrow keys
var two_player_mode : bool = false

var max_distance_tiles = 16

var occupied_cells : Dictionary = {}

var enemy_intent_cells : Dictionary = {}
