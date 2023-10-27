extends Camera2D

var move_speed = 400  # Pixels per second
var zoom_speed = 0.02  # Amount of zoom per frame

func _process(delta):
	var move_vec = Vector2()

	if Input.is_key_pressed(KEY_W):
		move_vec.y -= 1
	if Input.is_key_pressed(KEY_S):
		move_vec.y += 1
	if Input.is_key_pressed(KEY_A):
		move_vec.x -= 1
	if Input.is_key_pressed(KEY_D):
		move_vec.x += 1

	# Normalize to avoid faster diagonal movement
	move_vec = move_vec.normalized() 

	# Update camera position
	position += move_vec * move_speed * delta

	if Input.is_key_pressed(KEY_E):
		zoom += Vector2(zoom_speed, zoom_speed)
	if Input.is_key_pressed(KEY_Q):
		if zoom >= Vector2(.1, .1):
			zoom -= Vector2(zoom_speed, zoom_speed)
