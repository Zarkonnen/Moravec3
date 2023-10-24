extends Control

@export var index = 0

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		%Inventory.dropSlot(self)
