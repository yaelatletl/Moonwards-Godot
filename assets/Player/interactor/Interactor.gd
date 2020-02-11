extends RayCast

"""
	Casts to the direction the player is looking.
	When within a given range of an interactable,
	the player will be told of the opportunity to
	interact with the object.
"""


onready var main_camera : Camera = get_tree().get_root().get_camera()
onready var parent : Spatial = get_parent()

func _process( delta : float ) -> void :
	var new_rotate : Vector3 = main_camera.rotation
#	new_rotate.x = -new_rotate.x
	rotation = new_rotate
#	rotation += parent.rotation

#warning-ignore:unused_argument
func _physics_process(delta : float ) -> void:
	#Determine when I have touched an interactable.
	force_raycast_update()

	#Exit if I am not touching anything
	if not is_colliding() :
		return
	
	var collider : Object = get_collider()
	if Input.is_key_pressed( KEY_E ) :
		#Interact with the collider.
		collider.interact_with( self )
	
	
	
	
