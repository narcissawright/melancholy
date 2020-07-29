extends KinematicBody
var time:float = 0.0
var velocity := Vector3.ZERO

func _physics_process(t: float) -> void:
	time += t
	time = fmod(time, TAU)
	velocity.z = sin(time)
	velocity.y += Game.GRAVITY * t
	velocity.x = lerp(velocity.x, 0.0, 0.15)
	velocity = move_and_slide(velocity, Vector3.UP)
	
