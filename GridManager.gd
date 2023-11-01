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
