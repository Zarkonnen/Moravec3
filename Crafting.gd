extends TextureRect

var inputSlot = preload("res://CraftInputSlot.tscn")
var outputSlot = preload("res://CraftOutputSlot.tscn")
var catButton = preload("res://CraftCategoryButton.tscn")

var show = false
var category = Recipe.categories[0]

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if show:
			hideCrafting()
		else:
			showCrafting()

func showCrafting():
	var y = position.y
	var x = position.x + 70
	var index = 0
	for cat in Recipe.categories:
		var catB = catButton.instantiate()
		catB.index = index
		index += 1
		catB.position.x = x
		catB.position.y = y
		catB.get_node("Border").color = "d0d1cb" if cat == category else "2f281e"
		catB.get_node("Label").text = cat[0]
		x += 130
		$/root/Node2D/GUI.add_child(catB)
	y = position.y + 70
	x = position.x + 20
	for r in category[1]:
		var outSlot = outputSlot.instantiate()
		outSlot.recipe = r
		outSlot.position.x = x
		outSlot.position.y = y
		outSlot.get_node("Texture").texture = outSlot.get_node("Texture").texture.duplicate()
		outSlot.get_node("Texture").setImage(r.output.texRect)
		outSlot.tooltip_text = "Craft " + r.output.name
		if not r.unlocked:
			outSlot.tooltip_text += "\nUnlock with " + str(r.xp) + " XP"
		elif r.stamina > %Stats.getValue("Stamina"):
			outSlot.tooltip_text += "\nNot enough stamina"
		outSlot.get_node("Border").color = Color("597646") if canCraft(r) else Color("d53846")
		if not r.unlocked:
			outSlot.get_node("Border").color = Color("7892ab")
		outSlot.get_node("Label").text = "" if r.unlocked else str(r.xp) + " XP"
		$/root/Node2D/GUI.add_child(outSlot)
		var x2 = x + 70
		for i in r.inputs:
			var inSlot = inputSlot.instantiate()
			inSlot.position.x = x2
			inSlot.position.y = y
			x2 += 70
			inSlot.get_node("Border").color = Color("d0d1cb") if %Inventory.has(i[0], i[1]) else Color("d53846")
			inSlot.get_node("Texture").texture = inSlot.get_node("Texture").texture.duplicate()
			inSlot.get_node("Texture").setImage(i[0].texRect)
			inSlot.get_node("Quantity").text = "" if i[1] < 2 else str(i[1])
			inSlot.tooltip_text = "Ingredient: " + str(i[1]) + "x " + i[0].name
			$/root/Node2D/GUI.add_child(inSlot)
		y += 70
	show = true
	
func hideCrafting():
	for n in get_tree().get_nodes_in_group("CraftCategoryButtons"):
		n.queue_free()
	for n in get_tree().get_nodes_in_group("CraftInputSlots"):
		n.queue_free()
	for n in get_tree().get_nodes_in_group("CraftOutputSlots"):
		n.queue_free()
	show = false

func canCraft(r:Recipe):
	if not r.unlocked:
		return false
	if r.stamina > %Stats.getValue("Stamina"):
		return false
	for i in r.inputs:
		if not %Inventory.has(i[0], i[1]):
			return false
	if r.output.snapToGrid:
		if r.output.wall and %Grid.g(Item.xToGrid(%Player.position.x), Item.yToGrid(%Player.position.y)).wall:
			return false
		if r.output.ceiling and %Grid.g(Item.xToGrid(%Player.position.x), Item.yToGrid(%Player.position.y)).ceiling:
			return false
	return true

func craft(r:Recipe):
	if not r.unlocked and %Player.xp >= r.xp:
		%Player.xp -= r.xp
		r.unlocked = true
		hideCrafting()
		showCrafting()
		return
	if not canCraft(r):
		return
	%Player.craft(r)
	hideCrafting()

func finishCrafting(r:Recipe):
	%Stats.change("Stamina", -r.stamina)
	for i in r.inputs:
		%Inventory.remove(i[0], i[1])
	if not r.output.canTake or not %Inventory.add(r.output, r.output.durability):
		%DropItem.createItem(r.output, %Player.position, r.output.durability)

func _on_inventory_changed():
	if show:
		hideCrafting()
		showCrafting()
