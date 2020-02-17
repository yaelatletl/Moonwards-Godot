extends "res://assets/Interactable/Interactable.gd"


export var audio_file : AudioStreamOGGVorbis = AudioStreamOGGVorbis.new()


func _ready() -> void :
	audio_file.loop = false
	$Audio.stream = audio_file


#warning-ignore:unused_argument
func play_sound(interactor_ray_cast):
	#Player requested audio. Play the audio.
	$Audio.play()
