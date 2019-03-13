extends Camera

func _ready():
	look_direction = rotation_degrees

var look_direction = Vector3()
var max_up_aim_angle = 80.0
var max_down_aim_angle = 80.0
var mouse_sensitivity = 0.10
var velocity = Vector3()
var look_velocity = Vector3()
var mouse_down = false

var velocity_damp = 0.95
var acceleration = 0.2

func _process(delta):
	var forward_direction = global_transform.basis.z
	var right_direction = global_transform.basis.x
	global_transform.origin += velocity
	
	velocity = velocity * velocity_damp
	look_velocity = look_velocity * velocity_damp
	
	rotation_degrees += look_velocity
	
	if rotation_degrees.x > max_up_aim_angle:
		rotation_degrees.x = max_up_aim_angle
	elif rotation_degrees.x < -max_down_aim_angle:
		rotation_degrees.x = -max_down_aim_angle
	
	if Input.is_action_pressed("left_click"):
		mouse_down = true
	else:
		mouse_down = false
	
	if Input.is_action_pressed("move_forwards"):
		if Input.is_action_pressed("shift"):
			velocity -= Vector3(0, -1, 0) * delta * acceleration
		else:
			velocity -= forward_direction * delta * acceleration
	
	if Input.is_action_pressed("move_backwards"):
		if Input.is_action_pressed("shift"):
			velocity += Vector3(0, -1, 0) * delta * acceleration
		else:
			velocity += forward_direction * delta * acceleration
	
	if Input.is_action_pressed("move_left"):
		velocity -= right_direction * delta * acceleration
	
	if Input.is_action_pressed("move_right"):
		velocity += right_direction * delta * acceleration
	
	if Input.is_action_pressed("spacebar"):
		velocity *= 1.05

func _input(event):
	if event is InputEventMouseMotion:
		if mouse_down:
			look_velocity.y -= event.relative.x * mouse_sensitivity * acceleration
			look_velocity.x -= event.relative.y * mouse_sensitivity * acceleration
		