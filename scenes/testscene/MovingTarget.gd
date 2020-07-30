extends KinematicBody
var time:float = 0.0
var velocity := Vector3.ZERO
var player_nearby:bool = false

onready var projectile = preload("res://scenes/projectile.tscn")
var fire_cooldown = 0

func _physics_process(t: float) -> void:
	time += t
	time = fmod(time, TAU)
	velocity.z = sin(time)
	velocity.y += Game.GRAVITY * t
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
	p.velocity = (Game.player.position - translation).normalized() * 14.0 + Vector3.UP * 2.0
	Game.add_child(p)

func _on_detector_body_entered(body: Node) -> void:
	if body == Game.player:
		player_nearby = true

func _on_detector_body_exited(body: Node) -> void:
	if body == Game.player:
		player_nearby = false
