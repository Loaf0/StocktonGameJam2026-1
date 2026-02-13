extends Node2D
class_name Dungeon

var astar_grid: AStarGrid2D
@onready var tilemap : Room = $TileMapLayer
@onready var character_container: Node2D = $CharacterContainer
@onready var transition: CanvasLayer = $Transition

@onready var fade_overlay : ColorRect = $Transition.get_child(0)

@export var new_tilemap_scene : PackedScene
@export var enemy_scene : PackedScene
@export var player_positions := [Vector2(0,0), Vector2(0,1)]

@onready var tutorial_ui: CanvasLayer = $TutorialUI
@onready var p_2: MarginContainer = $TutorialUI/P2

var tile_map_scenes = [
		preload("res://scenes/layouts/001.tscn"),
		preload("res://scenes/layouts/002.tscn"),
		preload("res://scenes/layouts/003.tscn"),
		preload("res://scenes/layouts/004.tscn"),
		preload("res://scenes/layouts/005.tscn"),
		preload("res://scenes/layouts/006.tscn"),
		preload("res://scenes/layouts/007.tscn"),
		preload("res://scenes/layouts/008.tscn"),
		preload("res://scenes/layouts/009.tscn"),
	]
var recent_maps: Array = []
const MAX_RECENT := 3

func _ready() -> void:
	#give enemies and players tile map reference for movement
	for node in get_tree().get_nodes_in_group("req_tile_map"):
		if node.has_method("set_tile_map"):
			node.set_tile_map(tilemap)
			#print("assigned tile map to " + str(node) )
	
	p_2.visible = Global.two_player_mode
	
	setup_astar()
	
	refresh_occupancy()
	BeatManager.phase_changed.connect(_on_phase_changed)

#func _input(event):
	#if event.is_action_pressed("debug_next_layout"):
		#change_layout()

func _get_random_map_scene() -> PackedScene:
	var available := tile_map_scenes.filter(func(scene):
		return not recent_maps.has(scene)
	)

	if available.is_empty():
		recent_maps.clear()
		available = tile_map_scenes.duplicate()

	var chosen = available.pick_random()

	recent_maps.append(chosen)
	if recent_maps.size() > MAX_RECENT:
		recent_maps.pop_front()

	return chosen

func change_layout() -> void:
	for projectile in get_tree().get_nodes_in_group("projectile"):
		projectile.on_death()
	while BeatManager.phase != 3:
		await get_tree().process_frame
	Global.difficulty += 0.1
	Global.do_not_act = true
	
	tutorial_ui.hide()
	p_2.hide()
	
	var fade_time = 60.0 / BeatManager.bpm * 2
	var tween = create_tween()
	fade_overlay.visible = true
	tween.tween_property(fade_overlay.material, "shader_parameter/radius", 0.0, fade_time)
	await tween.finished
	
	if new_tilemap_scene:
		var scene_to_load := _get_random_map_scene()
		var new_tilemap_instance = scene_to_load.instantiate() as Room
		var old_tilemap = tilemap
		var tilemap_index = old_tilemap.get_index()

		add_child(new_tilemap_instance)
		move_child(new_tilemap_instance, tilemap_index)
		tilemap = new_tilemap_instance

		if old_tilemap:
			old_tilemap.queue_free()
		astar_grid = null
	setup_astar()

	Global.occupied_cells.clear()

	var players = get_tree().get_nodes_in_group("player")

	for i in range(players.size()):
		var p = players[i]
		p.set_tile_map(tilemap)
		var spawn_cell : Vector2i
		if i == 0:
			spawn_cell = tilemap.player_spawn_1
		else:
			spawn_cell = tilemap.player_spawn_2
		p.grid_position = spawn_cell
		p.global_position = tilemap.map_to_local(spawn_cell)

	if enemy_scene:
		for i in range(3):
			var enemy = enemy_scene.instantiate()
			enemy.position = tilemap.map_to_local(Vector2i(5 + i, 5))
			add_child(enemy)
	
	refresh_occupancy()
	
	tween = create_tween()
	tween.tween_property(fade_overlay.material, "shader_parameter/radius", 2.0, fade_time)
	await tween.finished
	await get_tree().create_timer(fade_time).timeout
	setup_astar()
	fade_overlay.visible = false
	
	Global.do_not_act = false

	while BeatManager.phase != 3:
		await get_tree().process_frame

func setup_astar():
	#setup astar
	if tilemap == null:
		for child in get_children():
			if child is TileMapLayer:
				tilemap = child
				break
	if tilemap == null:
		push_warning("No TileMapLayer found for A* setup!")
		return
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
	await get_tree().process_frame
	if get_tree().get_nodes_in_group("enemy").is_empty():
		change_layout()
	await get_tree().create_timer(0.12).timeout
	refresh_occupancy()

func fade_in(duration: float = 0.5) -> void:
	var mat := fade_overlay.material as ShaderMaterial
	var tween := create_tween()
	tween.tween_property(mat, "shader_param/radius", 0.0, duration)
	await tween.finished

func fade_out(duration: float = 0.5) -> void:
	var mat := fade_overlay.material as ShaderMaterial
	var tween := create_tween()
	tween.tween_property(mat, "shader_param/radius", 2.0, duration)
	await tween.finished
