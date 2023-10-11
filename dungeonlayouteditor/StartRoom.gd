#extends Button
#
#@export var room: PackedScene
#@onready var layout = $"../../../../Layout"
#
#var room_instance: Node2D = null
#var is_following_cursor = false
#var mouse_pos
#
#func _on_room_pressed():
## If a room instance is currently being dragged, finalize its position
#	if room_instance and is_following_cursor:
#		room_instance.position = mouse_pos - layout.global_position
#		room_instance.visible = true
#		room_instance = null
#	room_instance = room.instantiate()
#	layout.add_child(room_instance)
#	room_instance.position = Vector2.ZERO
#	room_instance.set("is_placed", false)
#	is_following_cursor = true
#	room_instance.visible = false # Initially hide
#
#func _on_pressed() -> void:
#	_on_room_pressed()
#	release_focus()
#
#func _process(delta: float) -> void:
#	mouse_pos = layout.get_global_mouse_position()
#	if is_following_cursor and not room_instance.get("is_placed"):
#		room_instance.position = mouse_pos - layout.global_position
#		room_instance.visible = true
#
#
#func _input(event: InputEvent) -> void:
#	if is_following_cursor and event is InputEventMouseButton and event.pressed:
#		room_instance.global_position = event.position - layout.global_position # Set the position to the click location
#		room_instance.set("is_placed", true)
#		is_following_cursor = false # Stop the room from following the cursor
#		room_instance = null # Decouple the room instance
