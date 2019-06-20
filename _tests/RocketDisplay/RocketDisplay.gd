extends Spatial

var info_boxes = []
var slide_buttons = []
var current_slide = ""

func _ready():
	yield(get_tree(), "idle_frame")
	GoToSlide("1")

func RegisterInfoBox(var box):
	info_boxes.append(box)

func RegisterSlideButton(var button):
	slide_buttons.append(button)

func GoToSlide(var index):
	if $AnimationPlayer.is_playing() or index == current_slide:
		return
	
	current_slide = index
	
	for box in info_boxes:
		if box.show_text:
			box.ToggleVisible()
	
	for button in slide_buttons:
		button.SetActive(button.slide_id == current_slide)
	
	var target_animation = $AnimationPlayer.get_animation(index)
	var target_translation = target_animation.track_get_key_value(target_animation.find_track("Camera:translation"), 0)
	var target_rotation = target_animation.track_get_key_value(target_animation.find_track("Camera:rotation_degrees"), 0)
	var transition_animation = $AnimationPlayer.get_animation("Transition")
	
	transition_animation.track_set_key_value(transition_animation.find_track("Camera:translation"), 0, $Camera.translation)
	transition_animation.track_set_key_value(transition_animation.find_track("Camera:rotation_degrees"), 0, $Camera.rotation_degrees)
	
	transition_animation.track_set_key_value(transition_animation.find_track("Camera:translation"), 1, target_translation)
	transition_animation.track_set_key_value(transition_animation.find_track("Camera:rotation_degrees"), 1, target_rotation)
	
	$AnimationPlayer.play("Transition")