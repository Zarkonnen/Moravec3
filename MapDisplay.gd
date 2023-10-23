extends TileMap


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event is InputEventMouseButton and not event.is_pressed():
		var gridPos = Vector2i(floor(event.position.x / tile_set.tile_size.x), floor(event.position.y / tile_set.tile_size.y))
		var td:TileData = get_cell_tile_data(0, gridPos)
		if td and td.terrain == 0:
			%Player.moveTo = event.position
