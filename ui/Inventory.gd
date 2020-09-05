extends Node2D

"""
Should this system really exist only in the UI? 
Should there be a separate inventory system... 
"""

onready var item0 = $Item0
onready var item1 = $Item1
onready var item2 = $Item2
onready var item3 = $Item3
onready var item4 = $Item4

var gfx:Dictionary = {
	"": null,
	"sun_card": preload("res://ui/img/items/suncard_ui.png"),
	"moon_card": preload("res://ui/img/items/mooncard_ui.png")
	}

var inventory:Array
var selected_item:int = 0
var item_total = 2

func _ready() -> void:
	inventory = [
		{
			"node": item0, 
			"item": "sun_card"
		}, {
			"node": item1, 
			"item": "moon_card"
		}, {
			"node": item2,
			"item": ""
		}, {
			"node": item3,
			"item": ""
		}, {
			"node": item4,
			"item": ""
		}]
		
	for i in range (inventory.size()):
		set_selected(i, i == selected_item)
		set_graphic(i, inventory[i].item)

func is_full() -> bool:
	for obj in inventory:
		if obj.item == "":
			return false 
	return true

func obtain_item(_item:String):
	pass

func current_item() -> String:
	return inventory[selected_item].item

func set_graphic(index:int, item:String) -> void:
	inventory[index].node.texture = gfx[item]

func set_selected(index:int, state:bool) -> void:
	inventory[index].node.material.set_shader_param("selected", state)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("scroll_inventory_left"):
		Input.action_release("scroll_inventory_left")
		set_selected(selected_item, false)
		selected_item = posmod(selected_item + 1, item_total)
		set_selected(selected_item, true)
		
	if Input.is_action_just_pressed("scroll_inventory_right"):
		Input.action_release("scroll_inventory_right")
		set_selected(selected_item, false)
		selected_item = posmod(selected_item - 1, item_total)
		set_selected(selected_item, true)
