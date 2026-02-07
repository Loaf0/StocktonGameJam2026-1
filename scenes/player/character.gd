extends CharacterBody2D

@export var my_phase: int
@export var tile_size := 16
@export var tilemap: TileMapLayer

var can_act := false
var grid_position: Vector2i
var buffered_direction: Vector2i = Vector2i.ZERO

func _ready():
	add_to_group("req_tile_map")
	BeatManager.phase_changed.connect(_on_phase_changed)
	grid_position = tilemap.local_to_map(global_position)
	global_position = tilemap.map_to_local(grid_position)

func _on_phase_changed(phase: int):
	can_act = (phase == my_phase)

	if can_act and buffered_direction != Vector2i.ZERO:
		try_move(buffered_direction)
		buffered_direction = Vector2i.ZERO

func _unhandled_input(event):
	if event.is_action_pressed("ui_up"):
		buffered_direction = Vector2i.UP
	elif event.is_action_pressed("ui_down"):
		buffered_direction = Vector2i.DOWN
	elif event.is_action_pressed("ui_left"):
		buffered_direction = Vector2i.LEFT
	elif event.is_action_pressed("ui_right"):
		buffered_direction = Vector2i.RIGHT

func try_move(direction: Vector2i):
	var target := grid_position + direction

	if is_blocked(target):
		return

	grid_position = target
	global_position = tilemap.map_to_local(grid_position)

	can_act = false

func is_blocked(cell: Vector2i) -> bool:
	if not tilemap.get_used_rect().has_point(cell):
		return true

	var tile_data := tilemap.get_cell_tile_data(cell)
	if tile_data and tile_data.get_collision_polygons_count(0) > 0:
		return true

	return false

func set_tile_map(new_tilemap : TileMapLayer):
	tilemap = new_tilemap
