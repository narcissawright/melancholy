''' To be child of Player '''

extends MeshInstance
onready var tween:Tween = $'ShieldTween'
const SHIELD_MIN_SIZE := Vector3(0.92,0.96,0.92)
var active:bool = false

func _input(event: InputEvent) -> void:
	if event.is_action("shield"):
		if event.is_pressed():
			active = true
			tween.stop_all()
			tween.interpolate_property(self, "scale", SHIELD_MIN_SIZE, Vector3.ONE, 0.20, Tween.TRANS_CUBIC, Tween.EASE_OUT)
			tween.interpolate_property(get_surface_material(0), 'shader_param/external_opacity', 0.0, 1.0, 0.15, Tween.TRANS_CUBIC, Tween.EASE_OUT)
			tween.start()
		else:
			active = false
			tween.stop_all()
			tween.interpolate_property(self, "scale", Vector3.ONE, SHIELD_MIN_SIZE, 0.20, Tween.TRANS_CUBIC, Tween.EASE_IN)
			tween.interpolate_property(get_surface_material(0), 'shader_param/external_opacity', 1.0, 0.0, 0.15, Tween.TRANS_CUBIC, Tween.EASE_IN)
			tween.start()
