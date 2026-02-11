extends Node2D
class_name Dungeon

@export var tilemap : TileMapLayer
var astar_grid: AStarGrid2D
@onready var character_container: Node2D = $CharacterContainer
@onready var transition: CanvasLayer = $Transition

@onready var dim_overlay : ColorRect = $Transition.get_child(0)

@export var new_tilemap_scene : PackedScene
@export var enemy_scene : PackedScene
@export var player_positions := [Vector2(0,0), Vector2(0,1)]

func _ready() -> void:
	#give enemies and players tile map reference for movement
	for node in get_tree().get_nodes_in_group("req_tile_map"):
		if node.has_method("set_tile_map"):
			node.set_tile_map(tilemap)
			#print("assigned tile map to " + str(node) )
			
	
	setup_astar()
	
	refresh_occupancy()
	BeatManager.phase_changed.connect(_on_phase_changed)

func _input(event):
	if event.is_action_pressed("debug_next_layout"):
		change_layout()

func change_layout() -> void:
	while BeatManager.phase != 3:
		await get_tree().process_frame
		
	Global.do_not_act = true
	
	var fade_time = 60.0 / BeatManager.bpm * 2
	var tween = create_tween()
	tween.tween_property(dim_overlay.material, "shader_param/radius", 0.0, fade_time)
	await tween.finished
	
	
	if new_tilemap_scene:
		var new_tilemap_instance = new_tilemap_scene.instantiate()
		if tilemap:
			tilemap.queue_free()
		add_child(new_tilemap_instance)
		tilemap = new_tilemap_instance

	Global.occupied_cells.clear()

	var players = get_tree().get_nodes_in_group("player")
	for i in range(players.size()):
		var p = players[i]
		if i < player_positions.size():
			p.grid_position = player_positions[i]
			p.global_position = tilemap.map_to_local(p.grid_position)

	if enemy_scene:
		for i in range(3):
			var enemy = enemy_scene.instantiate()
			enemy.position = tilemap.map_to_local(Vector2i(5 + i, 5))
			add_child(enemy)
	
	setup_astar()
	refresh_occupancy()
	
	tween = create_tween()
	tween.tween_property(dim_overlay.material, "shader_param/radius", 2.0, fade_time)
	await tween.finished
	await get_tree().create_timer(fade_time).timeout
	
	dim_overlay.visible = false
	
	Global.do_not_act = false

	while BeatManager.current_phase != 3:
		await get_tree().process_frame

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
