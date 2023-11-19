class_name Util

static var ASPECT = 0.75
static var RATIO = Vector2(1, ASPECT)

static func minL(l, f):
	var minV = 0
	var set = false
	for e in l:
		var v = f.call(e)
		if not set:
			minV = v
			set = true
		else:
			minV = min(v, minV)
	return minV
	
static func maxL(l, f):
	var maxV = 0
	var set = false
	for e in l:
		var v = f.call(e)
		if not set:
			maxV = v
			set = true
		else:
			maxV = max(v, maxV)
	return maxV

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

static func sum(l, f):
	var amt = 0
	for x in l:
		amt += f.call(x)
	return amt
