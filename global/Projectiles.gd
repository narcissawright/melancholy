extends Spatial

func _ready() -> void:
	Events.connect("respawn", self, "empty")

func empty() -> void:
	for projectile in get_children():
		projectile.queue_free()
