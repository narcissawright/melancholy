extends AnimationPlayer

""" 
There's some issues here with awkward node references and unoptimized code.
"""

var active = false
var shieldbash_timer:int = 0
var bash_str:float setget , _get_bash_strength
var sliding = false

# Sort of ugly node references here, rather frail.
onready var shield_pos = $"../MelanieModel/Armature/Skeleton/ShieldPos"
onready var mesh = $"../ShieldMesh"

func _ready() -> void:
	Events.connect("player_damaged", self, "on_player_damaged")
	
func can_shield() -> bool:
	if Player.is_locked(): return false
	if Player.ledgegrabbing: return false
	return true

func _physics_process(_t:float) -> void:
	
	if sliding:
		if Player.horizontal_velocity().length() < 5.0:
			sliding = false
			Player.unlockplayer("shield_slide")
	
	if shieldbash_timer > 0:
		shieldbash_timer -= 1
	
	if can_shield():
		# If you just pressed shield
		if not active and Input.is_action_pressed("shield"):
			if can_shield_bash():
				# Perform shield bash
				Player.kinematicbody.anim_tree['parameters/ShieldMovement/playback'].travel("Bash")
				play("shield_bash")
				seek(0)
				active = true
			else:
				# Take shield out
				
				""" Issue here where it shouldnt start this animation from the beginning I think if the shield is currently being put away still... ?? """
				Player.kinematicbody.anim_state_machine.travel("ShieldMovement")
				Player.kinematicbody.anim_tree['parameters/ShieldMovement/playback'].start("TakeOut")
				play("take_out")
				active = true
		
		# If you're NOT pressing shield...
		elif not Input.is_action_pressed("shield"):
			if active and not is_playing():
				put_away()
				shieldbash_timer = 10 # frames

	if not active:
		# Follow Bone Attachment (bobbing on Melanie's back)
		mesh.transform = shield_pos.transform.rotated(Vector3.UP, PI)

func exit_shield_state() -> void:
	if Player.kinematicbody.anim_state_machine.get_current_node() == "ShieldMovement":
		Player.kinematicbody.anim_state_machine.travel("BaseMovement")

func slide() -> void:
	active = true
	sliding = true
	Player.lockplayer("shield_slide")
	play("take_out")
	seek(current_animation_length)

func put_away() -> void:
	if not sliding:
		Player.kinematicbody.anim_tree['parameters/ShieldMovement/playback'].travel("PutAway")
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
