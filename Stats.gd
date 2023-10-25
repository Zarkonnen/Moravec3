extends Node

class Stat:
	var name:String
	var color:Color
	var value:int
	var recentValue:int
	var valueChangeTimeout
	var autoChangeAmount
	var autoChangeInterval
	var autoChangeTimeout
	func _init(name, color, value, autoChangeAmount=0, autoChangeInterval=5):
		self.name = name
		self.color = color
		self.value = value
		self.recentValue = value
		self.valueChangeTimeout = 0
		self.autoChangeAmount = autoChangeAmount
		self.autoChangeInterval = autoChangeInterval
		self.autoChangeTimeout = autoChangeInterval

var stats = [Stat.new("Food", Color("597646"), 100, -1, 10), Stat.new("HP", Color("d53846"), 50, 1, 20)]
var byName = {}

func _ready():
	for stat in stats:
		byName[stat.name] = stat
		update(stat)

func change(name, delta):
	byName[name].value = clamp(byName[name].value + delta, 0, 100)
	byName[name].valueChangeTimeout = 1
	update(byName[name])
	
func getValue(name) -> int:
	return byName[name].value

func _process(delta):
	for stat in stats:
		stat.valueChangeTimeout -= delta
		if stat.valueChangeTimeout <= 0:
			stat.recentValue = stat.value
			update(stat)
		stat.autoChangeTimeout -= delta
		if stat.autoChangeTimeout <= 0:
			change(stat.name, stat.autoChangeAmount)
			stat.autoChangeTimeout = stat.autoChangeInterval
		
func update(stat):
	var sb = get_node(stat.name)
	sb.get_node("Label").text = stat.name
	var b = sb.get_node("Bar")
	b.color = stat.color
	b.size.x = 96 * stat.value / 100
	var ch = sb.get_node("Change")
	if stat.recentValue != stat.value:
		print("Change")
		ch.position.x = b.position.x + b.size.x
		ch.size.x = abs(stat.recentValue - stat.value)
		if stat.recentValue < stat.value:
			ch.position.x -= abs(stat.recentValue - stat.value)
		ch.visible = true
	else:
		ch.visible = false
