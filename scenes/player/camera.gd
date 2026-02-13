extends Camera2D

@export var max_distance_tiles := 6
@export var tile_size := 16
@export var camera_lerp := 8.0

@export var enemy_bias_strength := 0.25 
@export var screen_buffer_pixels := 128

@onready var player1 := %Player1
@onready var player2 := %Player2

func _process(delta):
	if not player1 or not player2:
		return

	var players_mid = (player1.global_position + player2.global_position) * 0.5
	
	var enemies := get_tree().get_nodes_in_group("enemy")
	var enemy_mid = players_mid
	
	if enemies.size() > 0:
		var sum := Vector2.ZERO
		for e in enemies:
			sum += e.global_position
		enemy_mid = sum / enemies.size()
	
	var biased_mid = players_mid.lerp(enemy_mid, enemy_bias_strength)
	
	var viewport_size := get_viewport_rect().size
	var half_screen := viewport_size * 0.5
	
	var min_x = biased_mid.x - half_screen.x + screen_buffer_pixels
	var max_x = biased_mid.x + half_screen.x - screen_buffer_pixels
	var min_y = biased_mid.y - half_screen.y + screen_buffer_pixels
	var max_y = biased_mid.y + half_screen.y - screen_buffer_pixels
	
	var clamped_mid = biased_mid
	
	clamped_mid.x = clamp(clamped_mid.x, min_x, max_x)
	clamped_mid.y = clamp(clamped_mid.y, min_y, max_y)
	
	global_position = global_position.lerp(clamped_mid, delta * camera_lerp)
