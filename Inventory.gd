extends Node

var contents = [
	[null, 0],
	[null, 0],
	[null, 0],
	[null, 0]
]

func _ready():
	for islot in get_tree().get_nodes_in_group("InventorySlots"):
		islot.get_node("Texture").texture = islot.get_node("Texture").texture.duplicate()

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

func dropSlot(slot):
	if contents[slot.index][0]:
		%DropItem.toDrop = contents[slot.index][0]
