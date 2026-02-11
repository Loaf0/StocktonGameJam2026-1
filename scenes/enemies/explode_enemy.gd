extends Enemy

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

func _my_turn():
	if acted_this_beat == false:
		#move or attack logic here
		if first_turn:
			first_turn = false
		elif !atk_turn:
			_move()
			atk_turn = true
		
		_declare_action()
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
		#attack
		atk_turn = false
		wait_turn = true
		_draw_move_arrow()
	return

func _declare_action() -> void:
	if !atk_turn:
		_draw_move_arrow()
	else:
		_draw_attack_warning()
	return


func _draw_attack_warning() -> void:
	#use attack width
	#draw
	
	pass
