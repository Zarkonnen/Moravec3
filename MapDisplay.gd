extends TileMap

var highlit = null

const INTERACTION_RANGE = 50

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	var mp = get_viewport().get_mouse_position() - Vector2(get_viewport().size) / 2 + %Player.position
	var closest = null
	var bestDist = 0
	for it in get_tree().get_nodes_in_group("Items"):
		if it.get_rect().has_point(mp):
			var dist = (it.position - mp).length()
			if not closest or dist < bestDist:
				closest = it
				bestDist = dist
	if highlit:
		highlit.highlight = false
		highlit = null
	if closest:
		closest.highlight = true
		highlit = closest
	if Input.is_mouse_button_pressed(1):
		var doMove = true
		if closest:
			var distance = closest.position - %Player.position
			if distance.length() > INTERACTION_RANGE:
				mp -= distance.normalized() * INTERACTION_RANGE / 2
			else:
				print("interact!")
				doMove = false
		if doMove:
			var gridPos = Vector2i(floor(mp.x / tile_set.tile_size.x), floor(mp.y / tile_set.tile_size.y))
			var td:TileData = get_cell_tile_data(0, gridPos)
			if td:# and td.terrain == 0:
				%Player.setNavTarget(mp)
	
