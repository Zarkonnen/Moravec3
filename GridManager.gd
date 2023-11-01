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
