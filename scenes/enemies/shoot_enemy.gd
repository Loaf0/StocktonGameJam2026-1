extends Enemy

var cannon_ball = preload("res://scenes/enemies/cannon_ball.tscn")

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

func _my_turn():
	if acted_this_beat == false:
		#move or attack logic here
		if first_turn:
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

func _attack() -> void:
	if wait_turn and atk_turn:
		wait_turn = false
		return
	if atk_turn:
		#attack_anim
		var temp = cannon_ball.instantiate()
		temp.global_position = $Pivot/Spawn.global_position
		temp.dir = facing_direction
		temp.tilemap = tilemap
		add_sibling(temp)
		#print(temp.global_position)
		atk_turn = false
		wait_turn = true
		for warn in atk_warns:
			warn.visible = false
		pivot.visible = true
		await get_tree().create_timer(0.15).timeout
		pivot.visible = false
		_draw_move_arrow()
	return

func _declare_action() -> void:
	if !atk_turn:
		_draw_move_arrow()
	else:
		_draw_attack_warning()
	return


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
