@tool
extends StaticBody2D
class_name Item

var texCopied = false
var type:ItemType = ItemType.ofName("bush"):
	set(t):
		type = t
		contents.size = type.containerSize
		rotTimeout = t.rotInterval
		hp = t.hp
		attackTimeout = t.attackCooldown
		durability = t.durability
		$Nearby.monitorable = t.interactable
		$Nearby.monitoring = not t.interact.is_empty()
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
		$Sprite2D.material.set_shader_parameter("tint", t.tint)
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
var hp = 1
var attackTimeout = 0
var pathTimeout = 0
var navPath = null
var navPathIndex = 0
var moveTo:Vector2 = Vector2.ZERO
var ouch = 0

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
		if type.wall and $/root/Node2D/Grid.g(gridX(), gridY()).wall == self:
			$/root/Node2D/Grid.g(gridX(), gridY()).wall = null
			$/root/Node2D/Grid.wallRemoved(gridX(), gridY())
		if type.ceiling and $/root/Node2D/Grid.g(gridX(), gridY()).ceiling == self:
			$/root/Node2D/Grid.g(gridX(), gridY()).ceiling = null
			$/root/Node2D/Grid.ceilingRemoved(gridX(), gridY())

func snapToGridAndRegister():
	var gridX = gridX()
	var gridY = gridY()
	position.x = gridX * 128 + 64
	position.y = gridY * 96 + 96
	if not Engine.is_editor_hint():
		if type.wall:
			$/root/Node2D/Grid.g(gridX, gridY).wall = self
			$/root/Node2D/Grid.wallAdded(gridX, gridY)
		if type.ceiling:
			$/root/Node2D/Grid.g(gridX, gridY).ceiling = self
			$/root/Node2D/Grid.ceilingAdded(gridX, gridY)

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite2D.material = $Sprite2D.material.duplicate()
	$Sprite2D.material.set_shader_parameter("tint", type.tint)
	$Layer2.material = $Layer2.material.duplicate()
	$Label.position.y = -type.texRect.size.y - 30
	$Quantity.text = "" if quantity < 2 else str(quantity)
	moveTo = position
	if type.snapToGrid:
		snapToGridAndRegister()
	
func _process(delta):
	if Engine.is_editor_hint():
		return
	if ouch > 0:
		ouch = max(0, ouch - delta * 5)
		$Sprite2D.scale = Vector2(1 - ouch * 0.1, 1 - ouch * 0.1)
	var alpha = 1.0
	var player:Player = get_node("../../Player")
	if player:
		if type.creature:
			_creatureProcess(delta)
		if type.wall and\
				abs(player.position.x - position.x) <= 64 and\
				player.position.y < position.y and\
				player.position.y > position.y - 96 * 2:
			alpha = 0.3
		elif type.ceiling:
			var playerEnclosure:GridManager.Enclosure = get_node("../../Grid").getEnclosure(player.gridX(), player.gridY())
			var myEnclosure:GridManager.Enclosure = get_node("../../Grid").getEnclosure(gridX(), gridY())
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
				for entry in type.spawnOnRotOutside:
					var st:ItemType = ItemType.ofName(entry[0])
					%DropItem.createItem(st, position, st.durability, entry[1])
				var rotInto = ItemType.ofName(type.rotInto)
				if rotInto:
					type = rotInto
					durability = rotInto.durability
				else:
					queue_free()

func _creatureProcess(delta):
	if attackTimeout > 0 and type.attackDamage:
		attackTimeout -= delta
	if type.attackDamage and attackTimeout <= 0 and position.distance_squared_to(%Player.position) < 40 * 40:
		%Sound.playSound(type.attackSound, type.attackVolume)
		var dmg = type.attackDamage
		if %Inventory.clothing:
			dmg = dmg * %Inventory.clothing.clothingDamageMult - %Inventory.clothing.clothingDamageAbsorb
		%Stats.change("HP", -max(0, dmg))
		attackTimeout = type.attackCooldown
		if dmg > 0:
			%Player.ouch = 1
	pathTimeout -= delta * (2 if hp < type.hp else 1)
	if pathTimeout <= 0:
		pathTimeout = randf_range(2, 8)
		moveTo = position
		var dsq = position.distance_squared_to(%Player.position)
		var injured = hp < type.hp
		if dsq < type.fleeFromPlayerDist * type.fleeFromPlayerDist or\
				(injured and dsq < type.fleeFromPlayerWhenInjuredDist * type.fleeFromPlayerWhenInjuredDist):
			moveTo = position + (position - %Player.position).normalized() * 500
		elif dsq < type.attackPlayerDist * type.attackPlayerDist or\
				(injured and dsq < type.attackPlayerWhenInjuredDist * type.attackPlayerWhenInjuredDist):
			moveTo = %Player.position
		elif type.roamRandomly:
			moveTo = position + Vector2(randf_range(-500, 500), randf_range(-500, 500))
		navPath = %Grid.navigate(position, moveTo)
		navPathIndex = 0
	if navPath and position.distance_squared_to(navPath[navPathIndex]) < 10 * 10:
		navPathIndex += 1
		if navPathIndex >= navPath.size():
			navPath = null
	if navPath:
		var sp = type.moveSpeed if hp < type.hp else type.idleMoveSpeed
		if ((navPath[navPathIndex] - position) / Util.RATIO).length() <= sp * delta:
			position = navPath[navPathIndex]
		else:
			position += (navPath[navPathIndex] - position).normalized() * sp * Util.RATIO * delta


func _on_nearby_area_entered(other):
	other = other.get_parent()
	if not is_instance_of(other, Item):
		return
	if not other.type.name in type.interact:
		return
	var interaction:ItemType.Interaction = type.interact[other.type.name]
	if interaction.destroy:
		unregister()
		queue_free()
	elif interaction.turnInto:
		type = ItemType.ofName(interaction.turnInto)
	if interaction.otherDestroy:
		other.unregister()
		other.queue_free()
	elif interaction.otherTurnInto:
		other.type = ItemType.ofName(interaction.otherTurnInto)
	if interaction.sound:
		%Sound.playSound(interaction.sound, interaction.volume)
