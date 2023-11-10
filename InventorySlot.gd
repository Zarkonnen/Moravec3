extends Control

@export var index = 0

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if %ContainerContents.container:
			%ContainerContents.transferFromPlayer(index, not Input.is_action_pressed("split"))
		else:
			if event.button_index == 1:
				%Inventory.selectSlot(index)
			if event.button_index == 2:
				%Inventory.dropSlot(index, not Input.is_action_pressed("split"))
