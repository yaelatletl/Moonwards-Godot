extends ScrollContainer

func _ready() -> void:
	get_tree().get_root().connect("size_changed",self,"_on_resize")
	
func _on_resize() -> void:
	var oldsize : Vector2 = Vector2(1024, 700)
	var newsize : Vector2 = get_tree().get_root().get_visible_rect().size
	var scale : float = newsize.y/oldsize.y
	rect_scale = Vector2(1,1)*scale
