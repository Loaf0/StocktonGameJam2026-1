extends Camera2D

@export var max_distance_tiles := 6
@export var tile_size := 16
@export var camera_lerp := 8.0

@onready var player1 := %Player1
@onready var player2 := %Player2

func _process(delta):
	if not player1 or not player2:
		return

	var mid = (player1.global_position + player2.global_position) * 0.5
	global_position = global_position.lerp(mid, delta * camera_lerp)
