extends CharacterBody2D

@export var my_phase: int
@export var tilemap: TileMapLayer

@export var move_duration := 0.12

var grid: AStarGrid2D

var grid_position: Vector2i
var target: Vector2i
var target_cell: Vector2i
var previous_cell: Vector2i
var move_pts: Array
var cur_pt: int

var can_act := false

var move_tween: Tween

var acted_this_beat := false
var facing_direction: Vector2i = Vector2i.DOWN
@onready var sprite = $Sprite2D
var is_moving := false


var atk_turn: bool = false

#on ready / player enter room / end of beat 2(3rd)
##locate the player
##find shortest path
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
	_declare_action()
	_update_facing_visual(true)

func _my_turn():
	if acted_this_beat == false:
		#move or attack logic here
		_move()
		
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
	_declare_action()
	if move_pts.is_empty():
		return
	else:
		# Add new cell immediately
		Global.occupied_cells[target_cell] = self
		cur_pt = 0
		if !is_blocked(tilemap.local_to_map(move_pts[cur_pt+1])):
			#clear previous cell before next enemy moves
			previous_cell = grid_position
			if previous_cell in Global.occupied_cells:
				Global.occupied_cells.erase(previous_cell)
			facing_direction  = move_pts[cur_pt+1] - move_pts[cur_pt]
			if facing_direction.y < 0:
				facing_direction = Vector2i.UP
			elif facing_direction.y > 0:
				facing_direction = Vector2i.DOWN
			elif facing_direction.x < 0:
				facing_direction = Vector2i.LEFT
			elif facing_direction.x > 0:
				facing_direction = Vector2i.RIGHT
			_update_facing_visual(true)
			animate_move(move_pts[cur_pt], move_pts[cur_pt+1])
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
	if Global.occupied_cells.has(cell):
		return true
	if Global.enemy_intent_cells.has(cell) and Global.enemy_intent_cells[cell] != self:
		return true
	return tile_data.get_custom_data("solid") == true

func _attack() -> void:
	return

func _declare_action() -> void:
	move_pts = grid.get_point_path(grid_position, target)
	move_pts = (move_pts as Array).map(func (p): return p + grid.cell_size / 2.0)
	$Line2D.points = move_pts
	if !Global.enemy_intent_cells.has(tilemap.local_to_map(move_pts[cur_pt+1])):
		Global.enemy_intent_cells[tilemap.local_to_map(move_pts[cur_pt+1])] = self
	#print(Global.enemy_intent_cells)
	return

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
