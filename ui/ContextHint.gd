extends Node2D

"""
Need to be able to fade individual context hints
instead of the entire system I think

That means Tween is probably superior to AnimationPlayer
And I suppose I should set a bool in the node list for
showing or not showing currently.

There's also the issue of having multiple Interact
objects within your range that have different text.

Current code doesn't support switching between those.

I would also like to support different controller button sets.
E.g. 'Agnostic', 'Nintendo', 'XBox', 'PlayStation' maybe.
"""

onready var anim = $AnimationPlayer
var node_list:Dictionary

func _ready() -> void:
	Events.connect("pause", self, "pause_state_changed")
	
	node_list = {
		"pickup": $PickUp,
		"menu": $MenuHints
	}
	anim.play("FadeOut")
	anim.seek(0.1, true)
	
func pause_state_changed(state:bool) -> void:
	if state == true:
		fadein("menu")
	else:
		fadeout()
		# Warning, this will not go back to what it was showing previously.
	
func fadein(type:String) -> void:
	# Show only the relevant context hint
	for key in node_list:
		if key == type:
			node_list[key].visible = true
		else:
			node_list[key].visible = false
	anim.play("FadeIn")
	
func fadeout() -> void:
	anim.play("FadeOut")
