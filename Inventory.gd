extends Node

var contents = [
	[null, 0],
	[null, 0],
	[null, 0],
	[null, 0]
]

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

func add(it:ItemType) -> bool:
	# Can we stack?
	var slot = Util.first(contents, func(s): return s[0] == it and s[1] < it.stacking)
	if not slot:
		slot = Util.first(contents, func(s): return s[1] == 0)
	if slot:
		slot[0] = it
		slot[1] += 1
		updateSlot(contents.find(slot))
		return true
	return false

func remove(it:ItemType) -> bool:
	var slot = Util.first(contents, func(s): return s[0] == it)
	if slot:
		slot[1] -= 1
		if slot[1] == 0:
			slot[0] = null
		updateSlot(contents.find(slot))
		return true
	return false
	
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
	if i != selectedSlot:
		var old = selectedSlot
		selectedSlot = i
		updateSlot(i)
		updateSlot(old)
