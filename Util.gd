class_name Util

static var ASPECT = 0.75
static var RATIO = Vector2(1, ASPECT)

static func minL(l, f):
	var minV = 0
	var isSet = false
	for e in l:
		var v = f.call(e)
		if not isSet:
			minV = v
			isSet = true
		else:
			minV = min(v, minV)
	return minV
	
static func maxL(l, f):
	var maxV = 0
	var isSet = false
	for e in l:
		var v = f.call(e)
		if not isSet:
			maxV = v
			isSet = true
		else:
			maxV = max(v, maxV)
	return maxV

static func first(l, q):
	for x in l:
		if q.call(x):
			return x
	return null

static func most(l, f):
	var theMost = null
	var found = false
	var quality = 0
	for x in l:
		var q = f.call(x)
		if not found or q > quality:
			found = true
			theMost = x
			quality = q
	return theMost

static func sum(l, f):
	var amt = 0
	for x in l:
		amt += f.call(x)
	return amt
