extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func pick_random():
	var random_pos : Vector3 = Vector3()
	var char_position = get_parent().translation
	random_pos.x = global_character_position.x + rand_range(-3.0,3.0)
	random_pos.y = global_character_position.y + rand_range(-3.0,3.0)
	random_pos.z = global_character_position.z + rand_range(-3.0,3.0)
	bot_update_path(WorldManager.current_world.to_local(random_pos))
	if AI_PATH.size()<1:
		pick_random()
	
	
	
func bot_update_path(to : Vector3) -> void:
	has_destination = false
	AI_PATH = Array(WorldManager.current_world.get_navmesh_path(WorldManager.current_world.to_local(global_character_position), to))
	if AI_PATH.size()>1:
		current_point = AI_PATH[0]
	else:
		current_point = Vector3()
	point_number = 0
	has_destination = true
	
func bot_movement(delta : float) -> void:
	cumulative_delta = cumulative_delta+delta
	if has_destination:
		if (to_local(current_point)-$KinematicBody.translation).length() < 0.5:
			cumulative_delta = 0
			if point_number < AI_PATH.size()-1:
				point_number += 1
				current_point = AI_PATH[point_number]
			else:
				pick_random()
	if cumulative_delta>10:
		cumulative_delta = 0
		if point_number < AI_PATH.size()-1:
			point_number += 1
			current_point = AI_PATH[point_number]
		else:
			pick_random()
# Called when the node enters the scene tree for the first time.
func _ready():
	pick_random()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
