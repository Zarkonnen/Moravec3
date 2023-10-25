extends Node

# type, quantity, durability, rotTimer
var contents = [
	[null, 0, 0, 0],
	[null, 0, 0, 0],
	[null, 0, 0, 0],
	[null, 0, 0, 0]
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
		var slot = contents[i]
		if slot[0] and slot[0].rotInterval:
			slot[3] -= delta
			if slot[3] <= 0:
				slot[2] -= 1
				slot[3] = slot[0].rotInterval
				if slot[2] <= 0:
					var rotInto = ItemType.ofName(slot[0].rotInto)
					if rotInto:
						slot[0] = rotInto
						slot[2] = rotInto.durability
					else:
						slot[0] = null
				updateSlot(i)

func has(it:ItemType, quantity:int=1) -> bool:
	for slot in contents:
		if slot[0] == it:
			quantity -= slot[1]
	return quantity <= 0
	
func useTool(it:ItemType, toolDurabilityChange:int):
	if not toolDurabilityChange:
		return
	var slot = contents[selectedSlot]
	if slot[0] != it:
		slot = Util.first(contents, func(s): return s[0] == it)
	if not slot:
		return
	slot[2] += toolDurabilityChange
	if slot[2] <= 0:
		slot[0] = null
	updateSlot(contents.find(slot))

func add(it:ItemType, durability) -> bool:
	if not it.canTake:
		return false
	# Can we stack?
	var slot = Util.first(contents, func(s): return s[0] == it and s[1] < it.stacking)
	if not slot:
		slot = Util.first(contents, func(s): return s[1] == 0)
	if slot:
		slot[0] = it
		slot[2] = round((slot[2] * slot[1] + durability) / (slot[1] + 1))
		slot[1] += 1
		updateSlot(contents.find(slot))
		changed.emit()
		return true
	return false

func remove(it:ItemType, quantity:int=1): # null or array of type, quantity, durability
	if not has(it, quantity):
		return null
	var q = quantity
	var durabilitySum = 0
	for slot in contents:
		if slot[0] == it:
			var rm = min(quantity, slot[1])
			slot[1] -= rm
			quantity -= rm
			durabilitySum += rm * slot[2]
			if slot[1] == 0:
				slot[0] = null
			updateSlot(contents.find(slot))
	changed.emit()
	return [it, round(durabilitySum / q)]
	
func updateSlot(i):
	var islot = get_tree().get_nodes_in_group("InventorySlots")[i]
	var c = contents[i]
	if c[0]:
		islot.get_node("Texture").texture.region = c[0].texRect
		islot.get_node("Texture").visible = true
		islot.tooltip_text = c[0].name
		if c[2] < c[0].durability:
			islot.get_node("Durability").size.x = (46 * c[2] / c[0].durability)
			islot.get_node("Durability").color = Color("d53846") if c[2] <= c[0].durability / 4 else Color("d0d1cb")
			islot.get_node("Durability").visible = true
		else:
			islot.get_node("Durability").visible = false
	else:
		islot.get_node("Texture").visible = false
		islot.get_node("Durability").visible = false
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
