extends Position3D

"""
Issues:
- no custom shader logic, particles, lighting, etc.
- doesnt check for jewel requirement
- no sfx
"""

onready var spawn_area = $SpawnArea
onready var bomb = preload("res://player/Bomb.tscn")

var current_bomb:Node
var holding = false

func _ready() -> void:
	Events.connect("player_damaged", self, "on_player_damaged")

func process_state() -> void:
	if not Game.player.shield.active:
		if Input.is_action_just_pressed("subweapon"):
			
			if holding: # If you are already holding the bomb, throw it.
				var velocity = Game.player.forwards()*10.0 + Vector3.UP*5.0
				throw_bomb_asap(velocity)
				
			elif can_spawn_bomb(): # If a bomb can be spawned, do so.
				spawn_bomb()
	
	elif holding: 
		drop_bomb()

# Spawn
func can_spawn_bomb() -> bool:
	if spawn_area.get_overlapping_bodies().size() == 0:
		return true
	return false
	
func spawn_bomb() -> void:
	current_bomb = bomb.instance()
	add_child(current_bomb)
	holding = true
	Game.player.jewels -= 5
	Game.player.lockplayer_for_frames(10)

# Buffered Throws
func throw_bomb_asap(velocity) -> void:
	if not current_bomb.anim.is_connected("animation_finished", self, "buffered_bomb_throw_ready"):
		if current_bomb.is_ready:
			throw_bomb(velocity)
		else:
			current_bomb.anim.connect("animation_finished", self, "buffered_bomb_throw_ready", [velocity], CONNECT_ONESHOT)

func buffered_bomb_throw_ready(anim_name:String, velocity:Vector3) -> void:
	if anim_name == "bomb_pull":
		throw_bomb(velocity)

# Throw
func throw_bomb(velocity) -> void:
	# Reparent and launch
	current_bomb.reparent_to_game_world()
	current_bomb.throw(velocity)
	if velocity != Vector3.ZERO:
		# don't slow player when dropping, only throwing.
		Game.player.lockplayer_for_frames(10)

# Drop
func drop_bomb() -> void:
	throw_bomb_asap(Vector3.ZERO)

# Collided while holding
func _on_SpawnArea_body_entered(_body: Node) -> void:
	if holding:
		holding = false
		current_bomb.explode()

func on_player_damaged() -> void:
	if holding:
		drop_bomb()
