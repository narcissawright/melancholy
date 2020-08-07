extends AnimationPlayer

"""
I could really see using animationplayer for more properties,
such as animating the shield slide interpolation value ??
"""

var active = false
var shieldbash_timer:int = 0 # I should try to remove this and maybe set a bool in animationplayer
var bash_str:float setget , _get_bash_strength
var sliding = false

func _ready() -> void:
	Events.connect("player_damaged", self, "on_player_damaged")

func _physics_process(_t:float) -> void:
	if sliding:
		if Game.player.horizontal_velocity().length() < 5.0:
			sliding = false
			Game.player.unlockplayer("shield_slide")
	
	if shieldbash_timer > 0:
		shieldbash_timer -= 1
	
	if not Game.player.is_locked():
		# If you just pressed shield
		if not active and Input.is_action_pressed("shield"):
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

func slide() -> void:
	active = true
	sliding = true
	Game.player.lockplayer("shield_slide")
	play("take_out")
	seek(current_animation_length)

func put_away() -> void:
	if not sliding:
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

func on_player_damaged() -> void:
	if active:
		put_away()
