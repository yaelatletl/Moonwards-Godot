extends Tabs
var resolutions : Array = [
	Vector2(460,600),
	Vector2(600,800),
	Vector2(1280, 720),
	Vector2(1366, 768),
	Vector2(1920,1080)
	]

onready var Quality : MenuButton = $Main/Row3/Video/ModelQuality/Quality
onready var Resolution : MenuButton = $Main/Row3/Video/Resolution/Resolution
onready var UpdateCheck : CheckBox = $Main/Row1/Updating/UpdateCheck
onready var FPSSlider : HSlider = $Main/Row3/Video/FPSLimit/FPSSlider
onready var FPSSpin : SpinBox = $Main/Row3/Video/FPSLimit/FPSSpin

func _ready() -> void:
	Resolution.get_popup().connect("id_pressed", self, "_on_Resolution_change")
	Quality.get_popup().connect("id_pressed", self, "_on_Detail_change")
	UpdateCheck.pressed = options.get("updater/client", "check_at_startup", true)

func _on_Detail_change(id : int) -> void:
	Quality.text = Quality.get_popup().get_item_text(id)

func _on_Resolution_change(id : int) -> void:
	Resolution.text = Resolution.get_popup().get_item_text(id)
	
func _on_UpdateCheck_pressed() -> void:
	if UpdateCheck.pressed:
		options.set("updater/client", true, "check_at_startup")
	else:
		options.set("updater/client", false, "check_at_startup")



func _on_FPSSpin_value_changed(value):
	FPSSlider.value = value


func _on_FPSSlider_value_changed(value):
	FPSSpin.value = value
