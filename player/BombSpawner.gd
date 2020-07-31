extends Position3D

onready var spawn_area = $SpawnArea
onready var bomb = preload("res://player/Bomb.tscn")

var current_bomb:Node

func can_spawn_bomb() -> bool:
	if spawn_area.get_overlapping_bodies().size() == 0:
		return true
	return false

func can_throw_bomb() -> bool:
	return current_bomb.is_ready
	
func throw_bomb(velocity) -> void:
	# Reparent and launch
	remove_child(current_bomb)
	Game.add_child(current_bomb)
	current_bomb.global_transform.origin = global_transform.origin
	current_bomb.throw(velocity)
	
func spawn_bomb() -> void:
	current_bomb = bomb.instance()
	add_child(current_bomb)
	Game.player.jewels -= 5
