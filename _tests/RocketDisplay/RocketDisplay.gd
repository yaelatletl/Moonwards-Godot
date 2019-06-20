extends Spatial

func _ready():
	pass

func GoToSlide(var index):
	if $AnimationPlayer.is_playing():
		return
	
	var target_animation = $AnimationPlayer.get_animation(index)
	var target_translation = target_animation.track_get_key_value(target_animation.find_track("Camera:translation"), 0)
	var target_rotation = target_animation.track_get_key_value(target_animation.find_track("Camera:rotation_degrees"), 0)
	var transition_animation = $AnimationPlayer.get_animation("Transition")
	
	transition_animation.track_set_key_value(transition_animation.find_track("Camera:translation"), 0, $Camera.translation)
	transition_animation.track_set_key_value(transition_animation.find_track("Camera:rotation_degrees"), 0, $Camera.rotation_degrees)
	
	transition_animation.track_set_key_value(transition_animation.find_track("Camera:translation"), 1, target_translation)
	transition_animation.track_set_key_value(transition_animation.find_track("Camera:rotation_degrees"), 1, target_rotation)
	
	$AnimationPlayer.play("Transition")