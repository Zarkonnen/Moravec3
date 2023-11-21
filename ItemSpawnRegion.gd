class_name ItemSpawnRegion

var type:ItemType
var quantity:int
var radius:float
var itemQuantity:int

static var types = null:
	get:
		if not types or Engine.is_editor_hint():
			loadTypes()
		return types

static func loadTypes():
	var l:Array = JSON.parse_string(FileAccess.open("res://itemSpawnRegions.json", FileAccess.READ).get_as_text())
	var ts = []
	for i in l:
		var isr:ItemSpawnRegion = ItemSpawnRegion.new()
		isr.type = ItemType.ofName(i["type"])
		isr.itemQuantity = i["itemQuantity"]
		isr.radius = i["radius"]
		isr.quantity = i["quantity"]
		ts.append(isr)
	types = ts
