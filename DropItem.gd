extends Sprite2D

var itemScene = preload("res://Item.tscn")

#func _ready():
#	toDrop = ItemType.ofName("chalk")

var toDrop:ItemType = null:
	set(value):
		toDrop = value
		if toDrop:
			texture.region = toDrop.texRect
			offset.y = -toDrop.texRect.size.y / 2
			visible = true
		else:
			visible = false

var quantity:int = 1:
	set(value):
		quantity = value
		$Quantity.text = "" if quantity < 2 else str(quantity)

var preferredSlot:int = ItemContainer.ANY_SLOT

func _process(delta):
	if visible:
		position = get_viewport().get_mouse_position()
		var worldPosition = position - Vector2(get_viewport().size) / 2 + %Player.position + %Camera.offset
		modulate = Color.WHITE if _canPlace(worldPosition) else Color.DARK_RED
		if toDrop.snapToGrid:
			var gridX = int(floor(worldPosition.x / 128))
			var gridY = int(floor(worldPosition.y / 96))
			position = Vector2(gridX * 128 + 64, gridY * 96 + 96) + Vector2(get_viewport().size) / 2 - %Player.position - %Camera.offset

func _canPlace(position):
	var gridX = int(floor(position.x / 128))
	var gridY = int(floor(position.y / 96))
	var tile = %Grid.g(gridX, gridY)
	if tile and tile.traversable():
		if toDrop.ceiling:
			if tile.ceiling or %Grid.wallSupportStrength(gridX, gridY) < 1:
				return false
		elif toDrop.snapToGrid:
			for it in get_tree().get_nodes_in_group("Items"):
				if it.position.x >= gridX * 128 and it.position.x <= gridX * 128 + 128 and it.position.y >= gridY * 128 and it.position.y <= gridY * 96 + 96:
					return false
		return true
	else:
		return false

func createItem(type:ItemType, at, durability, quantity=1):
	if type.snapToGrid:
		if type.wall and %Grid.g(Item.xToGrid(at.x), Item.yToGrid(at.y)).wall:
			return
		if type.ceiling and %Grid.g(Item.xToGrid(at.x), Item.yToGrid(at.y)).ceiling:
			return
	var item:Item = itemScene.instantiate()
	item.position = at
	item.type = type
	item.durability = durability
	item.quantity = quantity
	$/root/Node2D/Items.add_child(item)
	if type.snapToGrid:
		item.snapToGridAndRegister()

func doDrop(dropAt):
	if not toDrop:
		return
	if _canPlace(dropAt):
		visible = true
	else:
		return
	var removed = %Inventory.remove(toDrop, quantity, preferredSlot)
	if toDrop.snapToGrid:
		dropAt.y += 96
	if removed:
		createItem(toDrop, dropAt, removed[1], quantity)
		toDrop = null
		%World.ignoreNextClick = true
	else:
		visible = true
