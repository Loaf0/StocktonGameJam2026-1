extends CanvasLayer

@export var phase_icons: Array[Texture2D] = [
	preload("res://assets/ui/rangerico.png"),
	preload("res://assets/ui/knightico.png"),
	preload("res://assets/ui/skeltonico.png"),
	preload("res://assets/ui/swordico.png")
]

@export var icon_scene: PackedScene = preload("res://scenes/ui/beat_bar_icon.tscn")
@export var icon_distance: float = 250.0
@export var beats_visible: int = 3
@export var far_icon_speed: float = 0.35

func _ready():
	BeatManager.phase_changed.connect(_on_phase_changed)

func _on_phase_changed(phase: int):
	spawn_icon(phase, -1)
	spawn_icon(phase, 1)

func spawn_icon(phase: int, direction: int):
	var viewport := get_viewport().get_visible_rect().size
	var center := viewport * 0.5
	center.y = viewport.y * 0.925

	var seconds_per_beat = 60.0 / BeatManager.bpm

	var icon = icon_scene.instantiate()
	icon.start_position = center + Vector2(icon_distance * direction, 0)
	icon.target_position = center
	icon.travel_time = seconds_per_beat
	icon.speed_factor = far_icon_speed
	icon.position = icon.start_position

	if icon.has_node("Sprite2D"):
		icon.get_node("Sprite2D").texture = phase_icons[phase]

	add_child(icon)
