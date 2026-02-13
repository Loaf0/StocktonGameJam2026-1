extends CanvasLayer

enum MenuState {
	INTRO,
	MAIN,
	DIFFICULTY,
	OPTIONS,
	TUTORIAL,
	CREDITS
}
var current_state: MenuState = MenuState.INTRO

@onready var title: AudioStreamPlayer = $Title

@onready var texture_rect1 = $IntroMenu/MarginContainer/VBoxContainer/Control/TextureRect
@onready var texture_rect2 = $MainMenu/MarginContainer/VBoxContainer/Control/TextureRect
@onready var texture_rect3 = $Credits/TextureRect
var tween1 : Tween
var tween2 : Tween
var tween3 : Tween
var _timer : Timer

# intro
@onready var intro_anim: AnimatedSprite2D = $IntroAnim
@onready var start_up: AudioStreamPlayer = $StartUp
@onready var intro_menu: Control = $IntroMenu

# main menu
@onready var main_menu: Control = $MainMenu

# difficulty
@onready var difficulty_menu : Control = $Difficulty

# options
@onready var options: Control = $Options
@onready var sfx_volume: HSlider = $Options/MarginContainer/VBoxContainer/SFX
@onready var msfx_volume: HSlider = $Options/MarginContainer/VBoxContainer/MUSIC
var slider_click = preload("res://assets/audio/ui_effects/Switch.mp3")

#credits
@onready var credits: Control = $Credits

#tutorial
@onready var tutorial : Control = $Tutorial

func _ready() -> void:
	_set_menu_state(MenuState.INTRO)
	
	intro_anim.play("default")
	
	Save.load_settings()
	sfx_volume.value = Global.sfx_volume
	msfx_volume.value = Global.music_volume

	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(Global.sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(Global.music_volume))
	
	start_up.play(1.45)
	await start_up.finished
	
	texture_rect1.pivot_offset_ratio = Vector2(0.5, 0.5)
	texture_rect2.pivot_offset_ratio = Vector2(0.5, 0.5)
	texture_rect3.pivot_offset_ratio = Vector2(0.5, 0.5)
	
	$Title.play()
	var beat_length = 60.0 / 165
	await get_tree().create_timer(beat_length * .92).timeout
	_timer = Timer.new()
	_timer.wait_time = beat_length
	_timer.autostart = true
	_timer.timeout.connect(_on_beat)
	add_child(_timer)
	_timer.start()


func _on_beat() -> void:
	var original_scale = Vector2.ONE
	var target_scale = Vector2(.95, .95)
	if tween1:
		tween1.kill()
	tween1 = create_tween()
	tween1.tween_property(texture_rect1, "scale", target_scale, 0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween1.tween_property(texture_rect1, "scale", original_scale, 0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	if tween2:
		tween2.kill()
	tween2 = create_tween()
	tween2.tween_property(texture_rect2, "scale", target_scale, 0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween2.tween_property(texture_rect2, "scale", original_scale, 0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	if tween3:
		tween3.kill()
	tween3 = create_tween()
	tween3.tween_property(texture_rect3, "scale", target_scale, 0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween3.tween_property(texture_rect3, "scale", original_scale, 0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func _process(_delta: float) -> void:
	if current_state == MenuState.INTRO:
		if _intro_skip_pressed():
			_go_to_main_menu()

func _intro_skip_pressed() -> bool:
	return (
		Input.is_action_just_pressed("attack1")
		or Input.is_action_just_pressed("attack2")
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	)

func _set_menu_state(state: MenuState) -> void:
	current_state = state

	intro_menu.visible = state == MenuState.INTRO
	intro_anim.visible = state == MenuState.INTRO

	main_menu.visible = state == MenuState.MAIN
	difficulty_menu.visible = state == MenuState.DIFFICULTY
	options.visible = state == MenuState.OPTIONS
	credits.visible = state == MenuState.CREDITS
	tutorial.visible = state == MenuState.TUTORIAL

func _go_to_main_menu() -> void:
	_set_menu_state(MenuState.MAIN)

func _on_play_pressed() -> void:
	_go_to_difficulty()

func _on_options_pressed() -> void:
	_go_to_options()

func _on_credits_pressed() -> void:
	_set_menu_state(MenuState.CREDITS)

func _on_tutorial_pressed() -> void:
	_set_menu_state(MenuState.TUTORIAL)


func _on_quit_pressed() -> void:
	get_tree().quit()

func _go_to_difficulty() -> void:
	_set_menu_state(MenuState.DIFFICULTY)

func _on_easy_pressed() -> void:
	Global.max_player_health = 5
	Global.player_health = 5
	_on_difficulty_selected(130.0)

func _on_normal_pressed() -> void:
	Global.max_player_health = 4
	Global.player_health = 4
	_on_difficulty_selected(140.0)

func _on_hard_pressed() -> void:
	Global.max_player_health = 3
	Global.player_health = 3
	_on_difficulty_selected(150.0)

func _on_difficulty_selected(bpm : float) -> void:
	var tween := create_tween()
	tween.parallel().tween_property(
		title,
		"volume_db",
		-80,
		0.5
	)
	await LevelTransition.start_game("res://scenes/maps/test_maps/movement_test.tscn", bpm)

func _on_difficulty_back_pressed() -> void:
	_go_to_main_menu()

func _go_to_options() -> void:
	_set_menu_state(MenuState.OPTIONS)

func _on_msfx_volume_value_changed(_value: float) -> void:
	if int(_value) % 15 == 0:
		_play_one_shot_sfx(slider_click, 0.05, 0.0, 0.0, "Music")
	var bus_index = AudioServer.get_bus_index("Music") 
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(_value))

func _on_msfx_volume_drag_ended(value_changed: bool) -> void:
	if value_changed:
		var bus_index = AudioServer.get_bus_index("Music")
		var slider_value = msfx_volume.value
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(slider_value))
		Global.music_volume = slider_value 
	
func _on_sfx_volume_value_changed(_value: float) -> void:
	if int(_value) % 15 == 0:
		_play_one_shot_sfx(slider_click, 0.05, 0.0)
	var bus_index = AudioServer.get_bus_index("SFX") 
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(_value))

func _on_sfx_volume_drag_ended(value_changed: bool) -> void:
	if value_changed:
		var bus_index = AudioServer.get_bus_index("SFX") 
		var slider_value = sfx_volume.value 
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(slider_value))
		Global.sfx_volume = slider_value 

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

func _on_options_return_pressed() -> void:
	_go_to_main_menu()
	Save.save_all()

func _on_check_button_toggled(toggled_on: bool) -> void:
	Global.two_player_mode = toggled_on
