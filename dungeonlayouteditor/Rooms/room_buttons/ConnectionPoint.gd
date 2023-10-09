class_name ConnectionPoint extends Marker2D
var in_use = false
@export_enum("UP", "DOWN", "LEFT", "RIGHT") var direction: String

func get_in_use():
	return in_use
