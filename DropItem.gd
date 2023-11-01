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

func _process(delta):
	if visible:
		position = get_viewport().get_mouse_position() - Vector2(get_viewport().size) / 2 + %Player.position + %Camera.offset
		modulate = Color.WHITE if _canPlace(position) else Color.DARK_RED
		if toDrop.snapToGrid:
			var gridX = int(floor(position.x / 128))
			var gridY = int(floor(position.y / 96))
			position.x = gridX * 128 + 64
			position.y = gridY * 96 + 96

func _canPlace(position):
	var gridX = int(floor(position.x / 128))
	var gridY = int(floor(position.y / 96))
	if %World.tileAtIsFloor(position) and not %Walls.g(gridX, gridY):
		return true
	else:
		return false

func createItem(type:ItemType, at, durability):
	if _canPlace(at):
		var item:Item = itemScene.instantiate()
		item.position = at
		item.type = type
		item.durability = durability
		$/root/Node2D.add_child(item)
		if type.snapToGrid:
			item.snapToGridAndRegister()

func doDrop(dropAt):
	if not toDrop:
		return
	if _canPlace(dropAt):
		visible = true
	else:
		return
	var removed = %Inventory.remove(toDrop)
	if toDrop.snapToGrid:
		dropAt.y += 96
	if removed:
		createItem(toDrop, dropAt, removed[1])
		toDrop = null
	else:
		visible = true
