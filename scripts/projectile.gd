extends Sprite2D

@export var tilemap: TileMapLayer
var dir

@export var move_duration := 0.12
var move_tween: Tween
var is_moving := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	BeatManager.phase_changed.connect(_on_phase_changed)
	var cell = tilemap.local_to_map(global_position)
	#check for entity
	if Global.occupied_cells.has(cell):
		if Global.occupied_cells[cell].is_in_group("player"):
			print("player")
			#deal dmg
		queue_free()
	#check for wall
	var tile_data = tilemap.get_cell_tile_data(cell)
	if tile_data.get_custom_data("solid") == true:
		queue_free()


func _on_phase_changed(phase: int):
	match(dir):
		Vector2i.UP:
			animate_move(global_position, (global_position + Vector2(0, -32)))
		Vector2i.DOWN:
			animate_move(global_position, (global_position + Vector2(0, 32)))
		Vector2i.LEFT:
			animate_move(global_position, (global_position + Vector2(-32, 0)))
		Vector2i.RIGHT:
			animate_move(global_position, (global_position + Vector2(32, 0)))
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

func _on_move_finished():
	is_moving = false
	
	var cell = tilemap.local_to_map(global_position)
	#check for entity
	if Global.occupied_cells.has(cell):
		var body = Global.occupied_cells[cell]
		if body.is_in_group("player"):
			print("player")
			if body.has_method("take_damage"):
				body.take_damage()
		queue_free()
	#check for wall
	var tile_data = tilemap.get_cell_tile_data(cell)
	if tile_data.get_custom_data("solid") == true:
		queue_free()
	
