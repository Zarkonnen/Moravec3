extends Node

var neg:Array = []
var pos:Array = []

func g(x, y):
	var a:Array = pos
	if y < 0:
		y = -y - 1
		a = neg
	if y >= a.size():
		return null
	var row = a[y]
	if row == null:
		return null
	if x < 0:
		row = row[0]
		x = -x - 1
	else:
		row = row[1]
	if x >= row.size():
		return null
	return row[x]

func p(x, y, item):
	var a:Array = pos
	if y < 0:
		y = -y - 1
		a = neg
	if y >= a.size():
		a.resize(y + 1)
	if a[y] == null:
		a[y] = [[], []]
	var row = a[y]
	if x < 0:
		row = row[0]
		x = -x - 1
	else:
		row = row[1]
	if x >= row.size():
		row.resize(x + 1)
	row[x] = item

func wallSupportStrength(x, y, ceilings):
	# find all reachable walls via ceilings in a certain max range
	# subtract distance from wall strengths and return strongest
	# this is subtly wrong because we're using manhattan distance instead of actual path distance
	var strength = 0
	var queue:Array = [[x-1, y], [x+1, y], [x, y-1], [x, y+1]]
	var reached:Array = [[x, y]]
	while not queue.is_empty():
		var t = queue.pop_front()
		reached.append(t)
		var wall = g(t[0], t[1])
		if wall:
			strength = max(strength, wall.type.wallSupportRange - abs(x - t[0]) - abs(y - t[1]) + 1)
		if wall or ceilings.g(t[0], t[1]):
			if not [t[0]-1, t[1]] in reached:
				queue.append([t[0]-1, t[1]])
			if not [t[0]+1, t[1]] in reached:
				queue.append([t[0]+1, t[1]])
			if not [t[0], t[1]-1] in reached:
				queue.append([t[0], t[1]-1])
			if not [t[0], t[1]+1] in reached:
				queue.append([t[0], t[1]+1])
	return strength

func collapseCeilings(x, y, ceilings):
	# Call this when removing a wall or ceiling
	# Find all connected ceilings
	# check their wall support strength
	# delete them and spawn
	var queue:Array = [[x-1, y], [x+1, y], [x, y-1], [x, y+1]]
	var reached:Array = [[x, y]]
	while not queue.is_empty():
		var t = queue.pop_front()
		reached.append(t)
		var ceiling = ceilings.g(t[0], t[1])
		if ceiling:
			if wallSupportStrength(t[0], t[1], ceilings) <= 0:
				ceiling.unregister()
				ceiling.queue_free()
				for entry in ceiling.type.spawnOnCollapse:
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
	func _init(tiles):
		self.tiles = tiles
		enclosureCounter += 1
		number = enclosureCounter

var enclosures:Array = []

func getEnclosure(x, y, except=[]) -> Enclosure:
	var xy = [x, y]
	return Util.first(enclosures, func(e): return e not in except and xy in e.tiles)

func wallAdded(x, y):
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
					enc = null
				elif not encs.any(func(e): return start in e.tiles):
					# We need a new enclosure.
					var newEnc = Enclosure.new(fill)
					enclosures.append(newEnc)
					encs.append(newEnc)
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
				enclosures.append(Enclosure.new(fill))
	
func wallRemoved(x, y):
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
					

func _enclosureFill(x, y, maxDist=10):
	# Flood fill, starting at x, y. If we reach a tile that is more than maxdist away, return null.
	# Otherwise, check if the area covered by the reached list is no more than maxdist across.
	# Return the reached list.
	if g(x, y):
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
		if not g(t[0], t[1]):
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

