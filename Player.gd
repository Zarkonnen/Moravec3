extends RigidBody2D

@export var speed = 300.0

@onready var navigation_agent:NavigationAgent2D = $Navigation
var navigate = false
var prevTile = Vector2i.ZERO
var canSetNavTarget = true
var nextNavTarget = Vector2.ZERO
var interactWith:Item = null
var dropAt = Vector2.ZERO

func _ready():
	call_deferred("actor_setup")

func actor_setup():
	await get_tree().physics_frame

func setNavTarget(to:Vector2, interact):
	nextNavTarget = to
	interactWith = interact

func interact(it:Item):
	if it.type.canTake and %Inventory.add(it.type):
		it.queue_free()

func _physics_process(delta):
	var mv = Vector2(0, 0)
	var moveTo = Vector2(0, 0)
	if canSetNavTarget and nextNavTarget != Vector2.ZERO:
		navigation_agent.target_position = nextNavTarget
		navigate = true
		canSetNavTarget = false
		nextNavTarget = Vector2.ZERO
	if navigation_agent.is_navigation_finished():
		navigate = false
		canSetNavTarget = true
		if nextNavTarget == Vector2.ZERO:
			if interactWith:
				interact(interactWith)
				interactWith = null
			elif dropAt != Vector2.ZERO and %DropItem.toDrop:
				%DropItem.doDrop(dropAt)
				dropAt = Vector2.ZERO
	else:
		moveTo = navigation_agent.get_next_path_position()
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
		navigate = false
		nextNavTarget = Vector2.ZERO
	if not navigate:
		mv = mv.normalized() * speed * Util.RATIO * delta
	else:
		if ((moveTo - position) / Util.RATIO).length() <= speed * delta:
			mv = moveTo - position
			moveTo = Vector2.ZERO
		else:
			mv = ((moveTo - position) / Util.RATIO).normalized() * speed * Util.RATIO * delta
	move_and_collide(mv)
