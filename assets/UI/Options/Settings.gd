extends Tabs
var resolutions : Array = [
	Vector2(460,600),
	Vector2(600,800),
	Vector2(1280, 720),
	Vector2(1366, 768),
	Vector2(1920,1080)
	]

func _ready() -> void:
	var ResolutionPopup = $Main/Row3/Video/Resolution/Resolution.get_popup()
	ResolutionPopup.connect("id_pressed", self, "_on_Resolution_change")
	var DetailPopup = $Main/Row3/Video/ModelQuality/Quality.get_popup()
	DetailPopup.connect("id_pressed", self, "_on_Detail_change")
	$Main/Row1/Updating/UpdateCheck.pressed = options.get("updater/client", "check_at_startup", true)

func _on_Detail_change(id) -> void:
	var DetailPopup = $Main/Row3/Video/ModelQuality/Quality.get_popup()
	var Det = DetailPopup.get_item_text(id)
	$Main/Row3/Video/ModelQuality/Quality.text = Det

func _on_Resolution_change(id) -> void:
	var ResolutionPopup = $Main/Row3/Video/Resolution/Resolution.get_popup()
	var Res = ResolutionPopup.get_item_text(id)
	$Main/Row3/Video/Resolution/Resolution.text = Res
	
func _on_UpdateCheck_pressed() -> void:
	if $Main/Row1/Updating/UpdateCheck.pressed:
		options.set("updater/client", true, "check_at_startup")
	else:
		options.set("updater/client", false, "check_at_startup")



func _on_FPSSpin_value_changed(value):
	pass # Replace with function body.


func _on_FPSSlider_value_changed(value):
	pass # Replace with function body.
