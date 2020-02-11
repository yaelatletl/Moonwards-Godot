extends Area

"""
 For interacting with the player. 
 Use inside the body that you would like it
 to connect to. 
 I emit interacted_with when an interactor interacts with me. 
	Passes the node that requested the interact in the signal.

"""

signal interacted_with( interactor_ray_cast )


func interact_with( interactor : Node ) -> void :
	#Someone requested interaction with me.
	emit_signal( "interacted_with", interactor )
