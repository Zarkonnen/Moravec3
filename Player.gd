extends RigidBody2D

@export var speed = 300.0

@onready var navigation_agent:NavigationAgent2D = $Navigation
var navigate = false
var prevTile = Vector2i.ZERO
var canSetNavTarget = true
var nextNavTarget = Vector2.ZERO

func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 10.0

	# Make sure to not await during _ready.
	call_deferred("actor_setup")

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

func setNavTarget(to:Vector2):
	nextNavTarget = to

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
	else:
		moveTo = navigation_agent.get_next_path_position()
		var gridPos = Vector2i(floor(position.x / 128), floor(position.y / 96))
		if gridPos != prevTile: # This is needed because if we update the nav target faster, the agent breaks.
			canSetNavTarget = true
			prevTile = gridPos
	if Input.is_action_pressed("north"):
		mv.y = -1
		navigate = false
		nextNavTarget = Vector2.ZERO
	if Input.is_action_pressed("south"):
		mv.y = 1
		navigate = false
		nextNavTarget = Vector2.ZERO
	if Input.is_action_pressed("east"):
		mv.x = 1
		navigate = false
		nextNavTarget = Vector2.ZERO
	if Input.is_action_pressed("west"):
		mv.x = -1
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
