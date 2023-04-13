extends Node2D

const MOVEMENT_SPEED = 200
var move_dir = Vector2.ZERO
var game_scene
var inchat=false

func _process(delta):
	# ler entrada do jogador
	
	if Input.is_action_pressed("move_up"):
		move_dir.y -= 1
		move(Vector2(0,-1))
		
	if Input.is_action_pressed("move_down"):

		move(Vector2(0,1))
	if Input.is_action_pressed("move_left"):
		move(Vector2(1,0))
	if Input.is_action_pressed("move_right"):
		move(Vector2(-1,0))

	# normalizar o vetor de movimento para que o jogador não se mova mais rápido na diagonal
	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()

	# mover o jogador
	if !inchat:
		position+=move_dir * MOVEMENT_SPEED * delta
	move_dir=Vector2.ZERO
	# enviar posição atual para o servidor

func move(pos):
	move_dir+=pos
	if !inchat:
		game_scene.send_player_position(position.x, position.y)
