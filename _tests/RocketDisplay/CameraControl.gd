extends Spatial

export (float) var max_zoom_distance = 20.0
export (float) var min_zoom_distance = 2.5
export (float) var zoom_step_size = 0.5
export (float, 0, 500) var speed = 5
var enabled = false
export (NodePath) var camera_path
onready var camera = get_node(camera_path)
var current_look_position = Vector3()
var look_direction = Vector2()
var mouse_sensitivity = 0.2
var max_up_aim_angle = 55.0
var max_down_aim_angle = 55.0
var mouse_down = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	if not enabled:
		return
	var target_position = $CameraPosition.global_transform.origin
	camera.global_transform.origin = camera.global_transform.origin.linear_interpolate(target_position, delta * speed)
	
	var new_look_position = global_transform.origin
	current_look_position = current_look_position.linear_interpolate(new_look_position, delta * speed)
	camera.look_at(current_look_position, Vector3(0,1,0))

func SetEnabled(var _enabled):
	if _enabled:
		current_look_position = global_transform.origin
		look_direction.y = rotation_degrees.x
		look_direction.x = rotation_degrees.y
		
	enabled = _enabled

func _input(event):
	if not enabled:
		return
	if event.is_action("scroll_down"):
		IncreaseDistance()
	if event.is_action("scroll_up"):
		DecreaseDistance()
	
	if Input.is_action_pressed("left_click"):
		mouse_down = true
	else:
		mouse_down = false
	
	if mouse_down and event is InputEventMouseMotion:
		look_direction.x -= event.relative.x * mouse_sensitivity
		look_direction.y -= event.relative.y * mouse_sensitivity
		
		if look_direction.x > 360:
			look_direction.x = 0
		elif look_direction.x < -180:
			look_direction.x = 180
		if look_direction.y > max_up_aim_angle:
			look_direction.y = max_up_aim_angle
		elif look_direction.y < -max_down_aim_angle:
			look_direction.y = -max_down_aim_angle
		
		rotation_degrees = Vector3(look_direction.y, look_direction.x, 0)

func IncreaseDistance():
	if not enabled:
		return
	if $CameraPosition.translation.z < max_zoom_distance:
		$CameraPosition.translation.z += zoom_step_size

func DecreaseDistance():
	if not enabled:
		return
	if $CameraPosition.translation.z > min_zoom_distance:
		$CameraPosition.translation.z -= zoom_step_size