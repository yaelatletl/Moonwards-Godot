extends Spatial

export(NodePath) var camera_control_path
onready var camera_control = get_node(camera_control_path)

var look_direction = Vector2()
var mouse_sensitivity = 0.10
var max_up_aim_angle = 55.0
var max_down_aim_angle = 55.0
var root_motion = Transform()
var orientation = Transform()
var velocity = Vector3()

const GRAVITY = Vector3(0,-9.8, 0)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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

func _physics_process(delta):
	root_motion = $KinematicBody/AnimationTree.get_root_motion_transform()
	orientation *= root_motion
	
	var h_velocity = orientation.origin / delta
	velocity.x = h_velocity.x
	velocity.z = h_velocity.z
	velocity += GRAVITY * delta
	velocity = $KinematicBody.move_and_slide(velocity,Vector3(0,1,0))
	
	orientation.origin = Vector3()
	orientation = orientation.orthonormalized()