extends Node
class_name PlayerInventory

const BASE_INVENTORY_SIZE = 4
var contents = ItemContainer.new(4)

signal changed

var bag:ItemType = null
var bagDurability
var clothing:ItemType = null
var clothingDurability
var selectedSlot = 0

const MAX_SLOTS = 9
const BAG_SLOT = -1
const CLOTHING_SLOT = -2

func selectedItem() -> ItemType:
	return contents.g(selectedSlot).type

func _ready():
	for islot in get_tree().get_nodes_in_group("InventorySlots"):
		islot.get_node("Texture").texture = islot.get_node("Texture").texture.duplicate()
	updateAllSlots()

func _process(delta):
	var doCheck = false
	for i in range(contents.size):
		if Input.is_action_pressed("inventory" + str(i + 1)):
			selectSlot(i)
		if contents.g(i).update(delta):
			updateSlot(i)
			doCheck = true
	if doCheck:
		checkLight()

func has(it:ItemType, quantity:int=1) -> bool:
	return contents.has(it, quantity) or (bag == it and quantity == 1) or (clothing == it and quantity == 1)
	
func useTool(it:ItemType, toolDurabilityChange:int):
	if contents.useTool(selectedSlot, it, toolDurabilityChange):
		changed.emit()
		updateAllSlots()

func getType(slot):
	if slot == BAG_SLOT:
		return bag
	if slot == CLOTHING_SLOT:
		return clothing
	if slot < contents.size:
		return contents.g(slot).type
	return null

func transfer(fromSlot, toSlot, quantity=1):
	if fromSlot == toSlot:
		return
	var removed = remove(getType(fromSlot), quantity, fromSlot)
	if removed:
		add(removed[0], removed[1], quantity, toSlot)
	return removed

func add(it:ItemType, durability, quantity=1, preferredSlot=ItemContainer.ANY_SLOT) -> int:
	var added = 0
	if it.bagCapacity and not bag and (preferredSlot == BAG_SLOT or preferredSlot == ItemContainer.ANY_SLOT):
		bagDurability = durability
		added += 1
		quantity -= 1
		bag = it
		contents.size = BASE_INVENTORY_SIZE + it.bagCapacity
	if it.clothing and not clothing and (preferredSlot == CLOTHING_SLOT or preferredSlot == ItemContainer.ANY_SLOT):
		clothingDurability = durability
		added += 1
		quantity -= 1
		clothing = it
	if quantity > 0:
		added += contents.add(it, durability, quantity, preferredSlot)
	if added > 0:
		changed.emit()
		updateAllSlots()
		checkLight()
	return added

func canRemoveBag():
	if not bag:
		return true
	for i in range(BASE_INVENTORY_SIZE, BASE_INVENTORY_SIZE + bag.bagCapacity):
		if contents.g(i).type:
			return false
	return true

func remove(it:ItemType, quantity:int=1, preferredSlot=ItemContainer.ANY_SLOT): # null or array of [item type, durability]
	var result = null
	if not result and preferredSlot == BAG_SLOT and quantity == 1 and it == bag and canRemoveBag():
		bag = null
		contents.size = BASE_INVENTORY_SIZE
		result =  [it, bagDurability]
	if not result and preferredSlot == CLOTHING_SLOT and quantity == 1 and it == clothing:
		clothing = null
		result =  [it, clothingDurability]
	if not result:
		result = contents.remove(it, quantity)
	if not result and quantity == 1 and it == bag and canRemoveBag():
		bag = null
		contents.size = BASE_INVENTORY_SIZE
		result =  [it, bagDurability]
	if not result and quantity == 1 and it == clothing:
		clothing = null
		result = [it, clothingDurability]
	if result:
		changed.emit()
		updateAllSlots()
		checkLight()
	return result

func updateAllSlots():
	for i in range(-2, MAX_SLOTS + 1):
		updateSlot(i)
	
func updateSlot(i):
	var islot
	var it:ItemType
	var durability
	var quantity = 1
	if i >= contents.size:
		islot = get_tree().get_nodes_in_group("InventorySlots")[i]
		islot.visible = false
		return
	elif i < 0:
		if i == BAG_SLOT:
			islot = %BagSlot
			it = bag
			durability = bagDurability
		elif i == CLOTHING_SLOT:
			islot = %ClothingSlot
			it = clothing
			durability = clothingDurability
	else:
		islot = get_tree().get_nodes_in_group("InventorySlots")[i]
		it = contents.g(i).type
		durability = contents.g(i).durability
		quantity = contents.g(i).quantity
	islot.visible = true
	if it:
		islot.get_node("Texture").setImage(it.texRect)
		islot.get_node("Texture").visible = true
		islot.get_node("Texture").modulate = it.tint
		if %ContainerContents.container:
			islot.tooltip_text = it.name + "\nLeft click to transfer\nShift-left click to split"
		else:
			islot.tooltip_text = it.name + "\nLeft click to use/select\nRight click to drop\nShift-right click to split"
		if durability < it.durability:
			islot.get_node("Durability").size.x = (46 * durability / it.durability)
			islot.get_node("Durability").color = Color("d53846") if durability <= it.durability / 4 else Color("d0d1cb")
			islot.get_node("Durability").visible = true
		else:
			islot.get_node("Durability").visible = false
	else:
		islot.get_node("Texture").visible = false
		islot.get_node("Durability").visible = false
		islot.tooltip_text = ""
	islot.get_node("Quantity").text = "" if quantity < 2 else str(quantity)
	islot.get_node("Border").color = Color("d0d1cb") if i == selectedSlot else Color("2f281e")

func dropSlot(i, all:bool=true):
	if i == BAG_SLOT and bag:
		%DropItem.toDrop = bag
		%DropItem.quantity = 1
		%DropItem.preferredSlot = BAG_SLOT
	elif i == CLOTHING_SLOT and clothing:
		%DropItem.toDrop = clothing
		%DropItem.quantity = 1
		%DropItem.preferredSlot = CLOTHING_SLOT
	elif contents.g(i).type:
		%DropItem.toDrop = contents.g(i).type
		%DropItem.quantity = contents.g(i).quantity if all else 1
		%DropItem.preferredSlot = i

func selectSlot(i):
	if i < 0:
		return
	if contents.g(i).type and contents.g(i).type.use.has("consume"):
		%Player.consume(contents.g(i).type)
	elif i != selectedSlot:
		var old = selectedSlot
		selectedSlot = i
		updateSlot(i)
		updateSlot(old)

func checkLight():
	var amount = 0
	var color = Color.WHITE
	for i in range(contents.size):
		var slot:ItemContainer.Slot = contents.slots[i]
		if slot.type and slot.type.lightEmission > amount:
			amount = slot.type.lightEmission
			color = slot.type.lightColor
	if amount:
		$/root/Node2D/Player/Light.scale = Vector2(amount, amount)
		$/root/Node2D/Player/Light.color = color
		$/root/Node2D/Player/Light.enabled = true
	else:
		$/root/Node2D/Player/Light.enabled = false
