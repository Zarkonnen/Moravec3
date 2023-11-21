extends Control

@export var index = 0

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if %ContainerContents.container:
			%ContainerContents.transferFromPlayer(index, not Input.is_action_pressed("split"))
		elif %DropItem.toDrop and event.button_index == 1:
			if %Inventory.transfer(%DropItem.preferredSlot, index, %DropItem.quantity):
				%DropItem.toDrop = null
		else:
			if event.button_index == 1:
				%Inventory.selectSlot(index)
			if event.button_index == 2:
				if index == PlayerInventory.BAG_SLOT and not %Inventory.canRemoveBag():
					return
				%Inventory.dropSlot(index, not Input.is_action_pressed("split"))
