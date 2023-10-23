extends RigidBody2D



@export var speed = 300.0
var moveTo:Vector2 = Vector2.ZERO

func _physics_process(delta):
	var mv = Vector2(0, 0)
	if Input.is_action_pressed("north"):
		mv.y = -1
		moveTo = Vector2.ZERO
	if Input.is_action_pressed("south"):
		mv.y = 1
		moveTo = Vector2.ZERO
	if Input.is_action_pressed("east"):
		mv.x = 1
		moveTo = Vector2.ZERO
	if Input.is_action_pressed("west"):
		mv.x = -1
		moveTo = Vector2.ZERO
	
	if moveTo == Vector2.ZERO:
		mv = mv.normalized() * speed * Util.RATIO * delta
	else:
		if ((moveTo - position) / Util.RATIO).length() <= speed * delta:
			mv = moveTo - position
			moveTo = Vector2.ZERO
		else:
			mv = ((moveTo - position) / Util.RATIO).normalized() * speed * Util.RATIO * delta
	move_and_collide(mv)
