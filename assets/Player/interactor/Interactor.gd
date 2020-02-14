extends RayCast

"""
	Casts to the direction the player is looking.
	When within a given range of an interactable,
	the player will be told of the opportunity to
	interact with the object.
	
	Please note: Anything marked with the comment TEMPCAMERA is meant to 
	be replaced in the future when player agnostic controls is set.
"""

#This is what I pass as the interactor.
export var user : NodePath = get_path()

signal interact_possible( string_describing_potential_interact )

#This is show I will not spam a signal when I have potential interacts.
var previous_collider : Area = null

#This is the camera that is currently in use.
#TEMPCAMERA
var main_camera : Camera


func _ready():
	#Ensure that the RayCast is being cast properly.
	#If this assert fails, make sure that only the z action is non zero and
	#that the z axis is also negative.
	assert( cast_to.x == 0 && cast_to.y == 0 && cast_to.z < 0 )
	
	#The player camera is not set until after ready is done.
	#So I use call_deferred to get the correct camera.
	#TEMPCAMERA
	call_deferred( "set_camera" )

#warning-ignore:unused_argument
func _process( delta : float ) -> void :
	#Make the interactor point at the center of the screen.
	#This assumes that the interactor is a child of the player KinematicBody.
	
	#TODO: Decouple this from needing to be in the player and make it capable of being a part of anything.
	#The game camera gets loaded at a random time apparantly.
	#TEMPCAMERA
	rotation = main_camera.rotation

#warning-ignore:unused_argument
func _physics_process(delta : float ) -> void:
	#Determine when I have touched an interactable.

	#Exit if I am not touching anything. Reset previous collider.
	if not is_colliding() :
		previous_collider = null
		return
	
	#Get the interactable I am colliding with.
	var collider : Area = get_collider()
	
	#Return the interactable's name and notify listener's of it.
	if previous_collider != collider :
		emit_signal( "interact_possible", collider.get_info() )
		previous_collider = collider
	
	#Interact with the interactable if I am told to.
	#TODO: This assumes I am a part of the player. Make this implementation agnostic.
	if Input.is_action_just_pressed( "use" ) :
		#Player wants to interact with the collider.
		collider.interact_with( get_node( user ) )

#TEMPCAMERA
func set_camera() -> void :
	#This method only exists as a workaround to not being able to get the 
	#player camera during ready.
	main_camera = get_tree().get_root().get_camera()
