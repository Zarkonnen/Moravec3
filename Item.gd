@tool
extends StaticBody2D
class_name Item

var texCopied = false
var type:ItemType = ItemType.ofName("bush"):
	set(t):
		type = t
		$Label.position.y = -t.texRect.size.y - 30
		set_collision_layer_value(1, t.wall and not t.door)
		$Sprite2D.z_index = 3 if t.ceiling else 0
		if t.snapToGrid and Engine.is_editor_hint():
			snapToGridAndRegister()
		if not texCopied:
			$Sprite2D.texture = $Sprite2D.texture.duplicate()
			texCopied = true
		$Sprite2D.texture.region = t.texRect
		$Sprite2D.offset.y = -t.texRect.size.y / 2

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

func get_rect():
	var sr:Rect2 = $Sprite2D.get_rect()
	return Rect2(
		position.x + sr.position.x,
		position.y + sr.position.y,
		sr.size.x,
		sr.size.y
	)

func gridX():
	return int(floor(position.x / 128))

func gridY():
	return int(floor(position.y / 96)) - 1

func unregister():
	if type.snapToGrid:
		if type.wall and $/root/Node2D/Walls.g(gridX(), gridY()) == self:
			$/root/Node2D/Walls.p(gridX(), gridY(), null)
			$/root/Node2D/Walls.wallRemoved(gridX(), gridY())
		if type.ceiling and $/root/Node2D/Ceilings.g(gridX(), gridY()) == self:
			$/root/Node2D/Ceilings.p(gridX(), gridY(), null)

func snapToGridAndRegister():
	var gridX = gridX()
	var gridY = gridY()
	position.x = gridX * 128 + 64
	position.y = gridY * 96 + 96
	if not Engine.is_editor_hint():
		if type.wall:
			$/root/Node2D/Walls.p(gridX, gridY, self)
			$/root/Node2D/Walls.wallAdded(gridX, gridY)
		if type.ceiling:
			$/root/Node2D/Ceilings.p(gridX, gridY, self)

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite2D.material = $Sprite2D.material.duplicate()
	$Label.position.y = -type.texRect.size.y - 30
	if type.snapToGrid:
		snapToGridAndRegister()
	
func _process(delta):
	if type.wall and get_node("../Player") and abs(get_node("../Player").position.x - position.x) <= 64 and get_node("../Player").position.y < position.y and get_node("../Player").position.y > position.y - 96 * 2:
		$Sprite2D.material.set_shader_parameter("a", 0.35)
	else:
		$Sprite2D.material.set_shader_parameter("a", 1)
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
