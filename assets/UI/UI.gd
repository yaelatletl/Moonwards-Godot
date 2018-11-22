extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	$WelcomeText/AnimationPlayer.play("Hello")
	
func _unhandled_key_input(event):
	if Input.is_action_pressed("ui_cancel"):
		$Menu.popup_centered()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
