extends Spatial
var actor

func _ready():
	actor = get_parent()

func _unhandled_input(event):
	if event.is_action_pressed("use"):
		if not actor.climbing_stairs:
			interactive_object_check()
		else:
			actor.stop_stairs_climb()
			

func interactive_object_check():
	var space_state = get_world().direct_space_state
	var params = PhysicsShapeQueryParameters.new()
	var sphere = SphereShape.new()
	var kb_pos = actor.global_transform.origin

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
		if closest_object is Stairs:
			actor.climbing_stairs = true
			actor.climb_look_direction = closest_object.GetLookDirection(kb_pos)
			#Get the closest step to start climbing from.
			for index in closest_object.climb_points.size():
				if actor.climb_point == -1 or closest_object.climb_points[index].distance_to(kb_pos) < closest_object.climb_points[actor.climb_point].distance_to(kb_pos):
					actor.climb_point = index
		elif closest_object.has_method("activate"):
			closest_object.activate()
