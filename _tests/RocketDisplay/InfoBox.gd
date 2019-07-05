extends Spatial

export (String, MULTILINE)var text
var text_visible = true
var active = false

func _ready():
	$Text/Viewport/InfoBoxContent/Label.text = text
	get_parent().RegisterInfoBox(self)