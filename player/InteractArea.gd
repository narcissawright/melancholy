extends Area

var list:Array = []
onready var priority_position = $Position3D

func execute():
	if list.size() == 0: 
		# Nothing to execute.
		return
	if list.size() == 1:
		# Only 1 in list, so use this one.
		list[0].interact()
	else:
		var index = get_index_of_priority_interactable()
		list[index].interact()

func get_index_of_priority_interactable() -> int:
	# Need to find smallest distance.
	var index_of_smallest = 0
	var value_of_smallest = 100.0
	for i in range (list.size()):
		var length = (list[i].global_transform.origin - priority_position.global_transform.origin).length_squared()
		if length < value_of_smallest:
			value_of_smallest = length
			index_of_smallest = i
	return index_of_smallest

func _on_InteractArea_area_entered(area: Area) -> void:
	if list.size() == 0:
		Game.ui.get_node("ContextHint").fadein(area.type)
	list.append(area)
	
func _on_InteractArea_area_exited(area: Area) -> void:
	list.erase(area)
	if list.size() == 0:
		Game.ui.get_node("ContextHint").fadeout()
