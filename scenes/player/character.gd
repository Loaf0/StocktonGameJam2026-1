extends CharacterBody2D

@export var my_phase: int
@export var tile_size := 16
@export var tilemap: TileMapLayer

@export var beat_window := 0.15

@export var flash_color: Color = Color(1, 1, 0)
@export var flash_duration: float = 0.1

var grid_position: Vector2i
var buffered_direction: Vector2i = Vector2i.ZERO
var buffered_time: float = 0.0
var can_act := false
var initialized := false
var last_beat_time := 0.0

var _default_modulate: Color

@export var input_up: String = "up1"
@export var input_down: String = "down1"
@export var input_left: String = "left1"
@export var input_right: String = "right1"

@onready var sprite = $Sprite2D
@onready var flash_timer : Timer = $Timer

func _ready():
	add_to_group("req_tile_map")
	BeatManager.phase_changed.connect(_on_phase_changed)
	BeatManager.beat.connect(_on_beat)
	
	_default_modulate = sprite.modulate

	flash_timer.one_shot = true
	flash_timer.wait_time = flash_duration
	flash_timer.timeout.connect(_end_flash)
	
	if tilemap:
		_initialize_position()

func _on_beat(beat_count: int):
	last_beat_time = Engine.get_physics_frames()

func _on_phase_changed(phase: int):
	can_act = (phase == my_phase)

	if can_act:
		_start_flash()

	if buffered_direction != Vector2i.ZERO:
		var time_since_beat = Engine.get_physics_frames() - last_beat_time
		if abs(time_since_beat) <= beat_window:
			try_move(buffered_direction)
			buffered_direction = Vector2i.ZERO
		elif time_since_beat > beat_window:
			buffered_direction = Vector2i.ZERO

func _start_flash():
	sprite.modulate = flash_color
	flash_timer.start()

func _end_flash():
	sprite.modulate = _default_modulate

func _unhandled_input(event):
	if not event.is_pressed():
		return

	if event.is_action_pressed(input_up):
		_buffer_input(Vector2i.UP)
	elif event.is_action_pressed(input_down):
		_buffer_input(Vector2i.DOWN)
	elif event.is_action_pressed(input_left):
		_buffer_input(Vector2i.LEFT)
	elif event.is_action_pressed(input_right):
		_buffer_input(Vector2i.RIGHT)

func _buffer_input(direction: Vector2i):
	buffered_direction = direction
	buffered_time = Engine.get_physics_frames()

func try_move(direction: Vector2i):
	if not can_act or tilemap == null:
		return

	var target = grid_position + direction
	if is_blocked(target):
		return

	grid_position = target
	global_position = tilemap.map_to_local(grid_position)
	can_act = false

func is_blocked(cell: Vector2i) -> bool:
	if tilemap == null:
		return true
	var tile_data = tilemap.get_cell_tile_data(cell)
	return tile_data == null

func set_tile_map(new_tilemap: TileMapLayer):
	tilemap = new_tilemap
	_initialize_position()

func _initialize_position():
	if initialized or tilemap == null:
		return
	grid_position = tilemap.local_to_map(global_position)
	global_position = tilemap.map_to_local(grid_position)
	initialized = true
