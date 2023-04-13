extends Control


func _ready():
	
	WebsocketClient.connect("error",ErrorConnect)
	WebsocketClient.connect("connected",Connected)
	WebsocketClient.connect("disconnected",ErrorConnect)

func _on_connect_pressed():
	WebsocketClient.connect_to_server("7.tcp.eu.ngrok.io:10836", 9000)
	


func ErrorConnect(was_clean):
	get_parent().get_node("Login").visible=false
	visible=true
	$Label.text="SERVER DESLIGADO"

func Connected():
	visible=false
	get_parent().get_node("Login").visible=true

