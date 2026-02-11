extends CharacterBody2D

signal player_moved

@export var my_phase: int
@export var tilemap: TileMapLayer
@export var beat_window := 0.125
@export var move_duration := 0.12

var acted_this_beat := false
var facing_direction: Vector2i = Vector2i.DOWN
var is_moving := false

@export var flash_duration: float = 0.1
var _default_modulate: Color
var flash_color: Color
var move_tween: Tween
var buffer_active = false

var grid_position: Vector2i
var previous_cell: Vector2i
var buffered_direction: Vector2i = Vector2i.ZERO
var initialized := false
var can_act := false
@onready var buffer_timer_node: Timer = $BufferTimer

var time_since_beat := 0.0

var input_up: String = "up1"
var input_down: String = "down1"
var input_left: String = "left1"
var input_right: String = "right1"
var input_interact: String = "interact1"
var input_attack: String = "attack1"

@onready var sprite = $Sprite2D
@onready var flash_timer: Timer = $Timer

@export var up_next_pop_scale := .75
@export var up_next_normal_scale := 0.5
@export var up_next_pop_time := 0.12

var up_next_tween: Tween

@onready var up_next : Sprite2D = $Sprite2D/UpNext

func _ready():
	add_to_group("req_tile_map")
	add_to_group("player")
	
	buffer_timer_node.one_shot = true
	buffer_timer_node.wait_time = beat_window
	buffer_timer_node.timeout.connect(_on_buffer_timeout)
	
	flash_color = Color(0.24, 0.463, 1.0, 0.5) if my_phase == 0 else Color(1.0, 0.255, 0.0, 0.5)
	
	BeatManager.phase_changed.connect(_on_phase_changed)
	BeatManager.beat.connect(_on_beat)
	
	_default_modulate = sprite.modulate

	flash_timer.one_shot = true
	flash_timer.wait_time = flash_duration
	flash_timer.timeout.connect(_end_flash)
	
	if tilemap:
		_initialize_position()
	
	up_next.scale = Vector2.ONE * up_next_normal_scale
	up_next.modulate.a = 0.0
	
	if Global.two_player_mode and my_phase != 0:
		input_up = "up2"
		input_down = "down2"
		input_left = "left2"
		input_right = "right2"
		input_interact = "interact2"
		input_attack = "attack2"

func _on_beat(_beat_count: int):
	time_since_beat = 0.0

	if can_act:
		if buffered_direction != Vector2i.ZERO and buffer_active:
			try_resolve_buffer()


func attack():
	pass 

func _on_phase_changed(phase: int):
	var pre_phase = (my_phase - 1 + BeatManager.PHASES) % BeatManager.PHASES

	up_next.visible = phase == pre_phase
	if phase == pre_phase:
		_pop_up_next()

	if phase == 3:
		attack()
		return

	can_act = (phase == my_phase)

	if can_act:
		acted_this_beat = false
		_start_flash()
		if buffer_timer_node.time_left > 0.0 and buffered_direction != Vector2i.ZERO:
			try_resolve_buffer()


func _process(delta: float) -> void:
	time_since_beat += delta

func _resolve_if_valid():
	if buffered_direction == Vector2i.ZERO:
		clear_buffer()
		return

	if buffer_timer_node.timeleft > 0.0 or time_since_beat <= beat_window:
		try_resolve_buffer()
	else:
		clear_buffer()

func try_resolve_buffer():
	if buffered_direction == Vector2i.ZERO:
		return

	buffer_timer_node.stop()
	
	acted_this_beat = true
	can_act = false

	var direction := buffered_direction
	buffered_direction = Vector2i.ZERO

	facing_direction = direction
	var target_cell = grid_position + direction

	emit_signal("player_moved") # up here so if they didnt move the buffer wont overflow
	if is_blocked(target_cell) or not can_move_within_leash(target_cell):
		_update_facing_visual()
		return

	previous_cell = grid_position
	grid_position = target_cell
	var from_pos := tilemap.map_to_local(previous_cell)
	var to_pos := tilemap.map_to_local(grid_position)

	Global.occupied_cells[target_cell] = self

	_update_facing_visual()
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

	buffer_timer_node.start(beat_window)

	if can_act:
		try_resolve_buffer()


func _update_facing_visual():
	match facing_direction:
		Vector2i.UP:
			sprite.play("walk_up")
		Vector2i.DOWN:
			sprite.play("walk_down")
		Vector2i.LEFT:
			sprite.play("walk_left")
		Vector2i.RIGHT:
			sprite.play("walk_right")

func try_move(direction: Vector2i):
	if not can_act or tilemap == null:
		return

	var target = grid_position + direction

	facing_direction = direction

	if is_blocked(target) or not can_move_within_leash(target):
		_update_facing_visual()
		return

	grid_position = target
	global_position = tilemap.map_to_local(grid_position)
	can_act = false

	_update_facing_visual()
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
	print("t=", time_since_beat, " resolve")

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

func _pop_up_next():
	if up_next_tween and up_next_tween.is_running():
		up_next_tween.kill()

	up_next.visible = true

	up_next.scale = Vector2.ONE * up_next_normal_scale
	up_next.modulate.a = 0.0

	up_next_tween = create_tween()
	up_next_tween.set_trans(Tween.TRANS_BACK)
	up_next_tween.set_ease(Tween.EASE_OUT)

	up_next_tween.parallel().tween_property(
		up_next,
		"modulate:a",
		1.0,
		0.08
	)

	up_next_tween.parallel().tween_property(
		up_next,
		"scale",
		Vector2.ONE * up_next_pop_scale,
		up_next_pop_time
	)

	up_next_tween.tween_property(
		up_next,
		"scale",
		Vector2.ONE * up_next_normal_scale,
		up_next_pop_time * 0.8
	)
	
func _on_buffer_timeout():
	buffered_direction = Vector2i.ZERO
