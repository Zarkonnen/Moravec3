extends RigidBody2D

@export var speed = 300.0

@onready var navigation_agent:NavigationAgent2D = $Navigation
var navigate = false

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

func setMoveTo(to:Vector2):
	navigation_agent.target_position = to
	navigate = true

func _physics_process(delta):
	var mv = Vector2(0, 0)
	var moveTo = Vector2(0, 0)
	if navigation_agent.is_navigation_finished():
		navigate = false
	else:
		moveTo = navigation_agent.get_next_path_position()
	if Input.is_action_pressed("north"):
		mv.y = -1
		navigate = false
	if Input.is_action_pressed("south"):
		mv.y = 1
		navigate = false
	if Input.is_action_pressed("east"):
		mv.x = 1
		navigate = false
	if Input.is_action_pressed("west"):
		mv.x = -1
		navigate = false
	
	if not navigate:
		mv = mv.normalized() * speed * Util.RATIO * delta
	else:
		if ((moveTo - position) / Util.RATIO).length() <= speed * delta:
			mv = moveTo - position
			moveTo = Vector2.ZERO
		else:
			mv = ((moveTo - position) / Util.RATIO).normalized() * speed * Util.RATIO * delta
	move_and_collide(mv)
