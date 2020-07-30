extends StaticBody

# I need the Shield Collision to be a child of the player's Kinematicbody

onready var anim = $AnimationPlayer
var active = false
var shieldbash_timer:int = 0

func _physics_process(t:float) -> void:
	if shieldbash_timer > 0:
		shieldbash_timer -= 1
	
	# If you just pressed shield
	if Input.is_action_just_pressed("shield"):
		if can_shield_bash():
			# Perform shield bash
			anim.play("shield_bash")
			anim.seek(0)
			active = true
		elif not active:
			# Take shield out
			anim.play("take_out")
			active = true
	
	# If you're NOT pressing shield...
	elif not Input.is_action_pressed("shield"):
		if active and not anim.is_playing():
			anim.play("put_away")
			active = false
			shieldbash_timer = 10 # frames
	
func can_shield_bash() -> bool:
	if shieldbash_timer == 0: 
		return false
	if anim.is_playing():
		match anim.current_animation:
			"put_away":
				anim.seek(0, true)
				return true
			"shield_bash":
				if anim.current_animation_position < anim.current_animation_length * 0.5: 
					return false
	return true
