extends Node2D

@export var tilemap : TileMapLayer

func _ready() -> void:
	#give enemies and players tile map reference for movement
	for node in get_tree().get_nodes_in_group("req_tile_map"):
		if node.has_method("set_tile_map"):
			node.set_tile_map(tilemap)
