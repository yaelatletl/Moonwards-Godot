extends Control

signal disable_movement()
var chat_visible = true
var show_duration = 5.0
var timer = show_duration

func _ready():
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

func _process(delta):
	if chat_visible and not $VBoxContainer/ChatInput.has_focus():
		timer -= delta
		if timer <= 0.0:
			$AnimationPlayer.play("FadeOut")
			$VBoxContainer/ChatInput.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chat_visible = false

func _player_connected(id):
	AddMessage(gamestate.players[id] + ' has joined')

func _player_disconnected(id):
	AddMessage(gamestate.players[id] + ' has left')

func _connected_ok():
	AddMessage('You have joined the room')
	rpc('announce_user', gamestate.username)

sync func display_message(player, new_text):
	AddMessage(player + ' : ' + new_text)
	
remote func announce_user(player):
	AddMessage(player + ' has joined the room')

func _input(event):
	if event.is_action_pressed("toggle_chat"):
		ShowChat()
		if not $VBoxContainer/ChatInput.has_focus():
			$VBoxContainer/ChatInput.grab_focus()
		else:
			if not $VBoxContainer/ChatInput.text == "":
				rpc('display_message', gamestate.username, $VBoxContainer/ChatInput.text)
			$VBoxContainer/ChatInput.release_focus()
			$VBoxContainer/ChatInput.clear()

func ShowChat():
	if not chat_visible:
		$AnimationPlayer.play("FadeIn")
	$VBoxContainer/ChatInput.mouse_filter = Control.MOUSE_FILTER_STOP
	timer = show_duration
	chat_visible = true

func AddMessage(var message):
	$VBoxContainer/Log.add_text(message)
	$VBoxContainer/Log.newline()
	ShowChat()