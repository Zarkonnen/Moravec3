extends TileMap

var highlit = null
var ignoreNextClick = false

var mouseDown = false

const INTERACTION_RANGE = 60
const INTERACTION_RANGE_WALL = 140
const INTERACTION_SEARCH_RANGE = 300

func _process(delta):
	var mouseClicked = false
	if Input.is_mouse_button_pressed(1):
		mouseDown = not ignoreNextClick
	else:
		if mouseDown:
			if not ignoreNextClick:
				mouseClicked = true
		ignoreNextClick = false
		mouseDown = false
	var mp = get_viewport().get_mouse_position()
	if get_tree().get_nodes_in_group("MoveOpaque").any(func(n): return n.get_rect().has_point(mp)):
		return
	mp = mp - Vector2(get_viewport().size) / 2 + %Player.position + %Camera.offset
	var closest = null
	var bestDist = 0
	for it in get_tree().get_nodes_in_group("Items"):
		if it.get_rect().has_point(mp):
			var dist = (it.position - mp).length()
			if not closest or dist < bestDist:
				closest = it
				bestDist = dist
	if highlit and is_instance_valid(highlit):
		highlit.highlight = ""
		highlit = null
	if closest and %Player.interactionName(closest):
		closest.highlight = %Player.interactionName(closest)
		highlit = closest
	if mouseClicked or mouseDown:
		var doMove = not closest
		if mouseClicked:
			if %DropItem.toDrop:
				var irange = INTERACTION_RANGE_WALL if %DropItem.toDrop.wall else INTERACTION_RANGE
				var distance = mp - %Player.position
				if distance.length() > irange:
					%Player.dropAt = mp
					%DropItem.visible = false
					mp -= distance.normalized() * (irange - 20)
					doMove = true
				else:
					%DropItem.doDrop(mp)
					doMove = false
			elif closest:
				var distance = closest.position - %Player.position
				var irange = INTERACTION_RANGE_WALL if closest.type.wall else INTERACTION_RANGE
				if distance.length() > irange:
					mp -= distance.normalized() * (irange - 20)
					doMove = true
				else:
					%Player.interact(closest)
					doMove = false
			
		if doMove and tileAt(mp):
			%Player.setNavTarget(mp, closest)
		if doMove:
			%Player.using = null
			%Player.crafting = null
	if Input.is_action_pressed("use"):
		# Find something to interact with.
		var target = Util.most(get_tree().get_nodes_in_group("Items").filter(inSearchRange).filter(canInteract), playerCloseness)
		if target and target != %Player.using:
			var distance = target.position - %Player.position
			if distance.length() > INTERACTION_RANGE:
				%Player.setNavTarget(target.position - distance.normalized() * INTERACTION_RANGE / 2, target)
			else:
				%Player.interact(target)
	
func inSearchRange(it):
	return %Player.position.distance_squared_to(it.position) <= INTERACTION_SEARCH_RANGE * INTERACTION_SEARCH_RANGE

func canInteract(it):
	return it.type.canTake \
		or (%Inventory.selectedItem() and it.type.use.has(%Inventory.selectedItem().name)) \
		or it.type.use.has("any")
	
func playerCloseness(item):
	return -%Player.position.distance_squared_to(item.position)

func tileAt(mp) -> TileData:
	var gridPos = Vector2i(floor(mp.x / tile_set.tile_size.x), floor(mp.y / tile_set.tile_size.y))
	return get_cell_tile_data(0, gridPos)

func tileAtIsFloor(mp) -> bool:
	var td = tileAt(mp)
	return td and td.terrain == 0
