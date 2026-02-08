extends CharacterBody2D

signal player_moved

@export var my_phase: int
@export var tile_size := 16
@export var tilemap: TileMapLayer
@export var beat_window := 0.1

var facing_direction: Vector2i = Vector2i.DOWN

var flash_color: Color
@export var flash_duration: float = 0.1

var grid_position: Vector2i
var buffered_direction: Vector2i = Vector2i.ZERO
var buffered_time: float = 0.0
var can_act := false
var initialized := false
var last_beat_time := 0.0

var _default_modulate: Color

var input_up: String = "up1"
var input_down: String = "down1"
var input_left: String = "left1"
var input_right: String = "right1"
var input_interact: String = "interact1"
var input_attack: String = "attack1"

@onready var sprite = $Sprite2D
@onready var flash_timer: Timer = $Timer

func _ready():
	add_to_group("req_tile_map")
	add_to_group("player")
	flash_color = Color(0.24, 0.463, 1.0, 1.0) if my_phase == 0 else Color(1.0, 0.255, 0.0, 1.0)
	BeatManager.phase_changed.connect(_on_phase_changed)
	BeatManager.beat.connect(_on_beat)
	
	_default_modulate = sprite.modulate

	flash_timer.one_shot = true
	flash_timer.wait_time = flash_duration
	flash_timer.timeout.connect(_end_flash)
	
	if tilemap:
		_initialize_position()
	
	if Global.two_player_mode and my_phase != 0:
		input_up = "up2"
		input_down = "down2"
		input_left = "left2"
		input_right = "right2"
		input_interact = "interact2"
		input_attack = "attack2"

func _on_beat(_beat_count: int):
	last_beat_time = Time.get_unix_time_from_system()

func attack():
	pass 

func _on_phase_changed(phase: int):
	if phase == 3:
		attack()
		return
	can_act = (phase == my_phase)

	if can_act:
		_start_flash()

func _physics_process(_delta: float):
	if buffered_direction != Vector2i.ZERO:
		var time_since_beat = Time.get_unix_time_from_system() - last_beat_time
		if can_act or (time_since_beat > 0 and time_since_beat <= beat_window):
			try_move(buffered_direction)
			buffered_direction = Vector2i.ZERO

func _start_flash():
	sprite.modulate = flash_color
	flash_timer.start()

func _end_flash():
	sprite.modulate = _default_modulate

func _unhandled_input(event):
	if not event.is_pressed():
		return

	if Input.is_action_just_pressed(input_up):
		_buffer_input(Vector2i.UP)
	elif Input.is_action_just_pressed(input_down):
		_buffer_input(Vector2i.DOWN)
	elif Input.is_action_just_pressed(input_left):
		_buffer_input(Vector2i.LEFT)
	elif Input.is_action_just_pressed(input_right):
		_buffer_input(Vector2i.RIGHT)

func _buffer_input(direction: Vector2i):
	facing_direction = direction
	_update_facing_visual()

	buffered_direction = direction
	buffered_time = Engine.get_physics_frames()

func _update_facing_visual():
	pass #till we have sprites

func try_move(direction: Vector2i):
	if not can_act or tilemap == null:
		return

	var target = grid_position + direction

	if is_blocked(target):
		return

	if not can_move_within_leash(target):
		return

	grid_position = target
	global_position = tilemap.map_to_local(grid_position)
	can_act = false
	emit_signal("player_moved")

func is_blocked(cell: Vector2i) -> bool:
	var tile_data = tilemap.get_cell_tile_data(cell)
	if tile_data == null:
		return true
	return tile_data.get_custom_data("solid") == true

func clear_buffer():
	buffered_direction = Vector2i.ZERO

func can_move_within_leash(target_cell: Vector2i) -> bool:
	var other_player = _get_other_player()
	if other_player == null:
		return true

	var dist = target_cell.distance_to(other_player.grid_position)
	print(dist)
	return dist <= Global.max_distance_tiles

func _get_other_player():
	for node in get_tree().get_nodes_in_group("player"):
		if node != self:
			return node
	return null

func set_tile_map(new_tilemap: TileMapLayer):
	tilemap = new_tilemap
	_initialize_position()

func _initialize_position():
	if initialized or tilemap == null:
		return
	grid_position = tilemap.local_to_map(global_position)
	global_position = tilemap.map_to_local(grid_position)
	initialized = true
