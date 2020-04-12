extends Node


var AI_PATH : Array = []
var has_destination : bool  = false
var global_character_position : Vector3 = Vector3()

var point_number : int = 0
var cumulative_delta : float = 0.0

var actor : KinematicBody

func _ready():
	actor = get_parent()
	pick_random()


func _physics_process(delta):
	if actor.is_bot and not actor.is_puppet:
		if actor.current_point.length()<0.01:
			actor.motion_target = Vector2(0,0)
		else:
			actor.motion_target = Vector2(0,1)
		actor.camera_control.look_at((actor.current_point), Vector3(0,1,0))

func pick_random():
	var random_pos : Vector3 = Vector3()
	global_character_position = get_parent().get_parent().to_global(get_parent().translation)
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
		actor.current_point = AI_PATH[0]
	else:
		actor.current_point = Vector3()
	point_number = 0
	has_destination = true
	
func bot_movement(delta : float) -> void:
	cumulative_delta = cumulative_delta+delta
	if has_destination:
		if (get_parent().get_parent().to_local(actor.current_point)-get_parent().translation).length() < 0.5:
			cumulative_delta = 0
			if point_number < AI_PATH.size()-1:
				point_number += 1
				actor.current_point = AI_PATH[point_number]
			else:
				pick_random()
	if cumulative_delta>10:
		cumulative_delta = 0
		if point_number < AI_PATH.size()-1:
			point_number += 1
			actor.current_point = AI_PATH[point_number]
		else:
			pick_random()
			
# Called when the node enters the scene tree for the first time.
