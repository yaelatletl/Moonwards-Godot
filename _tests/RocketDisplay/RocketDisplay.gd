extends Spatial

var slide_buttons = []
var current_stage = 1
var max_stages = 4

func _ready():
	$AnimationPlayer.connect("animation_finished", self, "AnimationFinished")
	yield(get_tree(), "idle_frame")
	GoToCurrentStage()

func AnimationFinished(var animation_name):
	#Put the pivot in front of the camera, and reset the camera position.
	var pivot_distance = $Camera.global_transform.origin.distance_to($CameraPivot.global_transform.origin)
	$CameraPivot.global_transform.origin = $Camera.global_transform.origin + (-$Camera.global_transform.basis.z * pivot_distance)
#	$CameraPivot.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	$CameraPivot.rotation_degrees = $Camera.rotation_degrees
	$CameraPivot/CameraPosition.translation = Vector3(0.0, 0.0, pivot_distance)
	$CameraPivot.SetEnabled(true)

func StartNozzleAnimation():
	$Rocket/RocketBody/PYBB_Nozzle_Opt/AnimationPlayer.play("Key.004Action.001")

func StartInletAnimation():
	$Rocket/RocketBody/VariableInlet/AnimationPlayer.play("Key.005Action.001")

func RegisterSlideButton(var button):
	slide_buttons.append(button)

func NextStage():
	if $AnimationPlayer.is_playing():
		return
	if current_stage < max_stages:
		current_stage += 1
		GoToCurrentStage()

func PreviousStage():
	if $AnimationPlayer.is_playing():
		return
	if current_stage > 1:
		current_stage -= 1
		GoToCurrentStage()

func GoToCurrentStage():
	GoToSlide(current_stage)
	$AnimationPlayer.play("Stage" + str(current_stage))

func GoToSlide(var index):
	if $CameraAnimationPlayer.is_playing():
		return
	
	$CameraPivot.SetEnabled(false)
	
	for button in slide_buttons:
		button.SetActive(button.stage != current_stage)
	
	current_stage = index
	
	for button in slide_buttons:
		button.SetActive(button.stage == current_stage)
	
	var target_animation = $CameraAnimationPlayer.get_animation(str(index))
	var target_translation = target_animation.track_get_key_value(target_animation.find_track("Camera:translation"), 0)
	var target_rotation = target_animation.track_get_key_value(target_animation.find_track("Camera:rotation_degrees"), 0)
	var transition_animation = $CameraAnimationPlayer.get_animation("Transition")
	
	transition_animation.track_set_key_value(transition_animation.find_track("Camera:translation"), 0, $Camera.translation)
	transition_animation.track_set_key_value(transition_animation.find_track("Camera:rotation_degrees"), 0, $Camera.rotation_degrees)
	
	transition_animation.track_set_key_value(transition_animation.find_track("Camera:translation"), 1, target_translation)
	transition_animation.track_set_key_value(transition_animation.find_track("Camera:rotation_degrees"), 1, target_rotation)
	
	$CameraAnimationPlayer.play("Transition")