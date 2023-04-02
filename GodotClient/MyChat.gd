extends Node2D

#NetworkNode
const NetworkClient = preload("res://websocket_client.gd")


#Nodes
@onready var _network_client = NetworkClient.new()
@onready var username_textbox: LineEdit = get_node("login/VBoxContainer/username")
@onready var password_textbox: LineEdit = get_node("login/VBoxContainer/senha")


#Var
var username= "UNK"

var state:Callable

func _ready():
	_network_client.connect("connected", _handle_client_connected)
	_network_client.connect("data", _handle_network_data)
	add_child(_network_client)
	_network_client.connect_to_server("localhost", 9000)


func _handle_client_connected():
	print("Client connected to server!")


func send_chat(text):
	_network_client._send_string(JSON.stringify(text))

func _handle_network_data(data):
	print("Received server data: ", data)
	var json=JSON.new()
	json.parse(data)
	var message: Dictionary = json.get_data() 
	$Chat/TextEdit.text+=(message["message"] + "\n")
	if message["message"]=="logged_in":
		username=username_textbox.text
		$login.visible=false
		$Chat.visible=true


func _on_login_pressed():
	var username = username_textbox.text
	var password = password_textbox.text
	var message = {"action": "login", "username": username, "password": password}
	send_chat(message)



func _on_register_pressed():
	var username = username_textbox.text
	var password = password_textbox.text
	var message = {"action": "register", "username": username, "password": password}
	send_chat(message)


func _on_send_message_pressed():
	var text = $Chat/LineEdit.text.strip_escapes()
	if text != "":
		var mess={"action": "message", "message":text}
		send_chat(mess)
		$Chat/TextEdit.text+=text+"\n"
		#websocket_client.send_text(text.encode("utf8"))
		$Chat/LineEdit.clear()
