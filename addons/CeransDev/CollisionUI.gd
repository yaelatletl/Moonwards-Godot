tool
extends Control

var plugin

signal cs_list
signal cs_make
signal cs_delete
signal cs_save
signal bl_save
signal grp_list
signal lg_scale
signal bl_scale

signal mh_save
signal fx_mat

var collisions
var col
var console
var Editor
var editorplugin
func _ready():
	print("ready")

func LoadScripts():
	collisions = preload("res://addons/CeransDev/MakeCollisionShapes.gd")
	col = collisions.new()

func SetScripts():
	if not Editor:
		Editor = EditorPlugin.new().get_editor_interface()
# 	col.scene = Editor.get_edited_scene_root()
# 	col.editor = Editor
# 	col.editorplugin = editorplugin

func _enter_tree():
	print("_enter_tree")
	var base = "CenterContainer/VSplitContainer2/VSplitContainer/"
	#var Selected = get_node("CenterContainer/VSplitContainer/VBoxContainer/Create")
	#Selected.connect("pressed", self,"create_selected_only")
	var CreateAll = get_node(base+"VBoxContainer/Createall")
	CreateAll.connect("pressed", self,"create_for_all")
	var DeleteSelected = get_node(base+"VBoxContainer2/Delete")
	DeleteSelected.connect("pressed", self, "delete_selected")
	var DeleteAll = get_node(base+"VBoxContainer2/Deleteall")
	DeleteAll.connect("pressed", self, "delete_all")
#	var Test = get_node(base+"VBoxContainer2/Tree")
#	Test.connect("pressed", self, "test_Tree")
	console = $CenterContainer/VSplitContainer2/VBoxContainer/Panel/RichTextLabel

	LoadScripts()
	SetScripts()


func create_selected_only():
	console.text = console.text + "Create!"
	$WindowDialog.popup_centered()
	pass
	
func create_for_all():
	pass
	
func delete_selected():
	pass
	
func delete_all():
	pass
	
func test_Tree():
	print("pressed")
	#var Editor = EditorScript.new()
	#var Scene = Editor.get_scene()
	#var col = collisions.new()
	#col.get_all_meshes(Scene)
	#pass

func _on_Create_pressed():
	print("Create!")
	console = $CenterContainer/VSplitContainer2/VBoxContainer/Panel/RichTextLabel
	console.text = console.text + "Create!"


func _on_Tree_pressed():
#	var Editor = EditorScript.new()
#	var Scene = Editor.get_scene()
	var col = collisions.new()
	var scene = Editor.get_edited_scene_root()
	print(scene.get_children())
	col.ListGroups(scene.get_children())


func _on_Reload_pressed():
	print(Editor)
	LoadScripts()
	SetScripts()

func _on_Run_pressed():
	SetScripts()
	col.Run()


func _on_BL_save_pressed():
	emit_signal("bl_save", self)
	yield(plugin, "end_processing")
	find_node("BL_save").pressed = false
	

func _on_ListGrp_pressed():
	emit_signal("grp_list", self)
	yield(plugin, "end_processing")
	find_node("ListGrp").pressed = false

func _on_CS_list_pressed():
	emit_signal("cs_list", self)
	yield(plugin, "end_processing")
	find_node("CS_list").pressed = false

func _on_CS_make_pressed():
	emit_signal("cs_make", self)
	yield(plugin, "end_processing")
	find_node("CS_make").pressed = false

func _on_CS_delete_pressed():
	emit_signal("cs_delete", self)
	yield(plugin, "end_processing")
	find_node("CS_delete").pressed = false

func _on_CS_save_pressed():
	emit_signal("cs_save", self)
	yield(plugin, "end_processing")
	find_node("CS_save").pressed = false

func _on_LG_scale_pressed():
	emit_signal("lg_scale", self)
	yield(plugin, "end_processing")
# 	find_node("LG_scale").pressed = false


func _on_BL_scale_pressed():
	emit_signal("bl_scale", self)
	yield(plugin, "end_processing")
# 	find_node("BL_scale").pressed = false


func _on_FX_Mat_toggled(button_pressed):
	emit_signal("fx_mat", self)
	yield(plugin, "end_processing")
	find_node("FX_Mat").pressed = false


func _on_MH_Save_toggled(button_pressed):
	emit_signal("mh_save", self)
	yield(plugin, "end_processing")
	find_node("MH_Save").pressed = false
