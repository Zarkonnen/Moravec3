@tool
extends StaticBody2D
class_name Item

var texCopied = false
var type:ItemType = ItemType.ofName("bush"):
	set(t):
		type = t
		contents.size = type.containerSize
		rotTimeout = t.rotInterval
		if type.heatEmission:
			add_to_group("HeatEmitter")
		else:
			remove_from_group("HeatEmitter")
		if type.lightEmission:
			$Light.enabled = true
			$Light.scale = Vector2(type.lightEmission, type.lightEmission)
			$Light.color = type.lightColor
			$Light.position.y = -t.texRect.size.y / 2
		else:
			$Light.enabled = false
		$Label.position.y = -t.texRect.size.y - 30
		set_collision_layer_value(1, t.wall and not t.door)
		$Sprite2D.z_index = 3 if t.ceiling else 0
		if t.snapToGrid and Engine.is_editor_hint():
			snapToGridAndRegister()
		if not texCopied:
			$Sprite2D.texture = $Sprite2D.texture.duplicate()
			$Layer2.texture = $Layer2.texture.duplicate()
			texCopied = true
		$Sprite2D.texture.region = t.texRect
		$Sprite2D.offset.y = -t.texRect.size.y / 2
		if t.texRect2:
			$Layer2.texture.region = t.texRect2
			$Layer2.offset.y = -t.texRect2.size.y / 2
			$Layer2.visible = true
		else:
			$Layer2.visible = false

@export var quantity:int = 1:
	set(value):
		quantity = value
		$Quantity.text = "" if quantity < 2 else str(quantity)
		
var durability = 0
var rotTimeout = 0

@export var typeName:String = "bush":
	set(value):
		var t = ItemType.ofName(value)
		if t:
			type = t
		typeName = value

@export var highlight:String = "":
	set(value):
		$Sprite2D.material.set_shader_parameter("strength", 0.2 if value else 0.0)
		highlight = value
		$Label.text = value

var contents:ItemContainer = ItemContainer.new(0)

func get_rect():
	var sr:Rect2 = $Sprite2D.get_rect()
	return Rect2(
		position.x + sr.position.x,
		position.y + sr.position.y,
		sr.size.x,
		sr.size.y
	)
	
static func xToGrid(x):
	return int(floor(x / 128))

static func yToGrid(y):
	return int(floor(y / 96)) - 1

func gridX():
	return int(floor(position.x / 128))

func gridY():
	return int(floor(position.y / 96)) - 1

func unregister():
	if type.snapToGrid:
		if type.wall and $/root/Node2D/Walls.g(gridX(), gridY()) == self:
			$/root/Node2D/Walls.p(gridX(), gridY(), null)
			$/root/Node2D/Walls.wallRemoved(gridX(), gridY(), $/root/Node2D/Ceilings)
		if type.ceiling and $/root/Node2D/Ceilings.g(gridX(), gridY()) == self:
			$/root/Node2D/Ceilings.p(gridX(), gridY(), null)
			$/root/Node2D/Walls.ceilingRemoved(gridX(), gridY(), $/root/Node2D/Ceilings)

func snapToGridAndRegister():
	var gridX = gridX()
	var gridY = gridY()
	position.x = gridX * 128 + 64
	position.y = gridY * 96 + 96
	if not Engine.is_editor_hint():
		if type.wall:
			$/root/Node2D/Walls.p(gridX, gridY, self)
			$/root/Node2D/Walls.wallAdded(gridX, gridY, $/root/Node2D/Ceilings)
		if type.ceiling:
			$/root/Node2D/Ceilings.p(gridX, gridY, self)
			$/root/Node2D/Walls.ceilingAdded(gridX, gridY, $/root/Node2D/Ceilings)

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite2D.material = $Sprite2D.material.duplicate()
	$Layer2.material = $Layer2.material.duplicate()
	$Label.position.y = -type.texRect.size.y - 30
	$Quantity.text = "" if quantity < 2 else str(quantity)
	if type.snapToGrid:
		snapToGridAndRegister()
	
func _process(delta):
	if Engine.is_editor_hint():
		return
	var alpha = 1.0
	var player:Player = get_node("../Player")
	if player:
		if type.wall and\
				abs(player.position.x - position.x) <= 64 and\
				player.position.y < position.y and\
				player.position.y > position.y - 96 * 2:
			alpha = 0.3
		elif type.ceiling:
			var playerEnclosure:GridManager.Enclosure = get_node("../Walls").getEnclosure(player.gridX(), player.gridY())
			var myEnclosure:GridManager.Enclosure = get_node("../Walls").getEnclosure(gridX(), gridY())
			if playerEnclosure and playerEnclosure == myEnclosure:
				alpha = 0.3
			elif player.gridX() == gridX() and player.gridY() == gridY():
				alpha = 0.3
	$Sprite2D.material.set_shader_parameter("a", alpha)
	contents.update(delta * type.containerTimeMult)
	if type.rotInterval:
		rotTimeout -= delta
		if rotTimeout <= 0:
			durability -= 1
			rotTimeout = type.rotInterval
			if durability <= 0:
				var rotInto = ItemType.ofName(type.rotInto)
				if rotInto:
					type = rotInto
					durability = rotInto.durability
				else:
					queue_free()
