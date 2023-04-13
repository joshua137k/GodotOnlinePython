extends Node3D

#Nodes
@onready var player=preload("res://PlayerAndPeer/car.tscn")
@onready var peer=preload("res://PlayerAndPeer/peer.tscn")

#Var
var player_id = -1
var players = {}
var MyPlayer


func _ready():
	WebsocketClient.connect("connected", _handle_client_connected)
	WebsocketClient.connect("data", _handle_network_data)
	MyPlayer=player.instantiate()
	player_id=Global.myid
	MyPlayer.position=$Marker3D.position
	MyPlayer.get_node("Label").text=Global.username
	players[Global.myid] = MyPlayer
	call_deferred("add_child",MyPlayer)
	$OpenChat.visible=true



#NewPeer
func newplayer(id,username):
	var new=peer.instantiate()
	new.get_node("Label").text=username
	new.position=$Marker3D.position
	players[id] = new
	send_player_position(str(new.position), str(new.rotation))
	call_deferred("add_child",new)


#Client Conectou
func _handle_client_connected():
	print("Client connected to server!")


#Receber dados do server
func _handle_network_data(data):
	#print("Received server data: ", data)
	var json=JSON.new()
	json.parse(data)
	
	var message: Dictionary = json.get_data() 
	match (message.type):


		"player_position":
			UpdateDataPeer(message)

		#"player_connected":
			#send_player_position(str(MyPlayer.position), str(MyPlayer.rotation))

		"player_disconnected":
			if str(message.id) in players:

				players[str(message.id)].queue_free()
				players.erase(str(message.id))
		
		"chat_message":
			$Chat/TextEdit.text+=message.username+": "+message.text+"\n"

func UpdateDataPeer(message):
	if message.id not in players:
		# cria um novo nó de cena para o novo jogador
		newplayer(message.id,message.username)
			#print()
	players[message.id].position = str_to_var("Vector3"+message.data[0])
	players[message.id].rotation = str_to_var("Vector3"+message.data[1])
#Enviar msg para o chat 
func send_chat_message(nome, text):
	var message = {'type': "chat_message", 'name': nome, 'text': text}
	send_text(JSON.stringify(message))


#Enviar player position para o chat 
func send_player_position(pos:String, rot:String):
	var data = [pos,rot]
	var message = {'type': 'player_position', 'id': player_id, 'data':data}
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
