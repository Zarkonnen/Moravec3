extends TileMap

var highlit = null
var ignoreUntilReleased = false

const INTERACTION_RANGE = 40

func _process(delta):
	var mp = get_viewport().get_mouse_position()
	if get_tree().get_nodes_in_group("MoveOpaque").any(func(n): return n.get_rect().has_point(mp)):
		return
	mp = mp - Vector2(get_viewport().size) / 2 + %Player.position
	var closest = null
	var bestDist = 0
	for it in get_tree().get_nodes_in_group("Items"):
		if it.get_rect().has_point(mp):
			var dist = (it.position - mp).length()
			if not closest or dist < bestDist:
				closest = it
				bestDist = dist
	if highlit and is_instance_valid(highlit):
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
				%Player.interact(closest)
				doMove = false
				ignoreUntilReleased = true
		elif %DropItem.toDrop:
			var distance = mp - %Player.position
			if distance.length() > INTERACTION_RANGE:
				%Player.dropAt = mp
				%DropItem.visible = false
				mp -= distance.normalized() * INTERACTION_RANGE / 2
			else:
				%DropItem.doDrop()
				doMove = false
				ignoreUntilReleased = true
		if doMove and tileAt(mp) and not ignoreUntilReleased:
			%Player.setNavTarget(mp, closest)
	else:
		ignoreUntilReleased = false
	
func tileAt(mp) -> TileData:
	var gridPos = Vector2i(floor(mp.x / tile_set.tile_size.x), floor(mp.y / tile_set.tile_size.y))
	return get_cell_tile_data(0, gridPos)

func tileAtIsFloor(mp) -> bool:
	var td = tileAt(mp)
	return td and td.terrain == 0
