extends Node
class_name GridManager

const MAP_SIZE = 20

class Tile:
	var id:int
	var x:int
	var y:int
	var ground:GroundType = null
	var wall:Item = null
	var ceiling:Item = null
	func _init(id, x, y, ground):
		self.id = id
		self.x = x
		self.y = y
		self.ground = ground
	func traversable():
		return ground.traversable and (not wall or not wall.type.wall or wall.type.door)

var grid:Array = []
var nav:AStar2D = AStar2D.new()

func navigate(from:Vector2, to:Vector2):
	var path = nav.get_point_path(nav.get_closest_point(from), nav.get_closest_point(to))
	path[0] = from
	path[path.size() - 1] = to
	return path

func _init():
	var grass = GroundType.ofName("Grass")
	var tidCounter = 0
	for y in range(0, MAP_SIZE):
		var row = []
		grid.append(row)
		for x in range(0, MAP_SIZE):
			row.append(Tile.new(tidCounter, x, y, grass))
			nav.add_point(tidCounter, Vector2(x * 128 + 64, y * 96 + 48))
			tidCounter += 1
	for y in range(1, MAP_SIZE - 1):
		for x in range(0, MAP_SIZE):
			nav.connect_points(grid[y][x].id, grid[y - 1][x].id)
			nav.connect_points(grid[y][x].id, grid[y + 1][x].id)
	for y in range(0, MAP_SIZE):
		for x in range(1, MAP_SIZE - 1):
			nav.connect_points(grid[y][x].id, grid[y][x - 1].id)
			nav.connect_points(grid[y][x].id, grid[y][x + 1].id)
	updateNavigation()
	
func updateNavigation():
	for y in range(0, MAP_SIZE ):
		for x in range(0, MAP_SIZE):
			var t = grid[y][x]
			nav.set_point_disabled(t.id, not t.traversable())
			
func _ready():
	updateTileMap()

func updateTileMap():
	var tm:TileMap = %World
	for row in grid:
		for tile in row:
			tm.set_cell(0, Vector2i(tile.x, tile.y), 0, tile.ground.atlasTile)
	for gt in GroundType.types:
		if gt.terrain != -1:
			tm.set_cells_terrain_connect(0, tm.get_used_cells_by_id(0, -1, gt.atlasTile), 0, gt.terrain)

func tileAt(x, y) -> Tile:
	return g(int(floor(x / 128)), int(floor(y / 96)))

func g(x, y):
	if x < 0 or y < 0 or y >= grid.size() or x >= grid[0].size():
		return null
	return grid[y][x]

func wallSupportStrength(x, y):
	# find all reachable walls via ceilings in a certain max range
	# subtract distance from wall strengths and return strongest
	# this is subtly wrong because we're using manhattan distance instead of actual path distance
	var strength = 0
	var queue:Array = [[x-1, y], [x+1, y], [x, y-1], [x, y+1]]
	var reached:Array = [[x, y]]
	while not queue.is_empty():
		var t = queue.pop_front()
		reached.append(t)
		var tile = g(t[0], t[1])
		if not tile:
			continue
		if tile.wall:
			strength = max(strength, tile.wall.type.wallSupportRange - abs(x - t[0]) - abs(y - t[1]) + 1)
		if tile.wall or tile.ceiling:
			if not [t[0]-1, t[1]] in reached:
				queue.append([t[0]-1, t[1]])
			if not [t[0]+1, t[1]] in reached:
				queue.append([t[0]+1, t[1]])
			if not [t[0], t[1]-1] in reached:
				queue.append([t[0], t[1]-1])
			if not [t[0], t[1]+1] in reached:
				queue.append([t[0], t[1]+1])
	return strength

func collapseCeilings(x, y):
	# Call this when removing a wall or ceiling
	# Find all connected ceilings
	# check their wall support strength
	# delete them and spawn
	var queue:Array = [[x-1, y], [x+1, y], [x, y-1], [x, y+1]]
	var reached:Array = [[x, y]]
	while not queue.is_empty():
		var t = queue.pop_front()
		reached.append(t)
		var tile = g(t[0], t[1])
		if tile and tile.ceiling:
			if wallSupportStrength(t[0], t[1]) <= 0:
				tile.ceiling.unregister()
				tile.ceiling.queue_free()
				for entry in tile.ceiling.type.spawnOnCollapse:
					var st:ItemType = ItemType.ofName(entry[0])
					for i in range(entry[1]):
						%DropItem.createItem(st, Vector2(t[0] * 128 + randi_range(16, 128 - 16), t[1] * 96 + randi_range(16, 96 - 16)), st.durability)
			if not [t[0]-1, t[1]] in reached:
				queue.append([t[0]-1, t[1]])
			if not [t[0]+1, t[1]] in reached:
				queue.append([t[0]+1, t[1]])
			if not [t[0], t[1]-1] in reached:
				queue.append([t[0], t[1]-1])
			if not [t[0], t[1]+1] in reached:
				queue.append([t[0], t[1]+1])

class Enclosure:
	static var enclosureCounter = 0
	var tiles:Array = []
	var number = 0
	var hasCeilings:bool = false
	var averageInsulation:float = 0
	var temperature:float = 20.0
	func _init(tiles):
		self.tiles = tiles
		enclosureCounter += 1
		number = enclosureCounter

var enclosures:Array = []

func getEnclosure(x, y, except=[]) -> Enclosure:
	var xy = [x, y]
	return Util.first(enclosures, func(e): return e not in except and xy in e.tiles)

func wallAdded(x, y):
	nav.set_point_disabled(g(x, y).id, not g(x, y).traversable())
	%EnclosureDebug.queue_redraw()
	#print("wa " + str(x) + ", " + str(y))
	# In enclosure:
	#   Remove tile from enclosure.
	#   Flood fill in each direction NSE.
	#   The first fill updates the existing enclosure, the others are added if different.
	# Not in enclosure:
	#   Flood fill in each direction and create new enclosures if the fill works.
	var enc = getEnclosure(x, y)
	if enc:
		enc.tiles.erase([x, y])
		var encs = [enc]
		for start in [[x-1, y], [x, y-1], [x+1, y], [x, y+1]]:
			var fill = _enclosureFill(start[0], start[1])
			if fill:
				if enc:
					# Update existing enclosure.
					enc.tiles = fill
					_updateCeilings(enc)
					_updateInsulation(enc)
					enc = null
				elif not encs.any(func(e): return start in e.tiles):
					# We need a new enclosure.
					var newEnc = Enclosure.new(fill)
					enclosures.append(newEnc)
					encs.append(newEnc)
					_updateCeilings(newEnc)
					_updateInsulation(enc)
		if enc:
			# Never got used, so delete it.
			enclosures.erase(enc)
	else:
		# Not in enclosure.
		for start in [[x-1, y], [x, y-1], [x+1, y], [x, y+1]]:
			if getEnclosure(start[0], start[1]):
				continue
			var fill = _enclosureFill(start[0], start[1])
			#print(fill)
			if fill:
				#print("new enc")
				var newEnc = Enclosure.new(fill)
				enclosures.append(newEnc)
				_updateCeilings(newEnc)
				_updateInsulation(newEnc)
	updateNavigation()
	
func wallRemoved(x, y):
	nav.set_point_disabled(g(x, y).id, not g(x, y).traversable())
	%EnclosureDebug.queue_redraw()
	#print("wr " + str(x) + ", " + str(y))
	var enc = getEnclosure(x, y)
	if enc: # This should never happen in the first place.
		enclosures.erase(enc)
	var encs = []
	# Visit neighbouring tiles, and if they're in enclosures, check on them.
	for start in [[x-1, y], [x, y-1], [x+1, y], [x, y+1]]:
		enc = getEnclosure(start[0], start[1], encs)
		#print("affected enc " + str(enc))
		if enc:
			# We have an enclosure, and not one we've already visited.
			var fill = _enclosureFill(start[0], start[1])
			if not fill:
				# The enclosure is no longer viable.
				#print("unviable")
				enclosures.erase(enc)
			else:
				# Maybe it should be merged?
				if encs.any(func(e): return e.tiles.any(func(t): return t in fill)):
					# There is an existing enclosure we've touched that overlaps.
					#print("merged")
					enclosures.erase(enc)
				else:
					# No, this is a separate enclosure that needs its tiles updated.
					#print("updated")
					enc.tiles = fill
					encs.append(enc)
					_updateCeilings(enc)
	updateNavigation()
					

func ceilingAdded(x, y):
	%EnclosureDebug.queue_redraw()
	var enc = getEnclosure(x, y)
	if enc:
		_updateCeilings(enc)
		_updateInsulation(enc)
		
func ceilingRemoved(x, y):
	%EnclosureDebug.queue_redraw()
	var enc = getEnclosure(x, y)
	if enc:
		enc.hasCeilings = false
		enc.averageInsulation = 0

func _enclosureFill(x, y, maxDist=10):
	# Flood fill, starting at x, y. If we reach a tile that is more than maxdist away, return null.
	# Otherwise, check if the area covered by the reached list is no more than maxdist across.
	# Return the reached list.
	if not g(x, y) or g(x, y).wall:
		return null # If we're in a wall, at the start, stop right away.
	var queue:Array = [[x-1, y], [x+1, y], [x, y-1], [x, y+1]]
	var reached:Array = [[x, y]]
	var leastX = x
	var mostX = x
	var leastY = y
	var mostY = y
	while not queue.is_empty():
		var t = queue.pop_front()
		if abs(t[0] - x) > maxDist or abs(t[1] - y) > maxDist:
			return null
		if g(t[0], t[1]) and not g(t[0], t[1]).wall:
			reached.append(t)
			leastX = min(t[0], leastX)
			mostX = max(t[0], mostX)
			leastY = min(t[1], leastY)
			mostY = max(t[1], mostY)
			if mostX - leastX > maxDist or mostY - leastY > maxDist:
				return null
			if not [t[0]-1, t[1]] in reached:
				queue.append([t[0]-1, t[1]])
			if not [t[0]+1, t[1]] in reached:
				queue.append([t[0]+1, t[1]])
			if not [t[0], t[1]-1] in reached:
				queue.append([t[0], t[1]-1])
			if not [t[0], t[1]+1] in reached:
				queue.append([t[0], t[1]+1])
	return reached

func _updateCeilings(enc:Enclosure):
	enc.hasCeilings = enc.tiles.all(func(t): return g(t[0], t[1]).ceiling)

func _updateInsulation(enc:Enclosure):
	if not enc.hasCeilings:
		enc.averageInsulation = 0
		return
	var total = 0.0
	var n = 0
	for t in enc.tiles:
		total += g(t[0], t[1]).ceiling.type.insulation
		n += 1
		if g(t[0] - 1, t[1]) and g(t[0] - 1, t[1]).wall:
			total += g(t[0] - 1, t[1]).wall.type.insulation
			n += 1
		if g(t[0] + 1, t[1]) and g(t[0] + 1, t[1]).wall:
			total += g(t[0] + 1, t[1]).wall.type.insulation
			n += 1
		if g(t[0], t[1] - 1) and g(t[0], t[1] - 1).wall:
			total += g(t[0], t[1] - 1).wall.type.insulation
			n += 1
		if g(t[0], t[1] + 1) and g(t[0], t[1] + 1).wall:
			total += g(t[0], t[1] + 1).wall.type.insulation
			n += 1
	if n == 0:
		enc.averageInsulation = 1
	else:
		enc.averageInsulation = total / n

func _process(delta):
	for enc in enclosures:
		_updateTemperature(enc)

func _updateTemperature(enc:Enclosure):
	var temp = %Weather.temperature()
	if not enc.hasCeilings:
		enc.temperature = temp
		return
	var emitters = get_tree().get_nodes_in_group("HeatEmitter")
	emitters = emitters.filter(func(it): return getEnclosure(it.gridX(), it.gridY()) == enc)
	var heatAdded = Util.sum(emitters, func(it): return it.type.heatEmission)
	#print("heatAdded " + str(heatAdded) + " tiles " + str(enc.tiles.size()) + " insulation " + str(enc.averageInsulation))
	enc.temperature = min(30, temp + heatAdded / enc.tiles.size() * enc.averageInsulation)
	#print(str(enc.temperature) + " vs " + str(temp))
