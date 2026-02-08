extends CanvasLayer

@export var phase_icons: Array[Texture2D] = [
	preload("res://assets/ui/rangerico.png"),
	preload("res://assets/ui/knightico.png"),
	preload("res://assets/ui/skeltonico.png"),
	preload("res://assets/ui/swordico.png")
]

@export var spacing : float = 160.0
@export var travel_time : float = 0.12
@export var hit_scale : Vector2 = Vector2(1.25, 1.25)
@export var hit_scale_time : float = 0.08
@export var settle_scale_time : float = 0.06

@onready var icons_root : Control = $Icons

var icons : Array[TextureRect] = []
var center_x : float
var tween : Tween
var phase_index : int = 0

func _ready():
	center_x = get_viewport().get_visible_rect().size.x * 0.5
	_setup_icons()
	BeatManager.phase_changed.connect(_on_phase_changed)
	print("Icons created:", icons.size())


func _setup_icons():
	icons.clear()

	var half := phase_icons.size() / 2.0

	for i in range(phase_icons.size()):
		var icon := TextureRect.new()
		icon.texture = phase_icons[i]

		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = icon.texture.get_size()

		icon.position = Vector2(
			center_x + (i - half) * spacing,
			0
		)

		icons_root.add_child(icon)
		icons.append(icon)
	
func _on_phase_changed(phase: int):
	phase_index = phase
	_advance_icons()
	_pulse_phase_icon(phase)

func _pulse_phase_icon(phase: int):
	if phase < 0 or phase >= icons.size():
		return

	var icon := icons[phase]

	var pulse := create_tween()
	pulse.tween_property(icon, "scale", hit_scale, hit_scale_time)
	pulse.tween_property(icon, "scale", Vector2.ONE, settle_scale_time)

func _advance_icons():
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()

	for i in range(icons.size()):
		var icon := icons[i]

		# compute wrapped offset from current phase
		var ico_offset = i - phase_index
		if ico_offset > icons.size() / 2:
			ico_offset -= icons.size()
		elif ico_offset < -icons.size() / 2:
			ico_offset += icons.size()

		var target_x = center_x + ico_offset * spacing

		tween.parallel().tween_property(
			icon,
			"position:x",
			target_x,
			travel_time
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _pulse_center_icon():
	var closest: TextureRect = null
	var best_dist := INF

	for icon in icons:
		var d = abs(icon.position.x - center_x)
		if d < best_dist:
			best_dist = d
			closest = icon

	if closest == null:
		return

	var pulse := create_tween()
	pulse.tween_property(closest, "scale", hit_scale, hit_scale_time)
	pulse.tween_property(closest, "scale", Vector2.ONE, settle_scale_time)
