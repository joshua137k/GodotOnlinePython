extends Node

var username="UNK"
var myid=0

func _ready():
	WebsocketClient.connect_to_server("localhost", 9000)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
