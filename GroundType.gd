class_name GroundType

var name:String
var comment:String
var atlasTile:Vector2i
var traversable:bool
var terrain = -1

func _init(name, x, y):
	self.name = name
	atlasTile = Vector2i(x, y)

static var types = null:
	get:
		if not types or Engine.is_editor_hint():
			loadTypes()
		return types

static func ofName(name:String) -> GroundType:
	for it in types:
		if it.name == name:
			return it
	return null

static func loadTypes():
	var l:Array = JSON.parse_string(FileAccess.open("res://groundTypes.json", FileAccess.READ).get_as_text())
	var ts = []
	for i in l:
		var gt = GroundType.new(i["name"], i["x"], i["y"])
		gt.traversable = i.get("traversable", true)
		gt.terrain = i.get("terrain", -1)
		gt.comment = i.get("comment", "")
		ts.append(gt)
	types = ts
