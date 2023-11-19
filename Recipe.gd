class_name Recipe

var inputs:Array = []
var output:ItemType = null
var time:int = 1
var xp:int = 5
var unlocked = false

# List of [name, list of recipes]
static var categories = null:
	get:
		if not categories:
			loadTypes()
		return categories

static func ofName(name:String) -> Recipe:
	for cat in categories:
		for it in cat[1]:
			if it.name == name:
				return it
	return null

static func loadTypes():
	var l:Array = JSON.parse_string(FileAccess.open("res://recipes.json", FileAccess.READ).get_as_text())
	var cats = []
	for c in l:
		var cat = [c.get("name"), []]
		cats.append(cat)
		for i in c.get("recipes"):
			var r = Recipe.new()
			r.time = i.get("time", 1)
			r.output = ItemType.ofName(i["output"])
			r.inputs = i["inputs"].map(func(e): return [ItemType.ofName(e[0]), e[1]])
			r.xp = i.get("xp", 5)
			cat[1].append(r)
	categories = cats

