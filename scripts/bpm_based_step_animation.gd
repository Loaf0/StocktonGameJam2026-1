extends AnimatedSprite2D

@export var beat_multiplier : float = 1.0

func _ready():
	BeatManager.beat.connect(_on_beat)

func _on_beat(_beat_count: int) -> void:
	if animation == "":
		return
	if not sprite_frames:
		return
	
	var frame_count = sprite_frames.get_frame_count(animation)
	frame = (frame + int(beat_multiplier)) % frame_count
