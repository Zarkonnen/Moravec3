extends RigidBody2D
class_name Player

const HEAT_EMIT_DIST = 128

@export var speed = 300.0

var navPath = null
var navPathIndex = 0
var navigate = false
var prevTile = Vector2i.ZERO
var canSetNavTarget = true
var nextNavTarget = Vector2.ZERO
var interactWith:Item = null
var dropAt = Vector2.ZERO

var crafting:Recipe = null
var using:Item = null
var usingInInventory:ItemType = null
var useType:ItemType.Use = null
var useTime = 0

var ouch = 0
var commentTimeout = 0
var doneComments = []
var commentGround = null
var commentGroundTime = 0

var xp:float = 0:
	set(value):
		xp = value
		%XPLabel.text = "XP: " + str(value)
		xpPulse = 1

var xpPulse = 0

var xpSourcesUsed = []

func gainXP(source:String, amt:int):
	if amt and not source in xpSourcesUsed:
		xp += amt
		xpSourcesUsed.append(source)

func doComment(c):
	if not c or c in doneComments:
		return
	doneComments.append(c)
	$Commentary.text = c
	commentTimeout = 5

func setNavTarget(to:Vector2, interact):
	nextNavTarget = to
	interactWith = interact
	using = null

func interactionName(it:Item):
	if it.type.canTake and it.contents.isEmpty() and (it.type.containerSize == 0 or %ContainerContents.container == it):
		return "Pick up " + it.type.name
	if it.type.containerSize > 0:
		return "Open " + it.type.name
	if %Inventory.selectedItem() and it.type.use.has(%Inventory.selectedItem().name):
		var use:ItemType.Use = it.type.use.get(%Inventory.selectedItem().name)
		if "Stamina" in use.stats and %Stats.getValue("Stamina") + use.stats["Stamina"] < 0:
			return use.name + "\nNot enough stamina!"
		return use.name
	if it.type.use.has("any"):
		var use:ItemType.Use = it.type.use.get("any")
		if "Stamina" in use.stats and %Stats.getValue("Stamina") + use.stats["Stamina"] < 0:
			return use.name + "\nNot enough stamina!"
		return use.name
	return ""

func interact(it:Item):
	interactWith = null
	%World.usePause = 0.35
	if it.type.canTake and it.contents.isEmpty() and (it.type.containerSize == 0 or %ContainerContents.container == it):
		%Sound.playSound("take", -40)
		it.quantity -= %Inventory.add(it.type, it.durability, it.quantity)
		if it.quantity <= 0:
			it.unregister()
			if it.type.wall or it.type.ceiling:
				%Grid.collapseCeilings(it.gridX(), it.gridY())
			it.queue_free()
			return
	if it.type.containerSize > 0:
		%ContainerContents.container = it
		%Inventory.updateAllSlots()
		return
	if %Inventory.selectedItem() and it.type.use.has(%Inventory.selectedItem().name):
		use(it, it.type.use.get(%Inventory.selectedItem().name))
		return
	if it.type.use.has("any"):
		use(it, it.type.use.get("any"))
		return

func use(it:Item, useType:ItemType.Use):
	if "Stamina" in useType.stats.keys() and %Stats.getValue("Stamina") + useType.stats["Stamina"] < 0:
		return
	usingInInventory = null
	using = it
	crafting = null
	self.useType = useType
	useTime = 0

func consume(it:ItemType):
	usingInInventory = it
	using = null
	crafting = null
	self.useType = it.use["consume"]
	useTime = 0

func craft(r:Recipe):
	crafting = r
	using = null
	usingInInventory = null
	useTime = 0

func localBrightness():
	return %Weather.brightness()

func localTemperature():
	return %Weather.temperature()

func _process(delta):
	if %Grid.g(gridX(), gridY()):
		var ground = %Grid.g(gridX(), gridY()).ground
		if ground != commentGround:
			commentGround = ground
			commentGroundTime = 0
		else:
			commentGroundTime += delta
			if commentGroundTime >= 4:
				doComment(commentGround.comment)
				commentGroundTime = 0
	if commentTimeout > 0:
		commentTimeout -= delta
		if commentTimeout <= 0:
			$Commentary.text = ""
	if ouch > 0:
		ouch = max(0, ouch - delta * 5)
		$Sprite2D.scale = Vector2(1 - ouch * 0.1, 1 - ouch * 0.1)
	if xpPulse > 0:
		xpPulse = max(0, xpPulse - delta * 5)
		%XPLabel.scale = Vector2(1 + xpPulse * 0.3, 1 + xpPulse * 0.3)
	if using or usingInInventory or crafting:
		useTime += delta * localBrightness()
		%UseProgress.visible = true
		var time = crafting.time if crafting else useType.time
		%UseProgressBar.size.x = clamp(96 * useTime / time, 0, 96)
		if useTime >= time:
			if crafting:
				%Sound.playSound(crafting.sound, crafting.volume)
				doComment(crafting.comment)
				%Crafts.finishCrafting(crafting)
			else:
				%Weather.t += useType.sleepTime
				%Sound.playSound(useType.sound, useType.volume)
				doComment(useType.comment)
				gainXP(useType.xpKey, useType.xp)
				%Inventory.useTool(ItemType.ofName(useType.tool), useType.toolDurability)
				if useType.toolDestroy:
					%Inventory.remove(ItemType.ofName(useType.tool), 1, %Inventory.selectedSlot)
				for entry in useType.spawn:
					var t:ItemType = ItemType.ofName(entry[0])
					var amt = entry[1]
					amt -= %Inventory.add(t, t.durability, amt)
					if amt:
						%DropItem.createItem(t, using.position if using else position, t.durability, amt)
				var turnInto:ItemType = ItemType.ofName(useType.turnInto) if useType.turnInto else null
				if turnInto:
					if using:
						using.type = turnInto
					else:
						%Inventory.remove(usingInInventory)
						if not %Inventory.add(turnInto, turnInto.durability):
							%DropItem.createItem(turnInto, position, turnInto.durability)
				elif useType.destroy:
					if using:
						using.unregister()
						using.queue_free()
					else:
						%Inventory.remove(usingInInventory)
				elif useType.damage and using:
					using.hp -= useType.damage
					using.ouch = 1
					if using.hp <= 0:
						for entry in using.type.loot:
							var t:ItemType = ItemType.ofName(entry[0])
							%DropItem.createItem(t, using.position, t.durability, entry[1])
						using.unregister()
						using.queue_free()
				for statName in useType.stats.keys():
					%Stats.change(statName, useType.stats[statName])
				if using:
					using.durability += useType.durability
			using = null
			usingInInventory = null
			crafting = null
	else:
		%UseProgress.visible = false

func gridX():
	return int(floor(position.x / 128))

func gridY():
	return int(floor(position.y / 96)) - 1

func temperature():
	var enc = %Grid.getEnclosure(gridX(), gridY())
	var temp = enc.temperature if enc else %Weather.temperature()
	for it in get_tree().get_nodes_in_group("HeatEmitter"):
		if self.position.distance_squared_to(it.position) <= HEAT_EMIT_DIST * HEAT_EMIT_DIST:
			temp = max(temp, it.type.heatEmission)
	return temp

func _physics_process(delta):
	var mv = Vector2(0, 0)
	var moveTo = Vector2(0, 0)
	if not is_instance_valid(interactWith):
		interactWith = null
	if canSetNavTarget and nextNavTarget != Vector2.ZERO:
		navPath = %Grid.navigate(position, nextNavTarget)
		navPathIndex = 0
		navigate = true
		canSetNavTarget = false
		nextNavTarget = Vector2.ZERO
	if navPath and position.distance_squared_to(navPath[navPathIndex]) < 10 * 10:
		navPathIndex += 1
	if navPath and navPathIndex >= navPath.size():
		navPath = null
		navigate = false
		canSetNavTarget = true
		if nextNavTarget == Vector2.ZERO:
			if interactWith:
				interact(interactWith)
				interactWith = null
			elif dropAt != Vector2.ZERO and %DropItem.toDrop:
				%DropItem.doDrop(dropAt)
				dropAt = Vector2.ZERO
	elif navPath:
		moveTo = navPath[navPathIndex]
		var gridPos = Vector2i(floor(position.x / 128), floor(position.y / 96))
		if gridPos != prevTile: # This is needed because if we update the nav target faster, the agent breaks.
			canSetNavTarget = true
			prevTile = gridPos
	if Input.is_action_pressed("north"):
		mv.y = -1
	if Input.is_action_pressed("south"):
		mv.y = 1
	if Input.is_action_pressed("east"):
		mv.x = 1
	if Input.is_action_pressed("west"):
		mv.x = -1
	if mv != Vector2.ZERO:
		using = null
		navigate = false
		crafting = null
		if %ContainerContents.container:
			%ContainerContents.container = null
			%Inventory.updateAllSlots()
		nextNavTarget = Vector2.ZERO
	if not navigate:
		mv = mv.normalized() * speed * %Weather.moveSpeedMult() * Util.RATIO * delta
	else:
		if ((moveTo - position) / Util.RATIO).length() <= speed * %Weather.moveSpeedMult() * delta:
			mv = moveTo - position
			moveTo = Vector2.ZERO
		else:
			mv = ((moveTo - position) / Util.RATIO).normalized() * speed * %Weather.moveSpeedMult() * Util.RATIO * delta
	mv.x = clampf(mv.x, -position.x + 1, %Grid.grid[0].size() * 128 - position.x - 1)
	mv.y = clampf(mv.y, -position.y + 1, %Grid.grid.size() * 96 - position.y - 1)
	move_and_collide(mv)
