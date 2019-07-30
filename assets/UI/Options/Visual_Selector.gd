extends Control
export(NodePath) var SlotOptionPath = "../../../VBoxContainer/SlotOption"

func _ready():
	get_node(SlotOptionPath).emit_signal("item_selected",0)
func _on_pants_selected():
	get_node(SlotOptionPath).select(0)
	get_node(SlotOptionPath).emit_signal("item_selected",0)
func _on_shirt_selected():
	get_node(SlotOptionPath).select(1)
	get_node(SlotOptionPath).emit_signal("item_selected",1)
func _on_skin_selected():
	get_node(SlotOptionPath).select(2)
	get_node(SlotOptionPath).emit_signal("item_selected",2)
func _on_hair_selected():
	get_node(SlotOptionPath).select(3)
	get_node(SlotOptionPath).emit_signal("item_selected",3)
func _on_shoes_selected():
	get_node(SlotOptionPath).select(4)
	get_node(SlotOptionPath).emit_signal("item_selected",4)