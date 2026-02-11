extends TileMapLayer
class_name Room

@export var player_spawn_1 : Vector2 = Vector2(10,10)
@export var player_spawn_2 : Vector2 = Vector2(12,10)

@export var enemy_spawn_points : Array[Vector2] = []

@onready var enemy_spawner: Node = $EnemySpawner

func _ready() -> void:
	if enemy_spawner:
		enemy_spawner.spawn_room_enemies(self, enemy_spawn_points)
