extends Node2D

var start_position: Vector2
var target_position: Vector2
var travel_time: float
var speed_factor: float = 1.0

var elapsed := 0.0
var _popped := false

@export var start_scale: float = 0.0
@export var max_scale: float = 1.25
@export var log_strength: float = 6.0

func _ready():
	_update_visuals(0.0)

func _process(delta):
	if _popped:
		return

	elapsed += delta * speed_factor
	var t = clamp(elapsed / travel_time, 0.0, 1.0)

	_update_visuals(t)

	if t >= 1.0:
		_pop()

func _update_visuals(t: float):
	position = start_position.lerp(target_position, t)

	var log_t := log(1.0 + log_strength * t) / log(1.0 + log_strength)
	var s = lerp(start_scale, max_scale, log_t)
	scale = Vector2(s, s)

func _pop():
	_popped = true
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.1)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.06)
	tween.finished.connect(queue_free)
