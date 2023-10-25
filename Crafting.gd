extends TextureRect

var inputSlot = preload("res://CraftInputSlot.tscn")
var outputSlot = preload("res://CraftOutputSlot.tscn")

var show = false

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if show:
			hideCrafting()
		else:
			showCrafting()

func showCrafting():
	var y = position.y + 70
	var x = position.x + 20
	for r in Recipe.list:
		var outSlot = outputSlot.instantiate()
		outSlot.recipe = r
		outSlot.position.x = x
		outSlot.position.y = y
		outSlot.get_node("Texture").texture = outSlot.get_node("Texture").texture.duplicate()
		outSlot.get_node("Texture").texture.region = r.output.texRect
		$/root/Node2D/GUI.add_child(outSlot)
		var x2 = x + 70
		for i in r.inputs:
			var inSlot = inputSlot.instantiate()
			inSlot.position.x = x2
			inSlot.position.y = y
			x2 += 70
			inSlot.get_node("Border").color = Color("d0d1cb") if %Inventory.has(i[0], i[1]) else Color("d53846")
			inSlot.get_node("Texture").texture = inSlot.get_node("Texture").texture.duplicate()
			inSlot.get_node("Texture").texture.region = i[0].texRect
			inSlot.get_node("Quantity").text = "" if i[1] < 2 else str(i[1])
			$/root/Node2D/GUI.add_child(inSlot)
		y += 70
	show = true
	
func hideCrafting():
	for n in get_tree().get_nodes_in_group("CraftInputSlots"):
		n.queue_free()
	for n in get_tree().get_nodes_in_group("CraftOutputSlots"):
		n.queue_free()
	show = false

func craft(r:Recipe):
	for i in r.inputs:
		if not %Inventory.has(i[0], i[1]):
			return
	%Player.craft(r)
	hideCrafting()

func finishCrafting(r:Recipe):
	for i in r.inputs:
		%Inventory.remove(i[0], i[1])
	if not r.output.canTake or not %Inventory.add(r.output, r.output.durability):
		%DropItem.createItem(r.output, %Player.position, r.output.durability)

func _on_inventory_changed():
	if show:
		hideCrafting()
		showCrafting()
