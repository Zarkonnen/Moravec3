extends Node

var spawnRegions = []

func _ready():
	generate()

func generate():
	var grid:GridManager = %Grid
	var water = GroundType.ofName("Water")
	# Generate some water regions
	for i in range(int(GridManager.MAP_SIZE * GridManager.MAP_SIZE / 80)):
		var w = randi_range(1, 3) * 2
		var h = randi_range(1, 3) * 2
		var x = randi_range(1, GridManager.MAP_SIZE / 2 - w / 2 - 1) * 2
		var y = randi_range(1, GridManager.MAP_SIZE / 2 - h / 2 - 1) * 2
		for yy in range(y, y + h):
			for xx in range(x, x + w):
				grid.g(xx, yy).ground = water
	grid.updateTileMap()
	
	# Clear test items
	for item in get_tree().get_nodes_in_group("Items"):
		item.unregister()
		item.queue_free()
	
	for isr in ItemSpawnRegion.types:
		for n in range(isr.quantity):
			var x = randf_range(0, 128 * GridManager.MAP_SIZE)
			var y = randf_range(0, 96 * GridManager.MAP_SIZE)
			spawnRegions.append([x, y, isr])
			for j in range(isr.itemQuantity):
				var ix = randf_range(x - isr.radius, x + isr.radius)
				var iy = randf_range(y - isr.radius, y + isr.radius)
				if not grid.tileAt(ix, iy) or not grid.tileAt(ix, iy).traversable():
					continue
				%DropItem.createItem(isr.type, Vector2(ix, iy), isr.type.durability)
