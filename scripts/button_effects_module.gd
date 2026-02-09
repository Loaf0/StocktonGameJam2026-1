extends Node
class_name button_effects_module

@export var ease_type : Tween.EaseType
@export var trans_type : Tween.TransitionType
@export var anim_duration : float = 0.07
@export var scale_amount : Vector2 = Vector2(1.1, 1.1)
@export var rotation_amount : float = 3.0

@onready var button : Button = get_parent()
const click_sfx = preload("res://assets/audio/kenny/ui/click2.ogg")
const mouse_click = preload("res://assets/audio/kenny/ui/mouseclick1.ogg")
const mouse_release = preload("res://assets/audio/kenny/ui/mouserelease1.ogg")

var tween : Tween

func _ready() -> void:
	button.mouse_entered.connect(_on_mouse_hovered.bind(true))
	button.mouse_exited.connect(_on_mouse_hovered.bind(false))
	button.pressed.connect(_on_button_pressed)
	button.pivot_offset_ratio = Vector2(0.5, 0.5)

func _on_button_pressed() -> void:
	reset_tween()
	tween.tween_property(button, "scale", 
		scale_amount, anim_duration).from(Vector2(0.8, 0.8))
	tween.tween_property(button, "rotation_degrees", 
		rotation_amount * [-1,1].pick_random(), anim_duration).from(0)
	_play_one_shot_sfx(click_sfx)

func _on_mouse_hovered(hovered : bool) -> void:
	reset_tween()
	tween.tween_property(button, "scale", 
		scale_amount if hovered else Vector2.ONE, anim_duration)
	tween.tween_property(button, "rotation_degrees", 
		rotation_amount * [-1,1].pick_random() if hovered else 0.0, anim_duration)
	_play_one_shot_sfx(mouse_click if hovered else mouse_release, 0.05, 0.0, -25)

func reset_tween() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(ease_type).set_trans(trans_type).set_parallel(true)

func _play_one_shot_sfx(sfx: AudioStream, pitch_range: float = 0.05, start_time: float = 0.0, volume_db: float = 0.0, bus_name: String = "SFX") -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = sfx
	player.bus = bus_name
	pitch_range = clamp(pitch_range, 0.0, 0.08)
	player.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	player.play(start_time)
