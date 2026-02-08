extends Node2D
class_name Dungeon

@export var tilemap : TileMapLayer

func _ready() -> void:
	#give enemies and players tile map reference for movement
	for node in get_tree().get_nodes_in_group("req_tile_map"):
		if node.has_method("set_tile_map"):
			node.set_tile_map(tilemap)
			#print("assigned tile map to " + str(node) )
			
	refresh_occupancy()
	BeatManager.phase_changed.connect(_on_phase_changed)

func refresh_occupancy():
	Global.occupied_cells.clear()
	for actor in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("enemy"):
		Global.occupied_cells[actor.grid_position] = actor
	print(Global.occupied_cells)

func _on_phase_changed(phase: int):
	if phase != 3:
		return
	await get_tree().create_timer(0.12).timeout
	refresh_occupancy()
