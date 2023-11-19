class_name ItemType

var name:String
var texRect:Rect2
var texRect2:Rect2
var canTake:bool = false
var stacking:int = 1
var use:Dictionary = {}
var durability:int = 1
var rotInterval:int = 0
var rotInto:String
var containerSize:int = 0
var containerTimeMult:float = 1.0
var snapToGrid:bool = false
var wall:bool = false
var door:bool = false
var ceiling:bool = false
var wallSupportRange = 2
var spawnOnCollapse:Array = []
var heatEmission:float = 0
var insulation:float = 0
var lightEmission:float = 0
var lightColor:Color = Color.WHITE

func _init(name, texRect):
	self.name = name
	self.texRect = texRect

static var types = null:
	get:
		if not types or Engine.is_editor_hint():
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
		if i.has("x2"):
			it.texRect2 = Rect2(i["x2"], i["y2"], i["w2"], i["h2"])
		it.canTake = i.get("canTake", false)
		it.stacking = i.get("stacking", 1)
		it.durability = i.get("durability", 1)
		it.rotInterval = i.get("rotInterval", 0)
		it.rotInto = i.get("rotInto", "")
		it.containerSize = i.get("containerSize", 0)
		it.containerTimeMult = i.get("containerTimeMult", 1.0)
		it.snapToGrid = i.get("snapToGrid", false)
		it.wall = i.get("wall", false)
		it.door = i.get("door", false)
		it.ceiling = i.get("ceiling", false)
		it.wallSupportRange = i.get("wallSupportRange", 2)
		it.spawnOnCollapse = i.get("spawnOnCollapse", [])
		it.heatEmission = i.get("heatEmission", 0)
		it.insulation = i.get("insulation", 0)
		it.lightEmission = i.get("lightEmission", 0)
		if i.has("lightColor"):
			it.lightColor = Color(i.get("lightColor"))
		if i.has("use"):
			var uses:Dictionary = i.get("use")
			for useK in uses.keys():
				var useV = uses[useK]
				var u = Use.new()
				u.tool = useK
				u.name = useV["name"]
				u.time = useV.get("time", 1)
				u.turnInto = useV.get("turnInto", "")
				u.destroy = useV.get("destroy", false)
				u.spawn = useV.get("spawn", [])
				u.stats = useV.get("stats", {})
				u.toolDurability = useV.get("toolDurability", 0)
				it.use[useK] = u
		ts.append(it)
	types = ts

class Use:
	var name:String = ""
	var tool:String = "any"
	var time = 1
	var turnInto:String = ""
	var destroy:bool = false
	var spawn:Array = []
	var stats:Dictionary = {}
	var toolDurability = 0
