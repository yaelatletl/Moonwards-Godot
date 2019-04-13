extends Spatial

var camera_control_path = "KinematicBody/PlayerCamera"
var camera_control

var MOTION_INTERPOLATE_SPEED = 10
var ROTATION_INTERPOLATE_SPEED = 10
var IN_AIR_DELTA = 0.3
var GRAVITY = Vector3(0,-1.62, 0)
var SNAP_VECTOR = Vector3(0.0, 0.1, 0.0)
var JUMP_SPEED = 2.8

const SpeedFeed = {
	MOTION_INTERPOLATE_SPEED = 10,
	ROTATION_INTERPOLATE_SPEED = 10,
	GRAVITY = Vector3(0,-1.62, 0),
	SNAP_VECTOR = Vector3(0.0, 0.1, 0.0),
	JUMP_SPEED = 2.8
}
var physics_scale = 1 setget SetPScale

func SetPScale(scale):
	if scale < 0.01 or scale > 100:
		return
	for k in SpeedFeed:
		match k:
			_:
				self.set(k, SpeedFeed[k] * scale)

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

const walk = 0
const flail = 1

##Networking
export(bool) var puppet = false setget SetRemotePlayer
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
	if not puppet:
		camera_control = get_node(camera_control_path)
	else:
		set_process_input(false)
	SetRemotePlayer(puppet)

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
	if event.is_action_pressed("player_back_in_time"):
		PopRPoint()


func Jump():
	jumping = false
	velocity.y += JUMP_SPEED

func _physics_process(delta):
	if puppet:
		HandleOnGround(delta)
		UpdateNetworking()
		HandleMovement()
	else:
		HandleOnGround(delta)
		HandleControls(delta)
		UpdateNetworking()
		HandleMovement()
		SaveRPoints(delta)

var in_air_accomulate = 0
func HandleOnGround(delta):
	if $KinematicBody/OnGround.is_colliding() and in_air:
		in_air = false
		land = true
		in_air_accomulate = 0
	elif not $KinematicBody/OnGround.is_colliding() and not in_air:
		in_air_accomulate += delta
		if in_air_accomulate >= IN_AIR_DELTA:
			in_air = true

func HandleMovement():
	$KinematicBody/AnimationTree["parameters/Walk/blend_position"] = motion
	if jumping:
		$KinematicBody/AnimationTree["parameters/Jump/active"] = true
	if running:
		$KinematicBody/AnimationTree["parameters/MovementSpeed/scale"] = 3.0
	else:
		$KinematicBody/AnimationTree["parameters/MovementSpeed/scale"] = 1.0

func HandleControls(var delta):
	if puppet:
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
	velocity = $KinematicBody.move_and_slide_with_snap(velocity, SNAP_VECTOR, Vector3(0,1,0), true)
	printd("velocity %s" %velocity)
	
	orientation.origin = Vector3()
	orientation = orientation.orthonormalized()
	
	#The model direction is calculated with both camera direction and animation movement.
	if motion_target != Vector2():
		$KinematicBody/Model.global_transform.basis = orientation.basis

func UpdateNetworking():
	if nonetwork:
		return
	if puppet:
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
	elif is_network_master():
		rset_unreliable("puppet_translation", $KinematicBody.global_transform.origin)
		rset_unreliable("puppet_rotation", $KinematicBody/Model.global_transform.basis)
		rset_unreliable("puppet_motion", motion)
		rset_unreliable("puppet_jump", jumping)
		rset_unreliable("puppet_run", running)
	else:
		printd("UpdateNetworking: not a remote player(%s) and not a network_master and network(%s)" % [get_path(), network])

func SetID(var _id):
	id = _id

func SetUsername(var _username):
	username = _username
	$KinematicBody/Nametag/Viewport/Username.text = username

func SetNetwork(var enabled):
	network = enabled
	nonetwork = ! enabled
	printd("Player %s enable/disable networking, nonetwork(%s)" % [get_path(), nonetwork])

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

func SetRemotePlayer(enable):
	puppet = enable
	if not puppet:
		$KinematicBody/Nametag.visible = false
		$Camera.current = true
	else:
		$KinematicBody/Nametag.visible = true
		$Camera.current = false

## Restore Positions
var rp_max_points = 100
var rp_delta = 5
var rp_delta_o = 1
var rp_time = 0
var rp_points = []

func PopRPoint():
	if rp_points.size() > 0:
			printd("-----%s %s %s" % [rp_points.size(), get_path(), rp_points[0]])
			$KinematicBody.global_transform = rp_points.pop_front()
			rp_time = 0

func SaveRPoints(delta):
	#save position if not in air, and if previous one is more than rp_delta
	rp_time += delta
	if not in_air:
			if rp_points.size() == 0:
					rp_points.append($KinematicBody.global_transform)
			if rp_points.size() > rp_max_points:
					rp_points.pop_back()
			if rp_time > rp_delta:
					var kbo = $KinematicBody.global_transform.origin
					if rp_points[0].origin.distance_to(kbo) > rp_delta_o:
							rp_time = 0
							rp_points.push_front($KinematicBody.global_transform)
							printd("+++++%s %s %s" % [rp_points.size(), get_path(), rp_points[0]])

#####################
#var debug = true
var debug_id = "Player2.gd:: "
var debug_list = [
#	{ enable = true, key = "" }
]
func printd(s):
	if debug:
		if debug_list.size() > 0:
			var found = false
			for dl in debug_list:
				if s.begins_with(dl.key):
					if dl.enable:
						print(debug_id, s)
					found = true
					break
			if not found:
				print(debug_id, s)
		else:
			print(debug_id, s)
