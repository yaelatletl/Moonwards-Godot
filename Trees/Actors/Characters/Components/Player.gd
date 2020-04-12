extends Node
""" 
Component node for player input 
"""
var actor : KinematicBody = null

export(NodePath) var camera_control_path : NodePath = ""
var camera_control : Spatial = null

var mouse_sensitivity : float = 0.10
var max_up_aim_angle : float = 55.5
var max_down_aim_angle : float = 55.5

func _ready():
	if get_parent() is Character:
		actor = get_parent()
	
func _unhandled_input(event):
	if actor == null:
		return
	if PauseMenu.is_open():
		return
	
	if (event is InputEventMouseMotion):
		actor.look_direction.x -= event.relative.x * mouse_sensitivity
		actor.look_direction.y -= event.relative.y * mouse_sensitivity

		if actor.look_direction.x > 360:
			actor.look_direction.x = 0
		elif actor.look_direction.x < 0:
			actor.look_direction.x = 360
		if actor.look_direction.y > max_up_aim_angle:
			actor.look_direction.y = max_up_aim_angle
		elif actor.look_direction.y < -max_down_aim_angle:
			actor.look_direction.y = -max_down_aim_angle

		actor.camera_control.Rotate(actor.look_direction)

	if event.is_action_pressed("move_right"):
		actor.motion_target.x = actor.motion_target.x + 1.0
	elif event.is_action_released("move_right"):
		actor.motion_target.x = actor.motion_target.x - 1.0
	elif event.is_action_pressed("move_left"):
		actor.motion_target.x = actor.motion_target.x - 1.0
	elif event.is_action_released("move_left"):
		actor.motion_target.x = actor.motion_target.x + 1.0
	elif event.is_action_pressed("move_forwards"):
		actor.motion_target.y = actor.motion_target.y + 1.0
	elif event.is_action_released("move_forwards"):
		actor.motion_target.y = actor.motion_target.y - 1.0
	elif event.is_action_pressed("move_backwards"):
		actor.motion_target.y = actor.motion_target.y - 1.0
	elif event.is_action_released("move_backwards"):
		actor.motion_target.y = actor.motion_target.y + 1.0

	if event.is_action_pressed("player_back_in_time"):
		actor.PopRPoint()

	if event.is_action_pressed("use"):
		if not actor.climbing_stairs:
			actor.DoInteractiveObjectCheck()
		else:
			actor.StopStairsClimb()

	if event.is_action("zoom_in") and not Input.is_action_pressed("move_run"):
		actor.camera_control.DecreaseDistance()

	if event.is_action("zoom_out") and not Input.is_action_pressed("move_run"):
		actor.camera_control.IncreaseDistance()

	if event.is_action_pressed("scroll_up") and Input.is_action_pressed("move_run") and actor.animation_speed < 3.0:
		actor.animation_speed += 0.25
	elif event.is_action_pressed("scroll_down") and Input.is_action_pressed("move_run") and actor.animation_speed > 0.5:
		actor.animation_speed -= 0.25
		
	actor.input_direction = (Input.get_action_strength("move_forwards") - Input.get_action_strength("move_backwards"))
	actor.jump = Input.is_action_pressed("jump")
