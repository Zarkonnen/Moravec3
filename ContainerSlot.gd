extends Control
class_name ContainerSlot
@export var index = 0
var ccs:ContainerContents

func _ready():
	ccs = %ContainerContents

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == 1:
			ccs.transferToPlayer(index, not Input.is_action_pressed("split"))
