extends Spatial

export(NodePath) var camera_control_path
onready var camera_control = get_node(camera_control_path)

const MOTION_INTERPOLATE_SPEED = 10
const ROTATION_INTERPOLATE_SPEED = 10
var motion = Vector2()

var look_direction = Vector2()
var mouse_sensitivity = 0.10
var max_up_aim_angle = 55.0
var max_down_aim_angle = 55.0
var root_motion = Transform()
var orientation = Transform()
var velocity = Vector3()
var run = false

const GRAVITY = Vector3(0,-1.62, 0)
const JUMP_SPEED = 0.5

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	orientation = $KinematicBody/Model.global_transform
	orientation.origin = Vector3()

func _input(event):
	if (event is InputEventMouseMotion):
		look_direction.x -= event.relative.x * mouse_sensitivity
		look_direction.y -= event.relative.y * mouse_sensitivity
		
		if look_direction.x > 360:
			look_direction.x = 0
		elif look_direction.x < 0:
			look_direction.x = 360
		if look_direction.y > max_up_aim_angle:
			look_direction.y = max_up_aim_angle
		elif look_direction.y < -max_down_aim_angle:
			look_direction.y = -max_down_aim_angle
		
		camera_control.Rotate(look_direction)

func Jump():
	velocity.y += JUMP_SPEED

func _physics_process(delta):
	HandleMovement(delta)
	HandleJump()

func HandleMovement(var delta):
	var motion_target = Vector2( 	Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
									Input.get_action_strength("move_forwards") - Input.get_action_strength("move_backwards"))
	
	#Only control the character when it is on the floor.
	if $KinematicBody.is_on_floor():
		motion = motion.linear_interpolate(motion_target, MOTION_INTERPOLATE_SPEED * delta)
	else:
		#Interpolate to standing still when in the air.
		motion = motion.linear_interpolate(Vector2(), MOTION_INTERPOLATE_SPEED * delta)
	$KinematicBody/AnimationTree["parameters/Walk/blend_position"] = motion
	
	#Multiply the movement animation when running. The animation takes care of the actual movement speed.
	if Input.is_action_pressed("move_run"):
		if not run:
			$KinematicBody/AnimationTree["parameters/MovementSpeed/scale"] = 3.0
			run = true
	elif run:
		$KinematicBody/AnimationTree["parameters/MovementSpeed/scale"] = 1.0
		run = false
	
	#Update the model rotation based on the camera look direction.
	var target_direction = -camera_control.camera.global_transform.basis.z
	target_direction.y = 0.0
	if $KinematicBody/Model.global_transform.origin != $KinematicBody/Model.global_transform.origin - target_direction:
		var target_transform = $KinematicBody/Model.global_transform.looking_at($KinematicBody/Model.global_transform.origin - target_direction, Vector3(0, 1, 0))
		orientation.basis = $KinematicBody/Model.global_transform.basis.slerp(target_transform.basis, delta * ROTATION_INTERPOLATE_SPEED)
	
	#Retrieve the root motion from the animationtree so it can be applied to the KinematicBody.
	root_motion = $KinematicBody/AnimationTree.get_root_motion_transform()
	orientation *= root_motion
	
	var h_velocity = (orientation.origin / delta)
	velocity.x = h_velocity.x
	velocity.z = h_velocity.z
	velocity += GRAVITY * delta
	
	#The true is for stopping on a slope.
	velocity = $KinematicBody.move_and_slide_with_snap(velocity, Vector3(1.0, 1.0, 1.0), Vector3(0,1,0), true)
	
	orientation.origin = Vector3()
	orientation = orientation.orthonormalized()
	
	#The model direction is calculated with both camera direction and animation movement.
	if motion_target != Vector2():
		$KinematicBody/Model.global_transform.basis = orientation.basis

func HandleJump():
	if Input.is_action_just_pressed("jump"):
		$KinematicBody/AnimationTree["parameters/Jump/active"] = true