tool
extends Panel
signal color_changed(color)

export(Color) var color : Color setget color_changed 
export(bool) var flat : bool  setget flat_changed

var isReady : bool = false


func _ready() -> void:
	if color == null:
		print ("PP:  reset color")
		color = ColorN('white')
	isReady = true
#	print ("Readying up PickerPanel.....")

	yield(get_tree(),'idle_frame')
	yield(get_tree(),'idle_frame')
	var sliders = $ClassicControls/Hider/Viewport/ColorPicker

	set_meta("_editor_icon", preload("res://addons/HuePicker/icon_picker_panel.svg"))

#	$HuePicker.color = color
#	sliders.color = color
	color_changed(color)

	$HuePicker.connect("color_changed", self, "_on_huePickChange")
	sliders.connect("color_changed", 	self, "_on_sliderChange")


func color_changed(value : Color, suppressSignal : bool = false) -> void:
#	if not isReady or value == null:
#		print("PickerPanel: Warning, attempting to change color before control is ready")		
#		print(color)
#		return

	if value != null:  isReady = true

	var sliders = $ClassicControls/Hider/Viewport/ColorPicker
	color = value
	
	if suppressSignal:  return
	
	if sliders !=null and $HuePicker != null:
		_on_sliderChange(value)
		_on_huePickChange(value)
		sliders.update_shaders()
	
	emit_signal('color_changed', value)

func flat_changed(value : bool) -> void:
	if has_stylebox_override("panel"):
		if not get("custom_styles/panel") is StyleBoxEmpty:
			print ("StyleBox 'panel' is overridden. Can't set flat.")
			return
	
	if value == true:
		add_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		set("custom_styles/panel", null)

	flat = value

func _on_huePickChange(color : Color) -> void:
#	print ("hpc", color)
	if not isReady or color == null:	return
	var sliders = $ClassicControls/Hider/Viewport/ColorPicker
	sliders.color = color
	sliders.update_shaders()

	color_changed(color,true)

func _on_sliderChange(color : Color) -> void:
#	print("slc", color)
	if not isReady or color == null:	return
#	$HuePicker._on_HuePicker_color_changed(color)
	$HuePicker.color = color

	#Prevent from accidentally resetting the internal hue if color's out of range
	var c = Color(color.r, color.g, color.b, 1)
	if c != ColorN('black', 1) and c != ColorN('white', 1) and c.s !=0:
		$HuePicker/"Hue Circle"._sethue(color.h, self)
		$HuePicker._on_HuePicker_color_changed(color)
		
	color_changed(color, true)
	
	

