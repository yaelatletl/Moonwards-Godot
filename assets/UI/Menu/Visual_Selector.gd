extends Control

func _on_pants_selected():
	get_node("../../SlotOption").select(0)
func _on_shirt_selected():
	get_node("../../SlotOption").select(1)
func _on_skin_selected():
	get_node("../../SlotOption").select(2)
func _on_hair_selected():
	get_node("../../SlotOption").select(3)