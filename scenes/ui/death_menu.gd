extends CanvasLayer

@onready var death: AudioStreamPlayer = $Death
@onready var texture_rect1: TextureRect = $DeathMenu/MarginContainer/VBoxContainer/Control/TextureRect

var tween1 : Tween
var _timer : Timer

func ready() -> void:
	#player dies in global
	#global.death(call leveltransition death
	BeatManager._music_player.volume_db = 0
	
	texture_rect1.pivot_offset_ratio = Vector2(0.5, 0.5)
	
	var beat_length = 60.0 / 140
	await get_tree().create_timer(beat_length * .42).timeout
	_timer = Timer.new()
	_timer.wait_time = beat_length
	_timer.autostart = true
	_timer.timeout.connect(_on_beat)
	add_child(_timer)
	_timer.start()



func _on_return_to_menu_pressed() -> void:
	LevelTransition.change_scene_to("res://scenes/ui/main_menu.tscn")
	return

func _on_beat() -> void:
	var original_scale = Vector2.ONE
	var target_scale = Vector2(.95, .95)
	if tween1:
		tween1.kill()
	tween1 = create_tween()
	tween1.tween_property(texture_rect1, "scale", target_scale, 0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween1.tween_property(texture_rect1, "scale", original_scale, 0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
