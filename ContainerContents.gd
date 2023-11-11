extends Control
class_name ContainerContents

var container:Item = null:
	set(value):
		var changed = container != value
		container = value
		update()


func _process(delta):
	if container and not is_instance_valid(container):
		container = null
		update()
		%Inventory.updateAllSlots()
	else:
		update()

func transferToPlayer(i, all:bool):
	var from:ItemContainer.Slot = container.contents.g(i)
	if not from.type:
		return
	var to:ItemContainer = %Inventory.contents
	var amt = to.add(from.type, from.durability, from.quantity if all else 1)
	if amt == 0:
		return
	container.contents.remove(from.type, amt)
	update()
	%Inventory.updateAllSlots()

func transferFromPlayer(inventoryIndex, all:bool):
	var inv:ItemContainer = %Inventory.contents
	var from:ItemContainer.Slot = inv.g(inventoryIndex)
	if not from.type:
		return
	var amt = container.contents.add(from.type, from.durability, from.quantity if all else 1)
	if amt == 0:
		return
	inv.remove(from.type, amt)
	update()
	%Inventory.updateAllSlots()

func g(i):
	return Util.first(get_children(), func(c): return is_instance_of(c, ContainerSlot) and c.index == i)

func _ready():
	for islot in get_tree().get_nodes_in_group("ContainerSlots"):
		islot.get_node("Texture").texture = islot.get_node("Texture").texture.duplicate()

func update():
	if not container:
		for i in range(16):
			g(i).visible = false
		visible = false
		return
	$Label.text = container.type.name
	for i in range(16):
		var islot = g(i)
		if i < container.contents.size:
			var c = container.contents.g(i)
			if c.type:
				islot.get_node("Texture").setImage(c.type.texRect)
				islot.get_node("Texture").visible = true
				islot.tooltip_text = c.type.name + "\nLeft click to take\nShift-left click to take one"
				islot.get_node("Quantity").text = "" if c.quantity < 2 else str(c.quantity)
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
				islot.get_node("Quantity").text = ""
			islot.visible = true
		else:
			islot.visible = false
	visible = true
