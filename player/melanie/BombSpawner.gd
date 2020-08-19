extends Position3D

onready var spawn_area = $SpawnArea
onready var bomb = preload("res://actor/bomb/Bomb.tscn")

var current_bomb:Node
var holding = false

const jewel_cost:int = 5

onready var tween = $Tween

func _ready() -> void:
	Events.connect("player_damaged", self, "on_player_damaged")

func process_state() -> void:
	#translation.y = Game.player.get_node("melanie_test/AnimationPlayer").get_animation("Walk").get_track("Spine1").translation.y
	
	if not Game.player.shield.active:
		if Input.is_action_just_pressed("subweapon"):
			
			if holding: # If you are already holding the bomb, throw it.
				var velocity = Game.player.forwards()*10.0 + Vector3.UP*5.0
				velocity += Game.player.velocity * 0.3
				throw_bomb_asap(velocity)
				
			elif not Game.player.is_locked() and can_spawn_bomb(): # If a bomb can be spawned, do so.
				spawn_bomb()
	
	elif holding: 
		drop_bomb()

# Spawn
func can_spawn_bomb() -> bool:
	if Game.player.jewels >= jewel_cost:
		if spawn_area.get_overlapping_bodies().size() == 0:
			return true
	return false
	
func spawn_bomb() -> void:
	current_bomb = bomb.instance()
	add_child(current_bomb)
	holding = true
	Game.player.jewels -= jewel_cost
	Game.player.lockplayer_for_frames(10)
	tween.stop_all()
	tween.interpolate_property(Game.player.anim_tree, 'parameters/BombBlend/blend_amount', null, 1.0, 0.1)
	tween.start()

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
	tween.stop_all()
	if velocity != Vector3.ZERO:
		# don't slow player when dropping, only throwing.
		Game.player.lockplayer_for_frames(10)
		
		tween.interpolate_property(Game.player.anim_tree, 'parameters/BombBlend/blend_amount', null, 0.0, 0.1)
	else:
		tween.interpolate_property(Game.player.anim_tree, 'parameters/BombBlend/blend_amount', null, 0.0, 0.1)
	
	tween.start()

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