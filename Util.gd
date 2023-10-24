class_name Util

static var ASPECT = 0.75
static var RATIO = Vector2(1, ASPECT)

static func first(l, q):
	for x in l:
		if q.call(x):
			return x
	return null

static func most(l, f):
	var most = null
	var found = false
	var quality = 0
	for x in l:
		var q = f.call(x)
		if not found or q > quality:
			found = true
			most = x
			quality = q
	return most
