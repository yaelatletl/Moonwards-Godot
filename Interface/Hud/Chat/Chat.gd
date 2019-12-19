extends PanelContainer
"""
	Chat Scene Script
"""

onready var rtl: RichTextLabel = $"V/RichTextLabel"


func _on_LineEdit_text_entered(new_text: String) -> void:
	rpc("_append_text_to_chat", new_text)


remotesync func _append_text_to_chat(new_text: String) -> void:
	# TODO: Add timestap prefix
	# TODO: Add username prefix
	# TODO: Add serverside logging
	rtl.newline()
	rtl.append_bbcode(new_text)
