extends PanelContainer
"""
	Chat Scene Script
"""

onready var _rtl: RichTextLabel = $"V/RichTextLabel"
onready var _le: LineEdit = $"V/LineEdit"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.scancode == KEY_ENTER:
			_le.grab_focus()


func _on_LineEdit_text_entered(new_text: String) -> void:
	rpc("_append_text_to_chat", new_text)
	_le.release_focus()


remotesync func _append_text_to_chat(new_text: String) -> void:
	# TODO: Add timestap prefix
	# TODO: Add username prefix
	# TODO: Add serverside logging
	_rtl.newline()
	_rtl.append_bbcode(new_text)
