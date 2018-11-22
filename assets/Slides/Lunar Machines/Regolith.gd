extends Spatial

func _ready():
	pass

func _process(delta):
	
	if not $AnimationPlayer.is_playing():
		$AnimationPlayer.play("default")
