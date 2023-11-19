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
	var warnOnBelow:int
	func _init(name, color, value, autoChangeAmount=0, autoChangeInterval=5, warnOnBelow=-1):
		self.name = name
		self.color = color
		self.value = value
		self.recentValue = value
		self.valueChangeTimeout = 0
		self.autoChangeAmount = autoChangeAmount
		self.autoChangeInterval = autoChangeInterval
		self.autoChangeTimeout = autoChangeInterval
		self.warnOnBelow = warnOnBelow

var t = 0

var stats = [\
		Stat.new("Food", Color("597646"), 100, -1, 10, 20),\
		Stat.new("HP", Color("d53846"), 50, 1, 20, 20),\
		Stat.new("Warmth", Color("90242a"), 100, 0, 5, 20),\
		Stat.new("Wetness", Color("62798d"), 0, 0, 1),\
		]
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
	t += delta
	for stat in stats:
		updateWarning(stat)
		stat.valueChangeTimeout -= delta
		if stat.valueChangeTimeout <= 0:
			stat.recentValue = stat.value
			update(stat)
		stat.autoChangeTimeout -= delta
		if stat.autoChangeTimeout <= 0:
			var amt = stat.autoChangeAmount
			if stat.name == "Warmth":
				var temp = %Player.temperature()
				if temp < 0:
					amt = -5
				elif temp < 10:
					amt = -2
				elif temp < 15:
					amt = -1
				elif temp >= 20 and temp < 25:
					amt = 2
				else:
					amt = 4
				var wet = getValue("Wetness")
				if wet > 50:
					amt -= 3
				elif wet > 20:
					amt -= 1
			if stat.name == "Wetness":
				if %Ceilings.g(%Player.gridX(), %Player.gridY()):
					amt = -1
				else:
					amt = %Weather.wetnessPerTime()
				if amt < 0:
					var temp = %Player.temperature()
					if temp >= 30:
						amt -= 2
					elif temp >= 22:
						amt -= 1
			change(stat.name, amt)
			stat.autoChangeTimeout = stat.autoChangeInterval
		
func update(stat):
	var sb = get_node(stat.name)
	sb.get_node("Label").text = stat.name
	var b = sb.get_node("Bar")
	b.color = stat.color
	b.size.x = 96 * stat.value / 100
	var ch = sb.get_node("Change")
	if stat.recentValue != stat.value:
		ch.position.x = b.position.x + b.size.x
		ch.size.x = abs(stat.recentValue - stat.value)
		if stat.recentValue < stat.value:
			ch.position.x -= abs(stat.recentValue - stat.value)
		ch.visible = true
	else:
		ch.visible = false

func updateWarning(stat):
	get_node(stat.name).get_node("Border").color = "ffffff" if stat.value < stat.warnOnBelow and fmod(t, 1) < 0.5 else "7e7d78"
	
