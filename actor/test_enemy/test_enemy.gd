extends KinematicBody
var time:float = 0.0
var velocity := Vector3.ZERO
var player_nearby:bool = false

onready var material = $Mesh.get_surface_material(0)
onready var projectile = preload("res://actor/test_enemy/projectile.tscn")
var fire_cooldown = 0
var locked:int = 0

func _physics_process(t: float) -> void:
	time += t
	time = fmod(time, TAU)
	
	if locked > 0:
		locked -= 1
		if locked == 0:
			material.set_shader_param("damaged", false)
	else:
		velocity.z = sin(time)
		velocity.y += Level.GRAVITY * t
		velocity.x = lerp(velocity.x, 0.0, 0.15)
		velocity = move_and_slide(velocity, Vector3.UP)
	
		if fire_cooldown > 0:
			fire_cooldown -= 1
		elif player_nearby:
			fire()
	
func fire() -> void:
	fire_cooldown = 60
	var p = projectile.instance()
	p.translation = translation
	p.velocity = (Player.head_position - translation).normalized() * 14.0
	p.projectile_owner = self
	Level.Projectiles.add_child(p)

func hit(_collision: Dictionary) -> String:
	material.set_shader_param("damaged", true)
	locked = 10
	return "die"

func hit_by_explosion(_explosion_center:Vector3) -> void:
	queue_free()

func _on_detector_body_entered(body: Node) -> void:
	if body == Player.kinematicbody:
		player_nearby = true

func _on_detector_body_exited(body: Node) -> void:
	if body == Player.kinematicbody:
		player_nearby = false
