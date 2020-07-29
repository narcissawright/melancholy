extends CollisionShape
onready var tween = $Tween

"""
Dumb part of the collision here is that the bottom of it should be slanted
So that you slip off of edges instead of float there.

Something to fix in the future.
When I do that, shape.extents.x won't be relvant obviously because it's a custom shape
So I'll need some other solution for the scaling.
"""

func _ready() -> void:
	set_state(false)

func set_state(enabled):
	disabled = not enabled
	if enabled:
		tween.interpolate_property(
			self, "translation:z", 0.0, -0.3, 0.2, 
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.interpolate_property(
			self, "shape:extents:x", 0.1, 0.4, 0.2, 
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
	else:
		tween.stop_all()
		translation.z = 0.0
		shape.extents.x = 0.1
		
