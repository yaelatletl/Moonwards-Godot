extends KinematicBody
class_name Character


enum STATE {
	WALKING
	FLAILING
	CLIMBING
	JUMPING
}

var MOTION_INTERPOLATE_SPEED = 8
var ROTATION_INTERPOLATE_SPEED = 10
var IN_AIR_DELTA = 0.3
var GRAVITY = Vector3(0,-1.62, 0)
var SNAP_VECTOR = Vector3(0.0, 0.1, 0.0)
var JUMP_SPEED = 2.8
var MIN_JUMP_SPEED = 0.2
var MAX_JUMP_TIMER = 0.5
var SPEED_SCALE = 15 #use as 0.1*SPEED_SCALE for time being because of slider for speed setting is int, in OptionsUI.gd


var animation_speed = 1.0

var is_puppet : bool = false
var is_bot : bool  = false

var input_direction : float = 0.0
var jump : bool = false
var jump_timeout : float = 0.0

var climbing_stairs : bool = false
var in_air : bool = false
var velocity : Vector3
var motion_target
var orientation
var movementstate : int = STATE.WALKING
var stairs = null
var climb_point = 0
var climb_progress = 0.0
var climb_direction = 1.0
var climb_look_direction = Vector3()
var ground_normal : Vector3 = Vector3()
var npc_velocity : bool = false


var current_point : Vector3
var camera_control : Spatial
var model : Spatial
var motion 
var root_motion 

func StopStairsClimb():
	climbing_stairs = false
	stairs = null
	climb_point = -1
	$AnimationTree["parameters/MovementState/current"] = STATE.WALKING


func UpdateClimbingStairs(var delta):
	var kb_pos = global_transform.origin

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
		$AnimationTree["parameters/MovementState/current"] = STATE.WALKING

		motion = motion.linear_interpolate(motion_target, MOTION_INTERPOLATE_SPEED * delta)

		#Update the model rotation based on the camera look direction.
		var target_direction = -camera_control.camera.global_transform.basis.z
		target_direction.y = 0.0

		var target_transform = model.global_transform.looking_at(model.global_transform.origin - target_direction, Vector3(0, 1, 0))
		orientation.basis = model.global_transform.basis.slerp(target_transform.basis, delta * ROTATION_INTERPOLATE_SPEED)

		#Retrieve the root motion from the animationtree so it can be applied to the KinematicBody.
		root_motion = $AnimationTree.get_root_motion_transform()
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
		$AnimationTree["parameters/MovementState/current"] = STATE.CLIMBING
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
		if $AnimationTree["parameters/ClimbDirection/current"] == 1:
			$AnimationTree["parameters/ClimbDirection/current"] = 0
			climb_direction = 1.0
	elif input_direction < 0.0:
		if $AnimationTree["parameters/ClimbDirection/current"] == 0:
			climb_direction = -1.0
			$AnimationTree["parameters/ClimbDirection/current"] = 1

	if climb_direction == 1.0:
		$AnimationTree["parameters/ClimbProgressUp/seek_position"] = climb_progress
	else:
		$AnimationTree["parameters/ClimbProgressDown/seek_position"] = climb_progress

	velocity = move_and_slide(velocity, Vector3(0,1,0), false)


func jump(var timer):
	var new_jump_vel = max(MIN_JUMP_SPEED, min(JUMP_SPEED, timer * JUMP_SPEED / MAX_JUMP_TIMER))
	velocity.y += new_jump_vel
	jump_timeout = 1.0

func movement(var delta):
	if is_puppet:# and not bot:
		return
	if PauseMenu.is_open():
		motion_target = Vector2()
		input_direction = 0.0
		jump = false
	if is_bot:
		input_direction = 1
	if jump_timeout > 0.0:
		jump_timeout -= delta
		if jump_timeout <= 0.0:
			$AnimationTree["parameters/JumpAmount/blend_amount"] = 0.0
			jump = false
		else:
			$AnimationTree["parameters/JumpAmount/blend_amount"] = jump_timeout / 2.0
	elif jump and not in_air and not climbing_stairs and jump_timeout < MAX_JUMP_TIMER:
		jump = false
		jump_timeout += delta
		$AnimationTree["parameters/JumpAmount/blend_amount"] = jump_timeout / MAX_JUMP_TIMER
		if not jump:
			jump = true
	elif jump:
		jump(jump_timeout)
		jump_timeout = 0.0
		$AnimationTree["parameters/MovementState/current"] = STATE.FLAILING
		movementstate = STATE.FLAILING

	if climbing_stairs:
		UpdateClimbingStairs(delta)
		return

	if in_air and movementstate == STATE.WALKING:
		$AnimationTree["parameters/MovementState/current"] = STATE.FLAILING
		movementstate = STATE.FLAILING
	elif not in_air and movementstate == STATE.FLAILING and jump_timeout <= 0.0:
		$AnimationTree["parameters/MovementState/current"] = STATE.WALKING
		movementstate = STATE.WALKING

	if is_on_floor():
		$AnimationTree["parameters/Land/active"] = true


	#Only control the character when it is on the floor.
	if not in_air:
		motion = motion.linear_interpolate(motion_target, MOTION_INTERPOLATE_SPEED * delta)
# 		#printd("%s = motion.linear_interpolate(%s, %s * %s)" % [motion, motion_target, MOTION_INTERPOLATE_SPEED, delta])
	else:
		pass

	ground_normal = $OnGround.get_collision_normal()

	#Update the model rotation based on the camera look direction.
	var target_direction = -camera_control.camera.global_transform.basis.z
	target_direction.y = 0.0
	if model.global_transform.origin != model.global_transform.origin - target_direction and not in_air:
		var target_transform = model.global_transform.looking_at(model.global_transform.origin - target_direction, Vector3(0, 1, 0))
		orientation.basis = model.global_transform.basis.slerp(target_transform.basis, delta * ROTATION_INTERPOLATE_SPEED)

	if not in_air and not jump:
		#Retrieve the root motion from the animationtree so it can be applied to the KinematicBody.
		root_motion = $AnimationTree.get_root_motion_transform()
		orientation *= root_motion

		var h_velocity = (orientation.origin / delta) * 0.1 * SPEED_SCALE
		if npc_velocity:
			h_velocity.x *= abs((to_local(current_point)-translation).normalized().x)
			h_velocity.z *= abs((to_local(current_point)-translation).normalized().z)
			
		
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

	velocity = move_and_slide(velocity, Vector3(0,1,0), motion_target == Vector2())

	orientation.origin = Vector3()
	orientation = orientation.orthonormalized()

	#The model direction is calculated with both camera direction and animation movement.
	if motion_target != Vector2():
		model.global_transform.basis = orientation.basis
