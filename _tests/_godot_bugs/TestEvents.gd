extends Spatial

func _ready():
	print("Set FPS to low, 3fps")
	Engine.target_fps = 3
	#Input.set_use_accumulated_input(false) #removes the problem

func _process(delta):
	pass

var p = 0
var r = 0
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		$pressed.visible = true
		$released.visible = false
		print("ui_cancel pressed %s" % p)
		p += 1
	if event.is_action_released("ui_cancel"):
		$pressed.visible = false
		$released.visible = true
		print("ui_cancel relased %s" % r)
		r += 1
