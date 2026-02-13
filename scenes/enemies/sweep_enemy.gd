extends Enemy

@onready var atk_warn_2: Sprite2D = $AtkWarn2
@onready var atk_warn_3: Sprite2D = $AtkWarn3


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
	atk_warns.append(atk_warn_2)
	atk_warns.append(atk_warn_3)
	atk_boxes.append($AtkWarn/AtkBox)
	atk_boxes.append($AtkWarn2/AtkBox)
	atk_boxes.append($AtkWarn3/AtkBox)
	for warn in atk_warns:
		warn.visible = true
		warn.scale = Vector2.ZERO

func _draw_attack_warning() -> void:
	if dead:
		return
	#rotate
	match (facing_direction):
		Vector2i.UP:
			atk_warn.position = Vector2(0,-32)
			atk_warn_2.position = Vector2(-32,-32)
			atk_warn_3.position = Vector2(32,-32)
			pivot.rotation_degrees = 180
		Vector2i.DOWN:
			atk_warn.position = Vector2(0,32)
			atk_warn_2.position = Vector2(-32,32)
			atk_warn_3.position = Vector2(32,32)
			pivot.rotation_degrees = 0
		Vector2i.LEFT:
			atk_warn.position = Vector2(-32,0)
			atk_warn_2.position = Vector2(-32,-32)
			atk_warn_3.position = Vector2(-32,32)
			pivot.rotation_degrees = 90
		Vector2i.RIGHT:
			atk_warn.position = Vector2(32,0)
			atk_warn_2.position = Vector2(32,-32)
			atk_warn_3.position = Vector2(32,32)
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
		_make_warn_visible(true)
	return
