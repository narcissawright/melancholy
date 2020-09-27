extends Node

# put level actors as children of this

var actor_list := []

func _ready() -> void:
	Events.connect("checkpoint", self, "save_actor_state")
	Events.connect("respawn", self, "load_actor_state")
	save_actor_state()

func save_actor_state() -> void:
	actor_list = []
	for actor in get_children():
		var scene = PackedScene.new()
		scene.pack(actor)
		actor_list.append(scene)
	
func load_actor_state() -> void:
	for actor in get_children():
		actor.free()
	for i in range (actor_list.size()):
		add_child(actor_list[i].instance())
