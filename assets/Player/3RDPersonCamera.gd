extends KinematicBody

# class member variables go here, for example:
var linear_velocity = Vector3()
var gravity = Vector3(0,1,0)
export(NodePath) var Target 
export(float) var camera_speed = 1.2
#var originalpos = Vector3()
export(NodePath) var origin 
#var cameramovement
func _enter_tree():
	#cameramovement = get_node("../..").fixpos
	origin = get_node(origin).translation
	Target = get_node(Target).translation
func _process(delta):
	linear_velocity = (origin - translation)
	#move_and_slide(linear_velocity,-gravity.normalized())
	
	
	translation.x = clamp(translation.x, Target.x-0.5, Target.x+0.5)
	translation.y = clamp(translation.y, Target.y-0.5, Target.y+0.5)
	translation.z = clamp(translation.z, Target.z-0.5, Target.z+0.5)
	
	
	
	if translation.length() > origin.length()+0.001: # and not (is_on_floor() or is_on_ceiling() or is_on_wall()):
		
		move_and_slide(linear_velocity,-gravity.normalized())
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
		move_and_slide(Vector3(), -gravity.normalized())
	
