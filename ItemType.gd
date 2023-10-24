class_name ItemType

var name:String
var texRect:Rect2
var canTake:bool = false
var stacking:int = 1

func _init(name, texRect):
	self.name = name
	self.texRect = texRect

static var types = null:
	get:
		if not types:
			loadTypes()
		return types

static func ofName(name:String) -> ItemType:
	for it in types:
		if it.name == name:
			return it
	return null

static func loadTypes():
	var l:Array = JSON.parse_string(FileAccess.open("res://itemTypes.json", FileAccess.READ).get_as_text())
	var ts = []
	for i in l:
		var it = ItemType.new(i["name"], Rect2(i["x"], i["y"], i["w"], i["h"]))
		it.canTake = i.get("canTake", false)
		it.stacking = i.get("stacking", 1)
		ts.append(it)
	types = ts
