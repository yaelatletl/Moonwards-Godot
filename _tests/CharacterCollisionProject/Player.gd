extends Spatial

var MOTION_INTERPOLATE_SPEED = 5
var ROTATION_INTERPOLATE_SPEED = 10
var IN_AIR_DELTA = 0.3
var GRAVITY = Vector3(0,-9.81, 0)
var SNAP_VECTOR = Vector3(0.0, 0.1, 0.0)
var JUMP_SPEED = 2.8
var SPEED_SCALE = 2 #use as 0.1*SPEED_SCALE for time being because of slider for speed setting is int, in Options.gd

var motion = Vector3()
var look_direction = Vector2()
var ground_normal = Vector3(0.0, -1.0, 0.0)
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
var flies = false
var movementstate = walk

const walk = 0
const flail = 1

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

func Jump():
	jumping = false
	velocity.y += JUMP_SPEED

func _physics_process(delta):
	HandleControls(delta)

func HandleControls(var delta):
	#Update the model rotation based on the camera look direction.
	var forward_direction = -$KinematicBody/Camera.global_transform.basis.z
	var right_direction = $KinematicBody/Camera.global_transform.basis.x
	
	var motion_target = (Input.get_action_strength("move_right") * right_direction) + (Input.get_action_strength("move_left") * -right_direction) + \
						(Input.get_action_strength("move_forwards") * forward_direction) + (Input.get_action_strength("move_backwards") * -forward_direction)
	motion_target *= 15.0
	motion = motion.linear_interpolate(motion_target, MOTION_INTERPOLATE_SPEED * delta)
	motion.y = 0.0
	velocity += motion * delta
	
	velocity += GRAVITY * delta
	
	if Input.is_action_just_pressed("jump"):
		velocity += Vector3(0.0, 300.0, 0.0) * delta
	
	velocity = $KinematicBody.move_and_slide(velocity, Vector3(0,1,0), true)
	velocity.x *= 0.9
	velocity.z *= 0.9
	if $KinematicBody/RayCast.is_colliding():
		$KinematicBody/Label/Viewport/Label.text = "on floor true"
	else:
		$KinematicBody/Label/Viewport/Label.text = "on floor false"

func CreateDebugLine(var from, var to):
	$KinematicBody/ImmediateGeometry.clear()
	$KinematicBody/ImmediateGeometry.begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	$KinematicBody/ImmediateGeometry.add_vertex(from)
	$KinematicBody/ImmediateGeometry.add_vertex(to)
	$KinematicBody/ImmediateGeometry.end()

