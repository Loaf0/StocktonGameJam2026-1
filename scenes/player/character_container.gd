extends Node2D

func _ready():
	%Player1.player_moved.connect(_on_move)
	%Player2.player_moved.connect(_on_move)

#clear buffered inputs on move so they dont move at the same time
func _on_move():
	%Player1.clear_buffer()
	%Player2.clear_buffer()
