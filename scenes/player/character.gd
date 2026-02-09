extends CharacterBody2D

signal player_moved

@export var my_phase: int
@export var tilemap: TileMapLayer
@export var beat_window := 0.12
@export var move_duration := 0.12

var acted_this_beat := false
var facing_direction: Vector2i = Vector2i.DOWN
var is_moving := false

@export var flash_duration: float = 0.1
var _default_modulate: Color
var flash_color: Color
var move_tween: Tween

var grid_position: Vector2i
var previous_cell: Vector2i
var buffered_direction: Vector2i = Vector2i.ZERO
var buffered_time: float = 0.00
var initialized := false
var buffer_active := false
var buffer_timer := 0.0
var can_act := false

var input_up: String = "up1"
var input_down: String = "down1"
var input_left: String = "left1"
var input_right: String = "right1"
var input_interact: String = "interact1"
var input_attack: String = "attack1"

@onready var sprite = $Sprite2D
@onready var flash_timer: Timer = $Timer
@onready var label = $Label

func _ready():
	add_to_group("req_tile_map")
	add_to_group("player")
	flash_color = Color(0.24, 0.463, 1.0, 0.5) if my_phase == 0 else Color(1.0, 0.255, 0.0, 0.5)
	
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
	if can_act:
		if buffered_direction != Vector2i.ZERO and buffer_active:
			try_resolve_buffer()


func attack():
	pass 

func _on_phase_changed(phase: int):
	var pre_phase = (my_phase - 1 + BeatManager.PHASES) % BeatManager.PHASES
	label.visible = phase == pre_phase
	
	if phase == 3:
		attack()
		return
		
	can_act = (phase == my_phase)

	if can_act:
		acted_this_beat = false
		_start_flash()
		

func _physics_process(_delta: float):
	if is_moving or not buffer_active:
		return

	buffer_timer -= _delta
	if buffer_timer <= 0:
		clear_buffer()
		return
	if can_act and buffered_direction != Vector2i.ZERO:
		try_resolve_buffer()

func try_resolve_buffer():
	acted_this_beat = true
	can_act = false

	var direction := buffered_direction
	buffered_direction = Vector2i.ZERO

	facing_direction = direction
	var target_cell = grid_position + direction

	emit_signal("player_moved") # up here so if they didnt move the buffer wont overflow
	if is_blocked(target_cell) or not can_move_within_leash(target_cell):
		_update_facing_visual(false)
		return

	previous_cell = grid_position
	grid_position = target_cell
	var from_pos := tilemap.map_to_local(previous_cell)
	var to_pos := tilemap.map_to_local(grid_position)

	Global.occupied_cells[target_cell] = self

	_update_facing_visual(true)
	animate_move(from_pos, to_pos)

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
	buffered_direction = direction
	buffer_timer = beat_window
	buffer_active = true


func _update_facing_visual(moving: bool = false):
	var prefix := "walk_" if moving else "idle_"

	match facing_direction:
		Vector2i.UP:
			sprite.play(prefix + "up")
		Vector2i.DOWN:
			sprite.play(prefix + "down")
		Vector2i.LEFT:
			sprite.play(prefix + "left")
		Vector2i.RIGHT:
			sprite.play(prefix + "right")

func try_move(direction: Vector2i):
	if not can_act or tilemap == null:
		return

	var target = grid_position + direction

	facing_direction = direction

	if is_blocked(target) or not can_move_within_leash(target):
		_update_facing_visual(false)
		return

	grid_position = target
	global_position = tilemap.map_to_local(grid_position)
	can_act = false

	_update_facing_visual(true)
	emit_signal("player_moved")

func is_blocked(cell: Vector2i) -> bool:
	var tile_data = tilemap.get_cell_tile_data(cell)
	if tile_data == null:
		return true
	if Global.occupied_cells.has(cell):
		return true
	return tile_data.get_custom_data("solid") == true

func clear_buffer():
	buffered_direction = Vector2i.ZERO
	buffer_active = false
	buffer_timer = 0.0

func can_move_within_leash(target_cell: Vector2i) -> bool:
	var other_player = _get_other_player()
	if other_player == null:
		return true

	var dist = target_cell.distance_to(other_player.grid_position)
	#print(dist)
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

func animate_move(from_pos: Vector2, to_pos: Vector2):
	is_moving = true

	if move_tween and move_tween.is_running():
		move_tween.kill()

	move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_QUAD)
	move_tween.set_ease(Tween.EASE_OUT)

	var mid := (from_pos + to_pos) * 0.5 + Vector2(0, -6)

	move_tween.tween_property(self, "global_position", mid, move_duration * 0.5)
	move_tween.tween_property(self, "global_position", to_pos, move_duration * 0.5)

	move_tween.finished.connect(_on_move_finished)

func _on_move_finished():
	is_moving = false

	if previous_cell in Global.occupied_cells:
		Global.occupied_cells.erase(previous_cell)

	Global.occupied_cells[grid_position] = self
