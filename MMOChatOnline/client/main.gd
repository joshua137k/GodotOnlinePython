extends Node2D

#NetworkNode
const NetworkClient = preload("res://websocket_client.gd")


#Nodes
@onready var _network_client = NetworkClient.new()
@onready var username_textbox: LineEdit = get_node("login/VBoxContainer/username")
@onready var password_textbox: LineEdit = get_node("login/VBoxContainer/senha")
@onready var player=preload("res://player.tscn")
@onready var peer=preload("res://peer.tscn")

#Var
var player_id = -1
var username= "UNK"
var players = {}
var MyPlayer

func _ready():
	_network_client.connect("connected", _handle_client_connected)
	_network_client.connect("data", _handle_network_data)
	add_child(_network_client)
	_network_client.connect_to_server("localhost", 9000)


#NewPeer
func newplayer(id,username):
	var new=peer.instantiate()
	new.get_node("Label").text=username
	players[id] = new
	send_player_position(new.position.x, new.position.y)
	call_deferred("add_child",new)


#Client Conectou
func _handle_client_connected():
	print("Client connected to server!")


#Receber dados do server
func _handle_network_data(data):
	print("Received server data: ", data)
	var json=JSON.new()
	json.parse(data)
	var message: Dictionary = json.get_data() 
	match (message.type):


		"player_position":
			if message.id not in players:
				# cria um novo nó de cena para o novo jogador
				newplayer(message.id,message.username)
			players[message.id].position = Vector2(message.x, message.y)


		"player_connected":
			send_player_position(MyPlayer.position.x, MyPlayer.position.y)


		"player_disconnected":
			if message.id in players:
				players[message.id].queue_free()
				players.erase(message.id)


		"id":
			MyPlayer=player.instantiate()
			username=username_textbox.text
			player_id=message.id
			MyPlayer.game_scene=self
			MyPlayer.get_node("Label").text=username
			players[message.id] = MyPlayer
			call_deferred("add_child",MyPlayer)
			$login.visible=false
			$OpenChat.visible=true
		
		
		"chat_message":
			$Chat/TextEdit.text+=message.username+": "+message.text+"\n"


		"system_message":
			$login/Label.text=message.text
#Enviar msg para o chat 
func send_chat_message(nome, text):
	var message = {'type': "chat_message", 'name': nome, 'text': text}
	send_text(JSON.stringify(message))


#Enviar player position para o chat 
func send_player_position(x, y):
	var message = {'type': 'player_position', 'id': player_id, 'x': x, 'y': y}
	send_text(JSON.stringify(message))



#Botões

#Register And Login
func _on_login_pressed():
	var username = username_textbox.text
	var password = password_textbox.text
	var message = {"type": "login", "username": username, "password": password}
	send_text(JSON.stringify(message))


func _on_register_pressed():
	var username = username_textbox.text
	var password = password_textbox.text
	var message = {"type": "register", "username": username, "password": password}
	send_text(JSON.stringify(message))
#Register And Login END


#Enviar mensagem no chat
func _on_send_message_pressed():
	var text = $Chat/LineEdit.text.strip_escapes()
	if text != "":
		send_chat_message(username,text)
		$Chat/TextEdit.text+=text+"\n"
		$Chat/LineEdit.clear()


#close chat
func _on_close_pressed():
	MyPlayer.inchat=false
	$Chat.visible=false
	$OpenChat.visible=true


#Open chat
func _on_open_chat_pressed():
	MyPlayer.inchat=true
	$Chat.visible=true
	$OpenChat.visible=false

#Botões End


#Enviar msg server
func send_text(text):
	_network_client._send_string(text)
