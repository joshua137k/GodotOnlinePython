extends Node2D

#Nodes
@onready var player=preload("res://player.tscn")
@onready var peer=preload("res://peer.tscn")

#Var
var player_id = -1
var players = {}
var MyPlayer


func _ready():
	WebsocketClient.connect("connected", _handle_client_connected)
	WebsocketClient.connect("data", _handle_network_data)
	MyPlayer=player.instantiate()
	player_id=Global.myid
	MyPlayer.game_scene=self
	MyPlayer.get_node("Label").text=Global.username
	players[Global.myid] = MyPlayer
	call_deferred("add_child",MyPlayer)
	$OpenChat.visible=true



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
			if str(message.id) in players:

				players[str(message.id)].queue_free()
				players.erase(str(message.id))
		
		"chat_message":
			$Chat/TextEdit.text+=message.username+": "+message.text+"\n"



#Enviar msg para o chat 
func send_chat_message(nome, text):
	var message = {'type': "chat_message", 'name': nome, 'text': text}
	send_text(JSON.stringify(message))


#Enviar player position para o chat 
func send_player_position(x, y):
	var message = {'type': 'player_position', 'id': player_id, 'x': x, 'y': y}
	send_text(JSON.stringify(message))



#Botões


#Enviar mensagem no chat
func _on_send_message_pressed():
	var text = $Chat/LineEdit.text.strip_escapes()
	if text != "":
		send_chat_message(Global.username,text)
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
	WebsocketClient._send_string(text)
