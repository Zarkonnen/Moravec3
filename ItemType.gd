class_name ItemType

var name:String
var comment:String
var texRect:Rect2
var texRect2:Rect2
var canTake:bool = false
var stacking:int = 1
var use:Dictionary = {}
var durability:int = 1
var rotInterval:int = 0
var rotInto:String
var spawnOnRotOutside:Array = []
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
var bagCapacity:int = 0
var clothing:bool = false
var clothingWetnessMult:float = 1
var clothingDamageMult:float = 1
var clothingDamageAbsorb:float = 0
var interact:Dictionary = {}
var interactable:bool = false

# Creature stuff
var creature:bool = false
var hp:float = 1
var loot:Array = []
var roamRandomly:bool = false
var idleMoveSpeed:float = 0
var moveSpeed:float = 0
var fleeFromPlayerDist:float = 0
var fleeFromPlayerWhenInjuredDist:float = 0
var attackPlayerDist:float = 0
var attackPlayerWhenInjuredDist:float = 0
var attackCooldown:float = 1
var attackDamage:float = 0
var attackSound:String = ""
var attackVolume:float = -20

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
		it.comment = i.get("comment", "")
		it.canTake = i.get("canTake", false)
		it.stacking = i.get("stacking", 1)
		it.durability = i.get("durability", 1)
		it.rotInterval = i.get("rotInterval", 0)
		it.rotInto = i.get("rotInto", "")
		it.spawnOnRotOutside = i.get("spawnOnRotOutside", [])
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
		it.bagCapacity = i.get("bagCapacity", 0)
		it.clothing = i.get("clothing", false)
		it.clothingWetnessMult = i.get("clothingWetnessMult", 1)
		it.clothingDamageMult = i.get("clothingDamageMult", 1)
		it.clothingDamageAbsorb = i.get("clothingDamageAbsorb", 0)
		it.interactable = i.get("interactable", false)
		
		# Creature stuff
		it.creature = i.get("creature", false)
		it.hp = i.get("hp", 1)
		it.loot = i.get("loot", [])
		it.roamRandomly = i.get("roamRandomly", false)
		it.idleMoveSpeed = i.get("idleMoveSpeed", 0)
		it.moveSpeed = i.get("moveSpeed", 0)
		it.fleeFromPlayerDist = i.get("fleeFromPlayerDist", 0)
		it.fleeFromPlayerWhenInjuredDist = i.get("fleeFromPlayerWhenInjuredDist", 0)
		it.attackPlayerDist = i.get("attackPlayerDist", 0)
		it.attackPlayerWhenInjuredDist = i.get("attackPlayerWhenInjuredDist", 0)
		it.attackCooldown = i.get("attackCooldown", 1)
		it.attackDamage = i.get("attackDamage", 0)
		it.attackSound = i.get("attackSound", "")
		it.attackVolume = i.get("attackVolume", -20)

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
				u.damage = useV.get("damage", 0)
				u.xp = useV.get("xp", 0)
				u.xpKey = useV.get("xpKey", u.name + " " + u.tool)
				u.comment = useV.get("comment", "")
				u.sound = useV.get("sound", "")
				u.volume = useV.get("volume", -20)
				u.sleepTime = useV.get("sleepTime", 0)
				it.use[useK] = u
		if i.has("interact"):
			var interacts:Dictionary = i.get("interact")
			for ik in interacts.keys():
				var iv = interacts[ik]
				var interaction = Interaction.new()
				interaction.other = ik
				interaction.turnInto = iv.get("turnInto", "")
				interaction.otherTurnInto = iv.get("otherTurnInto", "")
				interaction.destroy = iv.get("destroy", false)
				interaction.otherDestroy = iv.get("otherDestroy", false)
				interaction.sound = iv.get("sound", "")
				interaction.volume = iv.get("volume", "")
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
	var damage = 0
	var xpKey = ""
	var xp = 0
	var comment:String = ""
	var sound:String = ""
	var volume:float = -20
	var sleepTime:float = 0

class Interaction:
	var other:String
	var turnInto:String = ""
	var otherTurnInto:String = ""
	var destroy:bool = false
	var otherDestroy:bool = false
	var sound:String = ""
	var volume:float = -20
