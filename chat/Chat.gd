extends Control

var player_id
var username = ''
signal disable_movement()
func _ready():
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	player_id = str(get_tree().get_network_unique_id())

func _player_connected(id):
	$Display.text += '\n ' + username + ' has joined' #Change str(id) for the username

func _player_disconnected(id):
	$Display.text += '\n ' + username + ' has left' #Change str(id) for the username

func _connected_ok():
	$Display.text += '\n You have joined the room'
	rpc('announce_user', username)  #Change player_id for username

func _on_Message_Input_text_entered(new_text):
	$Message_Input.text = ''
	if not new_text == '':
		rpc('display_message', self.username, new_text)



sync func display_message(player, new_text):
	$Display.text += '\n ' + player + ' : ' + new_text

remote func announce_user(player):
	$Display.text += '\n ' + player + ' has joined the room'

func _unhandled_input(event):
	if event is InputEventKey and is_network_master():
		if event.pressed and event.scancode == KEY_ENTER:
			if not $Message_Input.has_focus():
				$Message_Input.grab_focus()
				emit_signal("disable_movement")
			else:
				emit_signal("disable_movement")
				$Message_Input.release_focus()



