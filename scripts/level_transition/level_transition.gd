extends CanvasLayer

@onready var fade_overlay : ColorRect = $Transition.get_child(0)
@onready var match_start: AudioStreamPlayer = $MatchStart

var scene_to_load : String
var transition_tween : Tween
var is_transitioning := false

func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS

func change_scene_to(scene_path : String) -> void:
	scene_to_load = scene_path
	get_tree().paused = true
	
	var fade_time = 60.0 / BeatManager.bpm * 2
	var tween = create_tween()
	fade_overlay.visible = true
	tween.tween_property(fade_overlay.material, "shader_parameter/radius", 0.0, fade_time)
	await tween.finished

func _load_new_scene() -> void:
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", scene_to_load)

func start_game(scene_path: String, bpm: float) -> void:
	if is_transitioning:
		return
	
	Global.difficulty = 1.0
	is_transitioning = true
	scene_to_load = scene_path
	
	BeatManager.bpm = bpm
	
	var fade_time := 60.0 / bpm
	
	get_tree().paused = true
	fade_overlay.visible = true
	
	var mat := fade_overlay.material as ShaderMaterial
	transition_tween = create_tween().set_trans(Tween.TRANS_SINE)
	
	mat.set_shader_parameter("radius", 2.0)
	
	transition_tween.tween_property(
		mat,
		"shader_parameter/radius",
		0.0,
		fade_time
	)
	
	await transition_tween.finished
	
	match_start.play()
	await match_start.finished
	
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_to_load)
	
	await get_tree().create_timer(0.1).timeout
	
	get_tree().paused = true
	
	transition_tween = create_tween().set_trans(Tween.TRANS_SINE)
	
	transition_tween.tween_property(
		mat,
		"shader_parameter/radius",
		2.0,
		fade_time
	)
	
	await transition_tween.finished
	
	fade_overlay.visible = false
	get_tree().paused = false
	BeatManager.start_song(bpm)
	is_transitioning = false
