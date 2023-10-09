extends Control

var object_cursor
signal connect_button_toggled(toggled)
# Assuming ConnectButton is a type of toggle button:

func _ready() -> void:
	object_cursor = get_node("/root/Main/EditorObject")
	
func _on_mouse_entered() -> void:
	object_cursor.can_place = false
#	print("entered") 

func _on_mouse_exited() -> void:
	object_cursor.can_place = true
