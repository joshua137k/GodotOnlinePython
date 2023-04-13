extends VehicleBody3D


var inchat:bool

func _physics_process(delta):
	var lado=Input.get_axis("d","a")*0.4
	var force=Input.get_axis("s","w")*100
	steering=lado
	engine_force=force
	
	if linear_velocity!=Vector3.ZERO:
		get_parent().send_player_position(str(position),str(rotation))
	if Input.is_action_pressed("espace"):
		linear_velocity=Vector3(
			lerp(linear_velocity.x, linear_velocity.x - 2, delta),   
			lerp(linear_velocity.y, linear_velocity.y - 2, delta),
			lerp(linear_velocity.z, linear_velocity.z - 2, delta)
			)
	
