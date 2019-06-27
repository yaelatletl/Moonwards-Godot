extends Spatial

export (String, MULTILINE)var text
export (NodePath)var control_path
var text_visible = true
var active = false

func _ready():
	$Text/Viewport/InfoBoxContent/Label.text = text