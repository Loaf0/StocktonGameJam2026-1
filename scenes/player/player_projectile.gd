extends Area2D

@export var tilemap: TileMapLayer
var dir
@onready var player_projectile: AnimatedSprite2D = $Player_projectile

@export var move_duration := 0.12
var move_tween: Tween
var is_moving := false

func _ready() -> void:
	add_to_group("projectile")
	BeatManager.phase_changed.connect(_on_phase_changed)
	#check for entity
	_on_move_finished()

func _on_phase_changed(_phase: int):
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
	if !tilemap:
		return
	
	var cell = tilemap.local_to_map(global_position)
	#check for entity
	if Global.occupied_cells.has(cell):
		var body = Global.occupied_cells[cell]
		if body.is_in_group("enemy"):
			print("enemy hit")
			if body.has_method("take_damage"):
				body.take_damage()
		print("hit body")
		on_death()
	#check for wall
	var tile_data = tilemap.get_cell_tile_data(cell)
	if tile_data == null:
		on_death()
		return

	if tile_data.get_custom_data("solid") == true:
		on_death()
	
func on_death() -> void:
	if move_tween and move_tween.is_running():
		move_tween.kill()

	var pop_tween := create_tween()
	pop_tween.set_trans(Tween.TRANS_BACK)
	pop_tween.set_ease(Tween.EASE_OUT) 
	pop_tween.parallel().tween_property(self, "scale", Vector2.ONE * 1.4, 0.08)

	pop_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.18)

	pop_tween.tween_property(self, "scale", Vector2.ONE * 0.6, 0.08)
	
	pop_tween.finished.connect(queue_free)
