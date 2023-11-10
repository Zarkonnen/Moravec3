extends Node

var contents = ItemContainer.new(4)

signal changed

var selectedSlot = 0

func selectedItem() -> ItemType:
	return contents.g(selectedSlot).type

func _ready():
	for islot in get_tree().get_nodes_in_group("InventorySlots"):
		islot.get_node("Texture").texture = islot.get_node("Texture").texture.duplicate()
	updateSlot(0)

func _process(delta):
	for i in range(contents.size):
		if Input.is_action_pressed("inventory" + str(i + 1)):
			selectSlot(i)
		if contents.g(i).update(delta):
			updateSlot(i)

func has(it:ItemType, quantity:int=1) -> bool:
	return contents.has(it, quantity)
	
func useTool(it:ItemType, toolDurabilityChange:int):
	if contents.useTool(selectedSlot, it, toolDurabilityChange):
		changed.emit()
		updateAllSlots()

func add(it:ItemType, durability, quantity=1) -> int:
	var added = contents.add(it, durability, quantity)
	if added > 0:
		changed.emit()
		updateAllSlots()
	return added

func remove(it:ItemType, quantity:int=1): # null or array of type, quantity, durability
	var result = contents.remove(it, quantity)
	if result:
		changed.emit()
		updateAllSlots()
	return result

func updateAllSlots():
	for i in range(contents.size):
		updateSlot(i)
	
func updateSlot(i):
	var islot = get_tree().get_nodes_in_group("InventorySlots")[i]
	var c = contents.g(i)
	if c.type:
		islot.get_node("Texture").setImage(c.type.texRect)
		islot.get_node("Texture").visible = true
		if %ContainerContents.container:
			islot.tooltip_text = c.type.name + "\nLeft click to transfer\nShift-left click to split"
		else:
			islot.tooltip_text = c.type.name + "\nLeft click to use/select\nRight click to drop\nShift-right click to split"
		if c.durability < c.type.durability:
			islot.get_node("Durability").size.x = (46 * c.durability / c.type.durability)
			islot.get_node("Durability").color = Color("d53846") if c.durability <= c.type.durability / 4 else Color("d0d1cb")
			islot.get_node("Durability").visible = true
		else:
			islot.get_node("Durability").visible = false
	else:
		islot.get_node("Texture").visible = false
		islot.get_node("Durability").visible = false
		islot.tooltip_text = ""
	islot.get_node("Quantity").text = "" if c.quantity < 2 else str(c.quantity)
	islot.get_node("Border").color = Color("2f281e") if i == selectedSlot else Color("d0d1cb")

func dropSlot(i, all:bool=true):
	if contents.g(i).type:
		%DropItem.toDrop = contents.g(i).type
		%DropItem.quantity = contents.g(i).quantity if all else 1

func selectSlot(i):
	if contents.g(i).type and contents.g(i).type.use.has("consume"):
		%Player.consume(contents.g(i).type)
	elif i != selectedSlot:
		var old = selectedSlot
		selectedSlot = i
		updateSlot(i)
		updateSlot(old)
