@tool
extends Area2D

var type:ItemType = ItemType.ofName("bush")
var texCopied = false

@export var typeName:String = "bush":
	set(value):
		var t = ItemType.ofName(value)
		if t:
			type = t
			if not texCopied:
				$Sprite2D.texture = $Sprite2D.texture.duplicate()
				texCopied = true
			$Sprite2D.texture.region = t.texRect
			$Sprite2D.offset.y = -t.texRect.size.y / 2
		typeName = value

@export var highlight = false:
	set(value):
		$Sprite2D.material.set_shader_parameter("width", 1.0 if value else 0.0)
		highlight = value

func get_rect():
	var sr:Rect2 = $Sprite2D.get_rect()
	return Rect2(
		position.x + sr.position.x,
		position.y + sr.position.y,
		sr.size.x,
		sr.size.y
	)

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite2D.material = $Sprite2D.material.duplicate()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
