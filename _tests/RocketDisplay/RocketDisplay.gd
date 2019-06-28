extends Spatial

var slide_buttons = []
var current_stage = 1
var max_stages = 5
var return_camera_translation
var return_camera_rotation

func _ready():
	$CameraAnimationPlayer.connect("animation_finished", self, "AnimationFinished")
	$Control.visible = false
#	Activate()

func Activate():
	$CollisionShape/Display.visible = false
	var camera_transform = get_tree().root.get_camera().global_transform
	$Camera.global_transform = camera_transform
	return_camera_translation = $Camera.translation 
	return_camera_rotation = $Camera.rotation_degrees
	UIManager.RequestFocus()
	UIManager.FreeMouse()
	current_stage = 1
	GoToCurrentStage()
	$Camera.current = true
	$Control.visible = true

func DeActivate():
	$CollisionShape/Display.visible = true
	$Camera.current = false
	current_stage = 0
	$Control.visible = false
	UIManager.ReleaseFocus()
	UIManager.LockMouse()

func AnimationFinished(var animation_name):
	if current_stage == 0 or current_stage == max_stages + 1:
		DeActivate()
	else:
		#Put the pivot in front of the camera, and reset the camera position.
		var pivot_distance = $Camera.translation.distance_to(Vector3())
		$CameraPivot.translation = $Camera.translation + (-$Camera.global_transform.basis.z * pivot_distance)
		$CameraPivot.rotation_degrees = $Camera.rotation_degrees
		$CameraPivot/CameraPosition.translation = Vector3(0.0, 0.0, pivot_distance)
		$CameraPivot.SetEnabled(true)

func StartNozzleAnimation():
	$Rocket/RocketBody/PYBB_Nozzle_Opt/AnimationPlayer.play("NozzleOpen")

func StartInletOpenAnimation():
	$Rocket/RocketBody/VariableInlet/AnimationPlayer.play("InletOpen")

func StartInletCloseAnimation():
	$Rocket/RocketBody/VariableInlet/AnimationPlayer.play("InletClose")

func StartBladesAnimation():
	$Rocket/RocketBody/ThrustFanBlades_Opt/AnimationPlayer.play("BladesRotate")

func RegisterSlideButton(var button):
	slide_buttons.append(button)

func NextStage():
	if $AnimationPlayer.is_playing():
		return
	current_stage += 1
	GoToCurrentStage()

func PreviousStage():
	if $AnimationPlayer.is_playing():
		return
	current_stage -= 1
	GoToCurrentStage()

func GoToCurrentStage():
	if current_stage > 0 and current_stage < max_stages + 1:
		if current_stage == 1:
			$Control/VBoxContainer/MainWindow/PreviousButton.text = "Quit"
		else:
			$Control/VBoxContainer/MainWindow/PreviousButton.text = "Previous"
		
		if current_stage == max_stages:
			$Control/VBoxContainer/MainWindow/NextButton.text = "Quit"
		else:
			$Control/VBoxContainer/MainWindow/NextButton.text = "Next"
		
		$AnimationPlayer.play("Stage" + str(current_stage))
	else:
		$AnimationPlayer.play("Stage0")
	
	GoToCameraStage()

func GoToCameraStage():
	
	var to_translation
	var to_rotation
	
	#Quiting to the player.
	if current_stage == 0 or current_stage == max_stages + 1:
		to_translation = return_camera_translation
		to_rotation = return_camera_rotation
	else:
		#Going to the next or previous camera translation.
		var target_animation = $AnimationPlayer.get_animation("Stage" + str(current_stage))
		var translation_idx = target_animation.find_track("Camera:translation")
		to_translation = target_animation.track_get_key_value(translation_idx, 0)
		target_animation.track_set_enabled(translation_idx, false)
		var rotation_idx = target_animation.find_track("Camera:rotation_degrees")
		target_animation.track_set_enabled(rotation_idx, false)
		to_rotation = target_animation.track_get_key_value(rotation_idx, 0)
	
	$CameraPivot.SetEnabled(false)
	
	for button in slide_buttons:
		button.SetActive(button.stage != current_stage)
	
	StartCameraAnimation(to_translation, to_rotation)

func StartCameraAnimation(var to_translation, var to_rotation):
	for button in slide_buttons:
		button.SetActive(button.stage == current_stage)
	
	var transition_animation = $CameraAnimationPlayer.get_animation("Transition")
	
	transition_animation.track_set_key_value(transition_animation.find_track("Camera:translation"), 0, $Camera.translation)
	transition_animation.track_set_key_value(transition_animation.find_track("Camera:rotation_degrees"), 0, $Camera.rotation_degrees)
	
	transition_animation.track_set_key_value(transition_animation.find_track("Camera:translation"), 1, to_translation)
	transition_animation.track_set_key_value(transition_animation.find_track("Camera:rotation_degrees"), 1, to_rotation)
	
	$CameraAnimationPlayer.play("Transition")
	
	