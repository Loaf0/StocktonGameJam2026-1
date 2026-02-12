extends Node2D

func _ready() -> void:
	add_to_group("enemy manager")
	BeatManager.phase_changed.connect(_on_phase_changed)

func _on_phase_changed(phase: int):
	for enemy in get_tree().get_nodes_in_group("enemy"):
		await get_tree().process_frame
		if enemy:
			enemy.on_phase_changed(phase)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if phase == 3 and enemy.atk_turn:
			if enemy:
				enemy._declare_action()
	Global.enemy_intent_cells.clear()
