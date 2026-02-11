extends Node

#mushroom candle skeleton
# difficulty 1.0 + 0.1
# skeleton - Base Rate 15 - min(base_rate * difficulty, 40)
# candle - Base Rate 25 - min(base_rate * difficulty, 30)
# ranged -
# mushroom = 100 - skeleton - candle

# enemies per room
# min(1 + ceil(randi(0, difficulty)), 5)

@export var skeleton_scene : PackedScene = preload("res://scenes/enemies/sweep_enemy.tscn")
@export var candle_scene : PackedScene = preload("res://scenes/enemies/plus_enemy.tscn")
@export var mushroom_scene : PackedScene = preload("res://scenes/enemies/base_enemy.tscn")
@export var cannon_scene : PackedScene = preload("res://scenes/enemies/base_enemy.tscn")

const MAX_ENEMIES_PER_ROOM := 5

func spawn_room_enemies(tilemap: TileMapLayer, spawn_points: Array[Vector2], astar_grid: AStarGrid2D) -> void:
	var difficulty := Global.difficulty
	
	for cell in spawn_points:
		var scene := _choose_enemy_scene(difficulty)
		var enemy = scene.instantiate()
		
		if enemy.has_method("set_tile_map"):
			enemy.set_tile_map(tilemap)
		if enemy.has_method("setup"):
			enemy.setup(astar_grid)
		
		var world_pos = tilemap.map_to_local(cell)
		enemy.global_position = tilemap.to_global(world_pos)
		
		get_tree().get_first_node_in_group("enemy manager").add_child(enemy)


func _choose_enemy_scene(difficulty : float) -> PackedScene:
	var cannon_weight = min(5 * difficulty, 15)
	var skeleton_weight = min(15.0 * difficulty, 30.0)
	var candle_weight = min(25.0 * difficulty, 25.0)
	var mushroom_weight = max(0.0, 100.0 - skeleton_weight - candle_weight - cannon_weight)

	var total = skeleton_weight + candle_weight + mushroom_weight

	var roll = randf() * total

	if roll < cannon_weight:
		return cannon_scene
	elif roll < skeleton_weight:
		return skeleton_scene
	elif roll < skeleton_weight + candle_weight:
		return candle_scene
	else:
		return mushroom_scene
