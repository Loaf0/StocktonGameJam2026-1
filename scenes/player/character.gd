extends CharacterBody2D

@export var my_phase: int
@export var tile_size := 16
@export var tilemap: TileMapLayer

var grid_position: Vector2i
var buffered_direction: Vector2i = Vector2i.ZERO
var can_act := false
var initialized := false

func _ready():
	add_to_group("req_tile_map")
	BeatManager.phase_changed.connect(_on_phase_changed)
	if tilemap:
		_initialize_position()

func _on_phase_changed(phase: int):
	print(name, " phase:", phase, " my_phase:", my_phase)
	can_act = (phase == my_phase)

	if can_act and buffered_direction != Vector2i.ZERO:
		try_move(buffered_direction)
		buffered_direction = Vector2i.ZERO

func _unhandled_input(event):
	if not event.is_pressed():
		return
	if buffered_direction != Vector2i.ZERO:
		return 
	if event.is_action_pressed("up1"):
		buffered_direction = Vector2i.UP
	elif event.is_action_pressed("down1"):
		buffered_direction = Vector2i.DOWN
	elif event.is_action_pressed("left1"):
		buffered_direction = Vector2i.LEFT
	elif event.is_action_pressed("right2"):
		buffered_direction = Vector2i.RIGHT

func try_move(direction: Vector2i):
	if not can_act:
		return

	if tilemap == null:
		push_warning(name + " tried to move without tilemap")
		return

	var target := grid_position + direction

	if is_blocked(target):
		return

	grid_position = target
	global_position = tilemap.map_to_local(grid_position)
	can_act = false

func is_blocked(cell: Vector2i) -> bool:
	if tilemap == null:
		return true

	var tile_data := tilemap.get_cell_tile_data(cell)

	if tile_data == null:
		return true

	return false


func set_tile_map(new_tilemap: TileMapLayer):
	tilemap = new_tilemap
	_initialize_position()

func _initialize_position():
	if initialized or tilemap == null:
		return

	grid_position = tilemap.local_to_map(global_position)
	global_position = tilemap.map_to_local(grid_position)
	initialized = true
