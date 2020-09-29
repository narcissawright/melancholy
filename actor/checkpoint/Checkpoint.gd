extends MeshInstance

func _on_CheckpointArea_body_entered(body: Node) -> void:
	if body == Player:
		Events.emit_signal("checkpoint", global_transform.origin)
