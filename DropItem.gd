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

func createItem(type, at, durability):
	if %World.tileAtIsFloor(at):
		var item:Item = itemScene.instantiate()
		item.position = at
		item.type = type
		item.durability = durability
		$/root/Node2D.add_child(item)

func doDrop(dropAt):
	if not toDrop:
		return
	if %World.tileAtIsFloor(dropAt):
		visible = true
	var removed = %Inventory.remove(toDrop)
	if removed:
		createItem(toDrop, dropAt, removed[1])
		toDrop = null
	else:
		visible = true
