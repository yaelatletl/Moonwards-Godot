extends KinematicBody

# class member variables go here, for example:
var linear_velocity = Vector3()
var gravity = Vector3(0,1,0)
export(float) var camera_speed = 1.2
export(float) var margin  = 0.05 
#var originalpos = Vector3()
export(NodePath) var Origin 
export(NodePath) var Target 
var target
var origin
var ready : bool = false

#var cameramovement
#func _enter_tree():
#	#cameramovement = get_node("../..").fixpos
#	origin = get_node(Origin).translation
#	target = get_node(Target).translation

	
func _ready():
	ready = true
	origin = to_local(get_node(Origin).get_global_transform()[3])
	rotation_degrees = get_node(Origin).rotation_degrees
	target = to_local(get_node(Target).get_global_transform()[3])
	
func _process(delta):
	
	#move_and_slide(linear_velocity,-gravity.normalized())
	if ready: 
		
		#translation.x = clamp(translation.x, target.x-margin, target.x+margin)
		#translation.y = clamp(translation.y, target.y-margin, target.y+margin)
		#translation.z = clamp(translation.z, target.z-margin, target.z+margin)
	
	
	
		if (origin-translation).length() > 0.1  and not (is_on_floor() or is_on_ceiling() or is_on_wall()):
			#print(get_global_transform()[3])
			#print(origin)
			#print(target)
			#linear_velocity = (origin - translation).normalized()*0.01
			#linear_velocity = move_and_slide(linear_velocity,gravity.normalized())
			set_global_transform(get_node(Origin).get_global_transform())
			#if translation.x <= origin.x-0.2:
	#		translation.x = translation.x + delta
	#	if translation.x >= -origin.x+0.2:
	#		translation.x = translation.x - delta
	#		
	#	if translation.y <= origin.y-0.2:
	#		translation.y = translation.y + delta
	#	if translation.y >= origin.y+0.2:
	#		translation.y = translation.y - delta
	#		
	#	if translation.z <= origin.y-0.2:
	#		translation.z = translation.z + delta
	#	if translation.z >= origin.y+0.2:
	#		translation.z = translation.z - delta	
		else:
			linear_velocity = move_and_slide(linear_velocity, gravity.normalized())
	
