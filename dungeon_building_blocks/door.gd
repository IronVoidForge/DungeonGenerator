extends Node2D

func turn_door(connection):
	if connection.direction == "DOWN":
		self.rotation = 0
	if connection.direction == "LEFT":
		self.rotation = PI/2
	if connection.direction == "UP":
		self.rotation = PI
	if connection.direction == "RIGHT":
		self.rotation = 3*PI/2
