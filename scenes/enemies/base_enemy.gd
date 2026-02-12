extends CharacterBody2D
class_name Enemy

@export var my_phase: int = 2
@export var tilemap: TileMapLayer

@export var move_duration := 0.12

var grid: AStarGrid2D
var initialized := false
var grid_position: Vector2i
var target: Vector2i
var target_cell: Vector2i
var previous_cell: Vector2i
var move_pts: Array
var cur_pt: int = 0

var can_act := false

var move_tween: Tween

var acted_this_beat := false
var facing_direction: Vector2i = Vector2i.DOWN
@onready var sprite = $Sprite2D
@onready var move_pivot: Node2D = $MovePivot
var atk_warns : Array
@onready var atk_warn: Sprite2D = $AtkWarn
var atk_boxes : Array
@onready var pivot: Node2D = $Pivot
var is_moving := false

var first_turn := true
var atk_turn: bool = false
var wait_turn: bool = true

#on ready / player enter room / end of beat 2(3rd)
##locate the player CHECK
##find shortest path CHECK
##toggle atk turn
##display atk aoe if true
##display move arrow if false
#on beat 2(3rd) move enemy
###atk if true
###move if false

#move logic global
#atk logic is per enemy (empty for base)
#func enemylogic is per enemy (move/atk alternate for base)

func _ready():
	add_to_group("req_tile_map")
	add_to_group("enemy")
	get_tree().get_nodes_in_group("player")
	await get_tree().process_frame
	_target_player()
	_update_facing_visual(true)
	atk_warns.append(atk_warn)
	atk_boxes.append($AtkWarn/AtkBox)

func _my_turn():
	if acted_this_beat == false:
		#move or attack logic here
		if first_turn:
			_declare_action()
			first_turn = false
		elif !atk_turn:
			_move()
			atk_turn = true
		
		
		_target_player()
		acted_this_beat = true
	return

func on_phase_changed(phase: int):
	if phase == 3:
		_attack()
		return
	
	can_act = (phase == my_phase)

	if can_act:
		acted_this_beat = false
		_my_turn()

func setup(_grid: AStarGrid2D) -> void:
	grid = _grid
	grid_position = tilemap.local_to_map(global_position)
	global_position = tilemap.map_to_local(grid_position)
	target_cell = grid_position

func pos_to_cell(pos:Vector2) -> Vector2:
	return pos / grid.cell_size

func _target_player() -> void:
	var dist1: int
	var dist2: int
	var players = get_tree().get_nodes_in_group("player")
	dist1 = abs((grid_position.x - players[0].grid_position.x)) + abs((grid_position.y - players[0].grid_position.y))
	dist2 = abs((grid_position.x - players[1].grid_position.x)) + abs((grid_position.y - players[1].grid_position.y))
	if dist1 < dist2:
		target = players[0].grid_position
	else:
		target = players[1].grid_position

func _move() -> void:
	if move_pts.is_empty():
		return
	else:
		move_pivot.visible = false
		if move_pts.size() > 1 and !is_blocked(tilemap.local_to_map(move_pts[cur_pt+1])):
			# Add new cell immediately and remove old
			if !Global.occupied_cells.has(tilemap.local_to_map(move_pts[cur_pt+1])):
				Global.occupied_cells[tilemap.local_to_map(move_pts[cur_pt+1])] = self
				Global.occupied_cells.erase(tilemap.local_to_map(move_pts[cur_pt]))
			_update_facing_dir()
			_update_facing_visual(true)
			animate_move(move_pts[cur_pt], move_pts[cur_pt+1])
			#print(Global.occupied_cells)
		else:
			_update_facing_visual(false)
	return

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
	grid_position = tilemap.local_to_map(to_pos)

func _on_move_finished():
	is_moving = false
	
	Global.occupied_cells[grid_position] = self

func is_blocked(cell: Vector2i) -> bool:
	var tile_data = tilemap.get_cell_tile_data(cell)
	if tile_data == null:
		return true
	if Global.occupied_cells.has(cell) and Global.occupied_cells[cell] != self:
		return true
	if Global.enemy_intent_cells.has(cell) and Global.enemy_intent_cells[cell] != self:
		return true
	return tile_data.get_custom_data("solid") == true

func _attack() -> void:
	if wait_turn and atk_turn:
		wait_turn = false
		return
	if atk_turn:
		#attack_anim
		for box in atk_boxes:
			for body in box.get_overlapping_bodies():
				if body is CharacterBody2D and body.is_in_group("player"):
					body.take_damage()
					#print("damaged")
		atk_turn = false
		wait_turn = true
		for warn in atk_warns:
			warn.visible = false
		pivot.visible = true
		match (facing_direction):
			Vector2i.UP:
				sprite.play("atk_up")
			Vector2i.DOWN:
				sprite.play("atk_down")
			Vector2i.LEFT:
				sprite.play("atk_left")
			Vector2i.RIGHT:
				sprite.play("atk_right")
		await sprite.animation_finished
		pivot.visible = false
		_draw_move_arrow()
	return

func _declare_action() -> void:
	if !atk_turn:
		_draw_move_arrow()
	else:
		_draw_attack_warning()
	return

func _draw_move_arrow() -> void:
	move_pts = grid.get_point_path(grid_position, target)
	move_pts = (move_pts as Array).map(func (p): return p + grid.cell_size / 2.0)
	_update_facing_dir()
	match (facing_direction):
		Vector2i.UP:
			move_pivot.rotation_degrees = 180
		Vector2i.DOWN:
			move_pivot.rotation_degrees = 0
		Vector2i.LEFT:
			move_pivot.rotation_degrees = 90
		Vector2i.RIGHT:
			move_pivot.rotation_degrees = 270
	
	if move_pts.size() > 1 and !Global.enemy_intent_cells.has(tilemap.local_to_map(move_pts[cur_pt+1])):
		Global.enemy_intent_cells[tilemap.local_to_map(move_pts[cur_pt+1])] = self
	#print(Global.enemy_intent_cells)
	move_pivot.visible = true

func _draw_attack_warning() -> void:
	#rotate
	match (facing_direction):
		Vector2i.UP:
			atk_warn.position = Vector2(0,-32)
			pivot.rotation_degrees = 180
		Vector2i.DOWN:
			atk_warn.position = Vector2(0,32)
			pivot.rotation_degrees = 0
		Vector2i.LEFT:
			atk_warn.position = Vector2(-32,0)
			pivot.rotation_degrees = 90
		Vector2i.RIGHT:
			atk_warn.position = Vector2(32,0)
			pivot.rotation_degrees = 270
	#draw
	for warn in atk_warns:
		var cell = tilemap.local_to_map(warn.global_position)
		#check for entity
		if Global.occupied_cells.has(cell):
			var body = Global.occupied_cells[cell]
			if body.is_in_group("enemy"):
				continue
		#check for wall
		var tile_data = tilemap.get_cell_tile_data(cell)
		if tile_data.get_custom_data("solid") == true:
			continue
		warn.visible = true
	return

func _update_facing_dir() -> void:
	if move_pts.size() > 1:
		facing_direction  = move_pts[cur_pt+1] - move_pts[cur_pt]
		if facing_direction.y < 0:
			facing_direction = Vector2i.UP
		elif facing_direction.y > 0:
			facing_direction = Vector2i.DOWN
		elif facing_direction.x < 0:
			facing_direction = Vector2i.LEFT
		elif facing_direction.x > 0:
			facing_direction = Vector2i.RIGHT

func _update_facing_visual(_moving: bool = false):
	var prefix := "walk_"

	match facing_direction:
		Vector2i.UP:
			sprite.play(prefix + "up")
		Vector2i.DOWN:
			sprite.play(prefix + "down")
		Vector2i.LEFT:
			sprite.play(prefix + "left")
		Vector2i.RIGHT:
			sprite.play(prefix + "right")

func set_tile_map(new_tilemap: TileMapLayer):
	tilemap = new_tilemap
	_initialize_position()

func _initialize_position():
	if initialized or tilemap == null:
		return
	grid_position = tilemap.local_to_map(global_position)
	global_position = tilemap.map_to_local(grid_position)
	initialized = true

func take_damage():
	sprite.play("death")
	sprite.frame = 0
	Global.add_score(ceil(100 * Global.score_multiplier))
	var cell = tilemap.local_to_map(global_position)
	Global.occupied_cells.erase(cell)

	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(self, "modulate:a", 0.0, 0.2)

	tween.finished.connect(queue_free)
