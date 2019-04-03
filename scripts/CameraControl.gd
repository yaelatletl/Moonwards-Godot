extends Spatial

export (NodePath)var kinematic_body_path
export (float, 0, 500) var speed = 10
onready var kinematic_body = get_node(kinematic_body_path)
onready var pivot = $Pivot
onready var camera_target = $Pivot/CameraTarget
onready var look_target = $Pivot/LookTarget
onready var camera = $Camera
var current_look_position = Vector3()
var zoom_step_size = 0.05

func _ready():
	yield(get_tree(), "idle_frame")
	remove_child(camera)
	get_parent().get_parent().add_child(camera)

func _input(event):
	if event.is_action("scroll_up"):
		if camera_target.translation.z > 0.15:
			camera_target.translation.z -= zoom_step_size
	if event.is_action("scroll_down"):
		if camera_target.translation.z < 1.0:
			camera_target.translation.z += zoom_step_size

func _physics_process(delta):
	var from = pivot.global_transform.origin
	var to = camera_target.global_transform.origin
	var local_to = camera_target.translation
	
	var col = get_world().direct_space_state.intersect_ray(from, to, [kinematic_body])
	DrawLine(from, to)
	
	var target_position = to
	if not col.empty():
		var raycast_offset = col.position.distance_to(from)
		if local_to.z > raycast_offset:
			target_position = pivot.to_global(Vector3(0, 0, max(0.15, raycast_offset - 0.15)))
	
	camera.global_transform.origin = camera.global_transform.origin.linear_interpolate(target_position, delta * speed)
	
	var new_look_position = look_target.global_transform.origin
	current_look_position = current_look_position.linear_interpolate(new_look_position, delta * speed)
	camera.look_at(current_look_position, Vector3(0,1,0))

func Rotate(var direction):
	pivot.rotation_degrees = Vector3(direction.y, direction.x, 0)

func DrawLine(var from, var to):
	var im = $Lines
	im.clear()
	im.begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	var origin = im.global_transform.origin
	
	im.add_vertex(from - origin)
	im.add_vertex(to - origin)
	
	im.end()

