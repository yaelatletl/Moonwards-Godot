extends RayCast

"""
	Casts to the direction the player is looking.
	When within a given range of an interactable,
	the player will be told of the opportunity to
	interact with the object.
"""

#This is what I pass as the interactor.
export var user : NodePath = get_path()

onready var main_camera : Camera = get_tree().get_root().get_camera()


func _ready():
	#Ensure that the RayCast is being cast properly.
	#If this fails, make sure that only the z action is non zero and
	#that the z axis is negative.
	assert( cast_to.x == 0 && cast_to.y == 0 && cast_to.z < 0 )

#warning-ignore:unused_argument
func _process( delta : float ) -> void :
	#Make the interactor point at the center of the screen.
	#This assumes that the interactor is a child of the player KinematicBody.
	#TODO: Decouple this from needing to be in the player and make it capable of being a part of anything.
	rotation = main_camera.rotation

#warning-ignore:unused_argument
func _physics_process(delta : float ) -> void:
	#Determine when I have touched an interactable.

	#Exit if I am not touching anything
	if not is_colliding() :
		return
	
	#Get the interactable I am colliding with.
	#TODO: Return the interactable's name and display it and notify listener's of it.
	var collider : Object = get_collider()
	if Input.is_action_just_pressed( "use" ) :
		#Player wants to interact with the collider.
		collider.interact_with( get_node( user ) )
	
	
	
	
