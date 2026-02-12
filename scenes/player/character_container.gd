extends Node2D

@onready var h_box_container: HBoxContainer = $HealthBar/HBoxContainer
@onready var texture_rect: TextureRect = $HealthBar/HBoxContainer/TextureRect
const HEART = preload("res://assets/ui/heart.png")
const NOHEART = preload("res://assets/ui/noheart.png")
var heart_tweens: Array[Tween] = []

func _ready():
	BeatManager.beat.connect(_on_beat)
	%Player1.player_moved.connect(_on_move)
	%Player2.player_moved.connect(_on_move)
	Global.health_changed.connect(update_health_bar)
	update_health_bar()

#clear buffered inputs on move so they dont move at the same time
func _on_move():
	%Player1.clear_buffer()
	%Player2.clear_buffer()

func update_health_bar() -> void:
	for child in h_box_container.get_children():
		child.queue_free()

	for i in Global.max_player_health:
		var heart := TextureRect.new()
		
		heart.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		
		heart.texture = HEART if i < Global.player_health else NOHEART
		
		h_box_container.add_child(heart)

func _on_beat(_value: int = 0) -> void:
	var target_scale = Vector2(0.92, 0.92)
	var original_scale = Vector2.ONE
	
	for heart in h_box_container.get_children():
		if heart is TextureRect:
			
			heart.pivot_offset = heart.size / 2.0
			
			var tween := create_tween()
			tween.tween_property(heart, "scale", target_scale, 0.06)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_OUT)
			tween.tween_property(heart, "scale", original_scale, 0.06)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_IN)
