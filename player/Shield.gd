extends AnimationPlayer

var active = false
var shieldbash_timer:int = 0
var bash_str:float setget , _get_bash_strength

func _physics_process(_t:float) -> void:
	if shieldbash_timer > 0:
		shieldbash_timer -= 1
	
	# If you just pressed shield
	if Input.is_action_just_pressed("shield"):
		if can_shield_bash():
			# Perform shield bash
			play("shield_bash")
			seek(0)
			active = true
		elif not active:
			# Take shield out
			play("take_out")
			active = true
	
	# If you're NOT pressing shield...
	elif not Input.is_action_pressed("shield"):
		if active and not is_playing():
			put_away()
			shieldbash_timer = 10 # frames

func put_away() -> void:
	play("put_away")
	active = false

func can_shield_bash() -> bool:
	if shieldbash_timer == 0: 
		return false
	if is_playing():
		match current_animation:
			"put_away":
				seek(0, true)
				return true
			"shield_bash":
				if current_animation_position < current_animation_length * 0.5: 
					return false
	return true

func _get_bash_strength() -> float:
	if current_animation == "shield_bash":
		return 1.0 - (current_animation_position / current_animation_length)
	return 0.0
	
