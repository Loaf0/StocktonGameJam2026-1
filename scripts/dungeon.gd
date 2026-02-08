extends Node2D
class_name Dungeon

@export var tilemap : TileMapLayer
var astar_grid: AStarGrid2D

func _ready() -> void:
	#give enemies and players tile map reference for movement
	for node in get_tree().get_nodes_in_group("req_tile_map"):
		if node.has_method("set_tile_map"):
			node.set_tile_map(tilemap)
			#print("assigned tile map to " + str(node) )
			
	
	setup_astar()
	
	refresh_occupancy()
	BeatManager.phase_changed.connect(_on_phase_changed)

func setup_astar():
	#setup astar
	astar_grid = AStarGrid2D.new()
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.cell_size = tilemap.tile_set.tile_size
	astar_grid.region = Rect2(Vector2.ZERO, ceil(get_viewport_rect().size / astar_grid.cell_size))
	astar_grid.update()
	#setup solids
	for id in tilemap.get_used_cells():
		var data = tilemap.get_cell_tile_data(id)
		if data and data.get_custom_data("solid"):
			astar_grid.set_point_solid(id)
	#give enemies grid
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.setup(astar_grid)

func refresh_occupancy():
	Global.occupied_cells.clear()
	for actor in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("enemy"):
		Global.occupied_cells[actor.grid_position] = actor
	#print(Global.occupied_cells)

func _on_phase_changed(phase: int):
	if phase != 3:
		return
	await get_tree().create_timer(0.12).timeout
	refresh_occupancy()
