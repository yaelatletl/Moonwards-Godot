extends Spatial

export(bool) var remote_player = false setget SetRemotePlayer
export(NodePath) var camera_control_path
onready var camera_control = null

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
var running = false
var in_air = false
var land = false
var jumping = false
var network = false setget SetNetwork
var flies = false
var movementstate = walk
var username = "username" setget SetUsername
var id setget SetID

const GRAVITY = Vector3(0,-1.62, 0)
const JUMP_SPEED = 0.75
const walk = 0
const flail = 1

##Networking
var puppet = false
puppet var puppet_translation
puppet var puppet_rotation
puppet var puppet_jump
puppet var puppet_run
puppet var puppet_motion

var nonetwork = true

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	orientation = $KinematicBody/Model.global_transform
	orientation.origin = Vector3()
	if not remote_player:
		camera_control = get_node(camera_control_path)
	else:
		set_process_input(false)

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
	jumping = false
	velocity.y += JUMP_SPEED

func _physics_process(delta):
	if $KinematicBody/OnGround.is_colliding() and in_air:
		in_air = false
		land = true
	elif not $KinematicBody/OnGround.is_colliding() and not in_air:
		in_air = true
	
	HandleControls(delta)
	UpdateNetworking()
	HandleMovement()

func HandleMovement():
	$KinematicBody/AnimationTree["parameters/Walk/blend_position"] = motion
	if jumping:
		$KinematicBody/AnimationTree["parameters/Jump/active"] = true
	if running:
		$KinematicBody/AnimationTree["parameters/MovementSpeed/scale"] = 3.0
	else:
		$KinematicBody/AnimationTree["parameters/MovementSpeed/scale"] = 1.0

func HandleControls(var delta):
	if remote_player:
		return
	var motion_target = Vector2( 	Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
									Input.get_action_strength("move_forwards") - Input.get_action_strength("move_backwards"))
	
	if Input.is_action_just_pressed("jump") and not in_air and not jumping:
		jumping = true
	
	if in_air and movementstate == walk:
		$KinematicBody/AnimationTree["parameters/MovementState/current"] = flail
		movementstate = flail
	elif not in_air and movementstate == flail:
		$KinematicBody/AnimationTree["parameters/MovementState/current"] = walk
		movementstate = walk
	
	if land:
		$KinematicBody/AnimationTree["parameters/Land/active"] = true
		land = false
	
	#Only control the character when it is on the floor.
	if not in_air:
		motion = motion.linear_interpolate(motion_target, MOTION_INTERPOLATE_SPEED * delta)
	else:
		pass
	
	#Multiply the movement animation when running. The animation takes care of the actual movement speed.
	if Input.is_action_pressed("move_run"):
		running = true
	else:
		running = false
	
	#Update the model rotation based on the camera look direction.
	var target_direction = -camera_control.camera.global_transform.basis.z
	target_direction.y = 0.0
	if $KinematicBody/Model.global_transform.origin != $KinematicBody/Model.global_transform.origin - target_direction and not in_air and not jumping:
		var target_transform = $KinematicBody/Model.global_transform.looking_at($KinematicBody/Model.global_transform.origin - target_direction, Vector3(0, 1, 0))
		orientation.basis = $KinematicBody/Model.global_transform.basis.slerp(target_transform.basis, delta * ROTATION_INTERPOLATE_SPEED)
	
	if not in_air:
		#Retrieve the root motion from the animationtree so it can be applied to the KinematicBody.
		root_motion = $KinematicBody/AnimationTree.get_root_motion_transform()
		orientation *= root_motion
		
		var h_velocity = (orientation.origin / delta)
		velocity.x = h_velocity.x
		velocity.z = h_velocity.z
	
	velocity += GRAVITY * delta
	
	#The true is for stopping on a slope.
	velocity = $KinematicBody.move_and_slide_with_snap(velocity, Vector3(0.0, 0.0, 0.0), Vector3(0,1,0), true)
	
	orientation.origin = Vector3()
	orientation = orientation.orthonormalized()
	
	#The model direction is calculated with both camera direction and animation movement.
	if motion_target != Vector2():
		$KinematicBody/Model.global_transform.basis = orientation.basis

func UpdateNetworking():
	if not network:
		return
	if remote_player:
		if puppet_translation != null:
			$KinematicBody.global_transform.origin = puppet_translation
		if puppet_rotation != null:
			$KinematicBody/Model.global_transform.basis = puppet_rotation
		if puppet_jump != null:
			jumping = puppet_jump
		if puppet_motion != null:
			motion = puppet_motion
		if puppet_run != null:
			running = puppet_run
	else:
		rset_unreliable("puppet_translation", $KinematicBody.global_transform.origin)
		rset_unreliable("puppet_rotation", $KinematicBody/Model.global_transform.basis)
		rset_unreliable("puppet_motion", motion)
		rset_unreliable("puppet_jump", jumping)
		rset_unreliable("puppet_run", running)

func SetID(var _id):
	id = _id

func SetUsername(var _username):
	username = _username
	$KinematicBody/Nametag/Viewport/Username.text = username

func SetNetwork(var enabled):
	network = enabled
	nonetwork = ! enable

	if network:
		rset_config("puppet_translation", MultiplayerAPI.RPC_MODE_PUPPET)
		rset_config("puppet_rotation",  MultiplayerAPI.RPC_MODE_PUPPET)
		rset_config("puppet_motion",  MultiplayerAPI.RPC_MODE_PUPPET)
		rset_config("puppet_jump",  MultiplayerAPI.RPC_MODE_PUPPET)
		rset_config("puppet_run",  MultiplayerAPI.RPC_MODE_PUPPET)
	else:
		rset_config("puppet_translation", MultiplayerAPI.RPC_MODE_DISABLED)
		rset_config("puppet_rotation",  MultiplayerAPI.RPC_MODE_DISABLED)
		rset_config("puppet_motion",  MultiplayerAPI.RPC_MODE_DISABLED)
		rset_config("puppet_jump", MultiplayerAPI.RPC_MODE_DISABLED)
		rset_config("puppet_run", MultiplayerAPI.RPC_MODE_DISABLED)

