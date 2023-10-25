extends Node

var contents = [
	[null, 0],
	[null, 0],
	[null, 0],
	[null, 0]
]

signal changed

var selectedSlot = 0

func selectedItem() -> ItemType:
	return contents[selectedSlot][0]

func _ready():
	for islot in get_tree().get_nodes_in_group("InventorySlots"):
		islot.get_node("Texture").texture = islot.get_node("Texture").texture.duplicate()
	updateSlot(0)

func _process(delta):
	for i in range(contents.size()):
		if Input.is_action_pressed("inventory" + str(i + 1)):
			selectSlot(i)

func has(it:ItemType, quantity:int=1) -> bool:
	for slot in contents:
		if slot[0] == it:
			quantity -= slot[1]
	return quantity <= 0

func add(it:ItemType) -> bool:
	# Can we stack?
	var slot = Util.first(contents, func(s): return s[0] == it and s[1] < it.stacking)
	if not slot:
		slot = Util.first(contents, func(s): return s[1] == 0)
	if slot:
		slot[0] = it
		slot[1] += 1
		updateSlot(contents.find(slot))
		changed.emit()
		return true
	return false

func remove(it:ItemType, quantity:int=1) -> bool:
	if not has(it, quantity):
		return false
	for slot in contents:
		if slot[0] == it:
			var rm = min(quantity, slot[1])
			slot[1] -= rm
			quantity -= rm
			if slot[1] == 0:
				slot[0] = null
			updateSlot(contents.find(slot))
	changed.emit()
	return true
	
func updateSlot(i):
	var islot = get_tree().get_nodes_in_group("InventorySlots")[i]
	var c = contents[i]
	if c[0]:
		islot.get_node("Texture").texture.region = c[0].texRect
		islot.get_node("Texture").visible = true
		islot.tooltip_text = c[0].name
	else:
		islot.get_node("Texture").visible = false
		islot.tooltip_text = ""
	islot.get_node("Quantity").text = "" if c[1] < 2 else str(c[1])
	islot.get_node("Border").color = Color("2f281e") if i == selectedSlot else Color("d0d1cb")

func dropSlot(i):
	if contents[i][0]:
		%DropItem.toDrop = contents[i][0]

func selectSlot(i):
	if contents[i][0] and contents[i][0].use.has("consume"):
		%Player.consume(contents[i][0])
	elif i != selectedSlot:
		var old = selectedSlot
		selectedSlot = i
		updateSlot(i)
		updateSlot(old)
