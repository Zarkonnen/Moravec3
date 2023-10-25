class_name Recipe

var inputs:Array = []
var output:ItemType = null
var time:int = 1

static var list = null:
	get:
		if not list:
			loadTypes()
		return list

static func ofName(name:String) -> Recipe:
	for it in list:
		if it.name == name:
			return it
	return null

static func loadTypes():
	var l:Array = JSON.parse_string(FileAccess.open("res://recipes.json", FileAccess.READ).get_as_text())
	var rs = []
	for i in l:
		var r = Recipe.new()
		r.time = i.get("time", 1)
		r.output = ItemType.ofName(i["output"])
		r.inputs = i["inputs"].map(func(e): return [ItemType.ofName(e[0]), e[1]])
		rs.append(r)
	list = rs

