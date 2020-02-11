extends Area

"""
 For interacting with the player. 
 Use inside the body that you would like it
 to connect to. 
 It emits interacted_with when 
 something interacts with it.
 Emits possible_interaction when the player
 has the potential of interacting with it.
"""



func interact_with( interactor : RayCast ) -> void :
	queue_free()
