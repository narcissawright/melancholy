tool
extends Sprite

onready var pos = $Light

func _process(_delta:float) -> void:
	if Engine.editor_hint:
		update_position()

func update_position() -> void:
	var pos2d:Vector2 = pos.position.normalized()
	var light_vec := Vector3(pos2d.x, -pos2d.y, 0.35).normalized()
	material.set_shader_param("light_vec", light_vec)
