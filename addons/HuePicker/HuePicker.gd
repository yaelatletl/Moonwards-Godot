tool
extends Control

export(Color) var color setget color_changed
signal color_changed(color)
signal Hue_Selected(color)
var isReady = false


func _ready():
#	print ("Setting up HuePicker.. %s" % color)
	if color == null:
		color = ColorN('white')
	isReady = true
	

	yield(get_tree(),'idle_frame')
	$Hue_Circle._sethue(color.h)
	$Hue_Circle.reposition_hue_indicator()
	reposition_hue_indicator()
	_on_HuePicker_color_changed(color)

	set_meta("_editor_icon", preload("res://addons/HuePicker/icon.png"))

func color_changed(value):
	color = value
	
	#TODO: This line is so we know to update the hue spinner if a property
	#is set from within the Godot editor. Will cause problems for downstream
	#Plugins, so try to figure out a way to determine that we're SPECIFICALLY
	#editing this property from the Inspector, somehow.  Hack!!!
	if Engine.editor_hint == true and $Hue_Circle != null: 
		$Hue_Circle._sethue(value.h)
	
	emit_signal('color_changed', value)

func _on_HuePicker_resized():
	var short_edge = min(rect_size.x, rect_size.y)
	var chunk = Vector2(short_edge,short_edge)
	var indicator = $Hue_Circle/indicator_rgba
	indicator.rect_size = chunk / 8
	$Hue_Circle/indicator_rgba/bg.position = chunk / 16
	$Hue_Circle/indicator_rgba/bg.scale = chunk / 256
	indicator.rect_position.x = rect_size.x/2 - short_edge/2
	indicator.rect_position.y = rect_size.y/2 + short_edge/2 - indicator.rect_size.y
	
	
	reposition_hue_indicator()
	
func reposition_hue_indicator():
	var hc   = $Hue_Circle
	var i    = $Hue_Circle/indicator_h
	var midR = min(hc.rect_size.x, hc.rect_size.y) * 0.45
	var ihx  = midR*cos(hc.saved_h * 2*PI) + hc.rect_size.x/2 - i.rect_size.x/2
	var ihy  = midR*sin(hc.saved_h * 2*PI) + hc.rect_size.y/2 - i.rect_size.y/2

	hc.reposition_hue_indicator()

	$Hue_Circle/indicator_h.set_rotation($Hue_Circle.saved_h * 2*PI + PI/2)
	i.rect_position = Vector2(ihx,ihy)

#Color change handler.
func _on_HuePicker_color_changed(color):
	if isReady == false or color == null:  
		print("HuePicker:  Warning, attempting to change color before control is ready")
		return  0

	$Hue_Circle/indicator_rgba/ColorRect.color = color
	$Hue_Circle/ColorRect/SatVal.material.set_shader_param("hue", $Hue_Circle.saved_h)
	reposition_hue_indicator()
	#Reposition SatVal indicator
	$Hue_Circle/ColorRect/indicator_sv.position = Vector2(color.s, 1-color.v) * $"Hue_Circle/ColorRect".rect_size
	emit_signal("Hue_Selected", color)

#For the Popup color picker.
func _on_ColorPicker_color_changed(color):
	#	#Prevent from accidentally resetting the internal hue if color's out of range
	var c = Color(color.r, color.g, color.b, 1)
	if c != ColorN('black', 1) and c != ColorN('white', 1) and c.s !=0:
		$Hue_Circle._sethue(self.color.h)

	self.color = color
	$Hue_Circle.reposition_hue_indicator()
