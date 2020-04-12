extends Spatial


var stairs_class = preload("res://Trees/Worlds/LegacyWorld/Stairs/Stairs.gd")

var MOTION_INTERPOLATE_SPEED = 8
var ROTATION_INTERPOLATE_SPEED = 10
var IN_AIR_DELTA = 0.3
var GRAVITY = Vector3(0,-1.62, 0)
var SNAP_VECTOR = Vector3(0.0, 0.1, 0.0)
var JUMP_SPEED = 2.8
var MIN_JUMP_SPEED = 0.2
var MAX_JUMP_TIMER = 0.5
var SPEED_SCALE = 15 #use as 0.1*SPEED_SCALE for time being because of slider for speed setting is int, in OptionsUI.gd

#### Globals for Bot movement ####
var current_point : Vector3 = Vector3() #This is the direction a bot would follow, given a set of instructions. 
var AI_PATH : Array = []
var has_destination : bool = false
var point_number : int = 0
export(bool) var bot : bool = false
var global_character_position : Vector3 = Vector3()
var cumulative_delta : float = 0.0
#############NPCS END#############


const SpeedFeed = {
# 	MOTION_INTERPOLATE_SPEED = 10,
# 	ROTATION_INTERPOLATE_SPEED = 10,
	GRAVITY = Vector3(0,-1.62, 0),
	SNAP_VECTOR = Vector3(0.0, 0.1, 0.0),
	JUMP_SPEED = 2.8
}
export(float) var physics_scale = 1 setget SetPScale

var motion : Vector2 = Vector2()

#################################
# Current state of player avatar
var look_direction = Vector2()
var ground_normal = Vector3(0.0, -1.0, 0.0)
var mouse_sensitivity = 0.10
var max_up_aim_angle = 55.0
var max_down_aim_angle = 55.0
var root_motion = Transform()

var velocity = Vector3()
var motion_target = Vector2()
var input_direction  = 0.0
var animation_speed = 1.0
var in_air = false
var in_air_accomulate = 0 #smooth short in air situations, duration is IN_AIR_DELTA
var land = false
var is_jumping = false
var jump = false
var jump_timeout = 0.0
var flies = false
var climbing_stairs = false
var stairs = null
var climb_point = 0
var climb_progress = 0.0
var climb_direction = 1.0
var climb_look_direction = Vector3()
var movementstate = walking

var id setget SetID
var nocamera = false
var jump_timer = 0.0
onready var model = $KinematicBody/Model
var camera_control
var camera_control_path

const walking = 0
const flailing = 1
const climbing = 2
const jumping = 3

#################################
##Networking
export(bool) var puppet = false setget set_remote_player
puppet var puppet_translation
puppet var puppet_rotation
puppet var puppet_jump
puppet var puppet_jump_blend
puppet var puppet_animation_speed
puppet var puppet_motion
puppet var puppet_anim_state
puppet var puppet_climb_dir
puppet var puppet_climb_progress_up
puppet var puppet_climb_progress_down 

var network = false setget SetNetwork
var nonetwork = ! network

var pants_mat
var shirt_mat
var skin_mat
var hair_mat
var shoes_mat



#################################
# Init functions
func Jump(variant):
	pass
func _enter_tree():
	set_player_group()
	if Lobby.local_id!=1 and bot:
		puppet = true


	

func set_player_group(enable=true): # for local only
	if not  is_inside_tree():
		return
	var pg = Options.player_data.player_group
	if puppet == false and not is_in_group(pg):
		#printd("add avatar(%s), puppet(%s) to %s group" % [get_path(), puppet, pg])
		add_to_group(pg, true)
	if puppet == true and is_in_group(pg):
		#printd("remove avatar(%s), puppet(%s) from %s group" % [get_path(), puppet, pg])
		remove_from_group(pg)

func SetID(var _id):
	id = _id



func SetPScale(scale):
	if scale < 0.01 or scale > 100:
		return
	for k in SpeedFeed:
		match k:
			_:
				self.set(k, SpeedFeed[k] * scale)

#################################
# _process functions
func _unhandled_input(event):
	# FIXME: This should be dealt with elsewhere
	if PauseMenu.is_open() or bot:
		return
	
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

	if event.is_action_pressed("move_right"):
		motion_target.x = motion_target.x + 1.0
	elif event.is_action_released("move_right"):
		motion_target.x = motion_target.x - 1.0
	elif event.is_action_pressed("move_left"):
		motion_target.x = motion_target.x - 1.0
	elif event.is_action_released("move_left"):
		motion_target.x = motion_target.x + 1.0
	elif event.is_action_pressed("move_forwards"):
		motion_target.y = motion_target.y + 1.0
	elif event.is_action_released("move_forwards"):
		motion_target.y = motion_target.y - 1.0
	elif event.is_action_pressed("move_backwards"):
		motion_target.y = motion_target.y - 1.0
	elif event.is_action_released("move_backwards"):
		motion_target.y = motion_target.y + 1.0

	if event.is_action_pressed("player_back_in_time"):
		PopRPoint()

	if event.is_action_pressed("use"):
		if not climbing_stairs:
			DoInteractiveObjectCheck()
		else:
			StopStairsClimb()

	if event.is_action("zoom_in") and not Input.is_action_pressed("move_run"):
		camera_control.DecreaseDistance()

	if event.is_action("zoom_out") and not Input.is_action_pressed("move_run"):
		camera_control.IncreaseDistance()

	if event.is_action_pressed("scroll_up") and Input.is_action_pressed("move_run") and animation_speed < 3.0:
		animation_speed += 0.25
	elif event.is_action_pressed("scroll_down") and Input.is_action_pressed("move_run") and animation_speed > 0.5:
		animation_speed -= 0.25

func ShowMouseCursor():
	pass

func HideMouseCursor():
	pass



func _physics_process(delta):
	if Lobby.isConnected:
		UpdateNetworking()
#	if puppet and not bot:
#		return
	if not puppet:
		SaveRPoints(delta)
	if bot and not puppet:
		if current_point.length()<0.01:
			motion_target = Vector2(0,0)
		else:
			motion_target = Vector2(0,1)
		camera_control.look_at((current_point), Vector3(0,1,0))
		global_character_position = to_global($KinematicBody.translation)
		bot_movement(delta)
	HandleOnGround(delta)
	HandleMovement()
	HandleControls(delta)



func HandleOnGround(delta):
	if $KinematicBody/OnGround.is_colliding() and in_air:
		in_air = false
		land = true
		in_air_accomulate = 0
		$KinematicBody/OnGround.cast_to.y = -0.1
	elif not $KinematicBody/OnGround.is_colliding() and not in_air and not climbing_stairs:
		in_air_accomulate += delta
		if in_air_accomulate >= IN_AIR_DELTA:
			in_air = true
			$KinematicBody/OnGround.cast_to.y = -0.04

func HandleMovement():
	$KinematicBody/AnimationTree["parameters/Walk/blend_position"] = motion
	$KinematicBody/AnimationTree["parameters/MovementSpeed/scale"] = animation_speed

func HandleControls(var delta):
	if puppet:# and not bot:
		return
	
	# FIXME: controls need to be dealt with elsewhere
	if PauseMenu.is_open():
		motion_target = Vector2()
		input_direction = 0.0
		jump = false
	elif not bot:
		jump = Input.is_action_pressed("jump")
		input_direction = (Input.get_action_strength("move_forwards") - Input.get_action_strength("move_backwards"))
	if bot:
		input_direction = 1# to_local(current_point) - $KinematicBody.translation
	if jump_timeout > 0.0:
		jump_timeout -= delta
		if jump_timeout <= 0.0:
			$KinematicBody/AnimationTree["parameters/JumpAmount/blend_amount"] = 0.0
			is_jumping = false
		else:
			$KinematicBody/AnimationTree["parameters/JumpAmount/blend_amount"] = jump_timeout / 2.0
	elif jump and not in_air and not climbing_stairs and jump_timer < MAX_JUMP_TIMER:
		jump = false
		jump_timer += delta
		$KinematicBody/AnimationTree["parameters/JumpAmount/blend_amount"] = jump_timer / MAX_JUMP_TIMER
		if not is_jumping:
			is_jumping = true
	elif is_jumping:
		Jump(jump_timer)
		jump_timer = 0.0
		$KinematicBody/AnimationTree["parameters/MovementState/current"] = flailing
		movementstate = flailing

	if climbing_stairs:
		UpdateClimbingStairs(delta)
		return

	if in_air and movementstate == walking:
		$KinematicBody/AnimationTree["parameters/MovementState/current"] = flailing
		movementstate = flailing
	elif not in_air and movementstate == flailing and jump_timeout <= 0.0:
		$KinematicBody/AnimationTree["parameters/MovementState/current"] = walking
		movementstate = walking

	if land:
		$KinematicBody/AnimationTree["parameters/Land/active"] = true
		land = false

	#Only control the character when it is on the floor.
	if not in_air:
		motion = motion.linear_interpolate(motion_target, MOTION_INTERPOLATE_SPEED * delta)
# 		#printd("%s = motion.linear_interpolate(%s, %s * %s)" % [motion, motion_target, MOTION_INTERPOLATE_SPEED, delta])
	else:
		pass

	ground_normal = $KinematicBody/OnGround.get_collision_normal()

	#Update the model rotation based on the camera look direction.
	var target_direction = -camera_control.camera.global_transform.basis.z
	target_direction.y = 0.0
	if model.global_transform.origin != model.global_transform.origin - target_direction and not in_air:
		var target_transform = model.global_transform.looking_at(model.global_transform.origin - target_direction, Vector3(0, 1, 0))
		orientation.basis = model.global_transform.basis.slerp(target_transform.basis, delta * ROTATION_INTERPOLATE_SPEED)

	if not in_air and not is_jumping:
		#Retrieve the root motion from the animationtree so it can be applied to the KinematicBody.
		root_motion = $KinematicBody/AnimationTree.get_root_motion_transform()
		orientation *= root_motion

		var h_velocity = (orientation.origin / delta) * 0.1 * SPEED_SCALE
		if bot:
			h_velocity.x *= abs((to_local(current_point)-$KinematicBody.translation).normalized().x )
			h_velocity.z *=abs((to_local(current_point)-$KinematicBody.translation).normalized().z)
			
		
		var velocity_direction = h_velocity.normalized()
		var slide_direction  = velocity_direction.slide(ground_normal)

		h_velocity = slide_direction * h_velocity.length()

# 		#printd("h_velocity(%s) = (orientation.origin(%s) / delta(%s))" % [h_velocity, orientation.origin, delta])
		velocity.x = h_velocity.x
		velocity.y = h_velocity.y

		#When the character is moving apply a bigger gravity so that the character stays on the ground.
		if motion_target != Vector2():
			velocity.y += -2.0 * animation_speed * delta
		else:
			velocity += GRAVITY * delta

		velocity.z = h_velocity.z
	else:
		#When in the air or jumping apply the normal gravity to the character.
		velocity += GRAVITY * delta

	velocity = $KinematicBody.move_and_slide(velocity, Vector3(0,1,0), motion_target == Vector2())

	orientation.origin = Vector3()
	orientation = orientation.orthonormalized()

	#The model direction is calculated with both camera direction and animation movement.
	if motion_target != Vector2():
		model.global_transform.basis = orientation.basis

func UpdateClimbingStairs(var delta):
	var kb_pos = $KinematicBody.global_transform.origin

	if climb_point % 2 == 0:
		climb_progress = abs((2.0 if climb_direction > 0.0 else 0.0) - abs((kb_pos.y - stairs.climb_points[climb_point].y) / stairs.step_size))
	else:
		climb_progress = abs((2.0 if climb_direction > 0.0 else 0.0) - (1.0 + abs(kb_pos.y - stairs.climb_points[climb_point].y) / stairs.step_size))

	#Check for next climb point.
	if climb_point + 1 < stairs.climb_points.size() and kb_pos.y > stairs.climb_points[climb_point].y:
		climb_point += 1
	#Check for previous climb point.
	elif climb_point - 1 >= 0 and kb_pos.y < stairs.climb_points[climb_point - 1].y:
		climb_point -= 1

	if climb_point == stairs.climb_points.size() - 1 and kb_pos.y > stairs.climb_points[climb_point].y and not input_direction <= 0.0:
		$KinematicBody/AnimationTree["parameters/MovementState/current"] = walking

		motion = motion.linear_interpolate(motion_target, MOTION_INTERPOLATE_SPEED * delta)

		#Update the model rotation based on the camera look direction.
		var target_direction = -camera_control.camera.global_transform.basis.z
		target_direction.y = 0.0

		var target_transform = model.global_transform.looking_at(model.global_transform.origin - target_direction, Vector3(0, 1, 0))
		orientation.basis = model.global_transform.basis.slerp(target_transform.basis, delta * ROTATION_INTERPOLATE_SPEED)

		#Retrieve the root motion from the animationtree so it can be applied to the KinematicBody.
		root_motion = $KinematicBody/AnimationTree.get_root_motion_transform()
		orientation *= root_motion

		var h_velocity = (orientation.origin / delta) * 0.1 * SPEED_SCALE

		velocity.x = h_velocity.x
		velocity.y = 0.0
		velocity.z = h_velocity.z

		orientation.origin = Vector3()
		orientation = orientation.orthonormalized()
#		if motion_target != Vector2():
#			model.global_transform.basis = orientation.basis

		climb_look_direction = stairs.GetLookDirection(kb_pos)

		#Stop climbing at the top when too far away from the stairs.
		if kb_pos.distance_to(stairs.climb_points[climb_point]) > 0.12:
			StopStairsClimb()
	else:
		$KinematicBody/AnimationTree["parameters/MovementState/current"] = climbing
		#Automatically move towards the climbing point horizontally.
		var flat_velocity = (stairs.climb_points[climb_point] - kb_pos) * delta * 150.0
		flat_velocity.y = 0.0
		velocity = flat_velocity
		velocity += Vector3(0, input_direction * delta * 3.0, 0)
		var target_transform = model.global_transform.looking_at(model.global_transform.origin - climb_look_direction, Vector3(0, 1, 0))
		model.global_transform.basis = target_transform.basis
		orientation.basis = target_transform.basis

	#When moving down and at the bottom of the stairs, then let go.
	if input_direction < 0.0 and climb_point < 2 and not in_air:
		StopStairsClimb()

	if input_direction > 0.0:
		if $KinematicBody/AnimationTree["parameters/ClimbDirection/current"] == 1:
			$KinematicBody/AnimationTree["parameters/ClimbDirection/current"] = 0
			climb_direction = 1.0
	elif input_direction < 0.0:
		if $KinematicBody/AnimationTree["parameters/ClimbDirection/current"] == 0:
			climb_direction = -1.0
			$KinematicBody/AnimationTree["parameters/ClimbDirection/current"] = 1

	if climb_direction == 1.0:
		$KinematicBody/AnimationTree["parameters/ClimbProgressUp/seek_position"] = climb_progress
	else:
		$KinematicBody/AnimationTree["parameters/ClimbProgressDown/seek_position"] = climb_progress

	velocity = $KinematicBody.move_and_slide(velocity, Vector3(0,1,0), false)

func StopStairsClimb():
	climbing_stairs = false
	stairs = null
	climb_point = -1
	$KinematicBody/AnimationTree["parameters/MovementState/current"] = walking

func DoInteractiveObjectCheck():
	var space_state = get_world().direct_space_state
	var params = PhysicsShapeQueryParameters.new()
	var sphere = SphereShape.new()
	var kb_pos = $KinematicBody.global_transform.origin

	sphere.radius = 0.03
	params.set_shape(sphere)
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.transform.origin = kb_pos
	params.collision_mask = 2

	var results = space_state.intersect_shape(params)

	#Get the closest stairs to start climbing.
	var closest_object = null
	for result in results:
		if closest_object == null or result.collider.global_transform.origin.distance_to(kb_pos) < closest_object.global_transform.origin.distance_to(kb_pos):
			closest_object = result.collider

	if closest_object != null:
		if closest_object is stairs_class:
			climbing_stairs = true
			stairs = closest_object
			climb_look_direction = stairs.GetLookDirection(kb_pos)
			#Get the closest step to start climbing from.
			for index in stairs.climb_points.size():
				if climb_point == -1 or stairs.climb_points[index].distance_to(kb_pos) < stairs.climb_points[climb_point].distance_to(kb_pos):
					climb_point = index
		elif closest_object.has_method("activate"):
			closest_object.activate()

#################################
# networking functions

#	else:
#		printd("UpdateNetworking: not a remote player(%s) and not a network_master and network(%s)" % [get_path(), network])



#################################
# Debugger functions
func CreateDebugLine(var from, var to):
	$KinematicBody/ImmediateGeometry.clear()
	$KinematicBody/ImmediateGeometry.begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	$KinematicBody/ImmediateGeometry.add_vertex(from)
	$KinematicBody/ImmediateGeometry.add_vertex(to)
	$KinematicBody/ImmediateGeometry.end()

## Restore Positions
var rp_max_points = 100
var rp_delta = 5
var rp_delta_o = 1 #minimal offset to be recorded
var rp_time = 0
var rp_points = []

func PopRPoint():
	if rp_points.size() > 0:
			#printd("-----%s %s %s" % [rp_points.size(), get_path(), rp_points[0]])
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
							#printd("+++++%s %s %s" % [rp_points.size(), get_path(), rp_points[0]])

func set_remote_player(if_remote):
	puppet = if_remote
