extends Node2D

var is_connect_mode = false
var is_rearrange_mode = false
var is_rotate_mode = false
var target_rotation = 0.0
var rotation_done = 0.0
var rotate_speed = PI / 3
var clicked_bodies = []
@onready var connect_button = $RoomSelect/TabContainer/Rooms/ScrollContainer/VBoxContainer/HBoxContainer3/ConnectButton
@onready var rearrange_button = $RoomSelect/TabContainer/Rooms/ScrollContainer/VBoxContainer/HBoxContainer3/RearrangeButton
@onready var rotate_button = $RoomSelect/TabContainer/Rooms/ScrollContainer/VBoxContainer/HBoxContainer3/RotateButton
@onready var save_button = $RoomSelect/TabContainer/Rooms/ScrollContainer/VBoxContainer/HBoxContainer3/SaveButton
@onready var layout = $Layout
# Load the Line2D scene
var connection_line_scene = preload("res://dungeonlayouteditor/connection_line.tscn")

func _ready():
	connect_button.connect("toggled", Callable(self, "_on_ConnectButton_toggled"))
	rearrange_button.connect("toggled", Callable(self, "_on_RearrangeButton_toggled"))
	rotate_button.connect("pressed", Callable(self, "_on_RotateButton_pressed"))
	save_button.connect("pressed", Callable(self, "_on_SaveButton_pressed"))
	get_tree().connect("node_added", Callable(self, "_on_NodeAdded"))
	$FileDialog.mode = FileDialog.FILE_MODE_SAVE_FILE
	$FileDialog.filters = ["*.tscn"]
		
func _on_NodeAdded(node):
	# Check if the newly added node has the signal we're looking for (body_added_to_tree)
	if node.has_signal("body_added_to_tree"):
		if not node.is_connected("body_added_to_tree", Callable(self, "_on_BodyAddedToTree")):
			node.connect("body_added_to_tree", Callable(self, "_on_BodyAddedToTree"))

func _on_BodyAddedToTree(body):
	if body.is_connected("clicked", Callable(self, "_on_body_clicked")):
		body.disconnect("clicked", Callable(self, "_on_body_clicked"))
	body.connect("clicked", Callable(self, "_on_body_clicked"))
	body.is_connect_mode = is_connect_mode
	body.is_rearrange_mode = is_rearrange_mode

func _on_body_clicked(body):
	clicked_bodies.append(body)
	if clicked_bodies.size() == 2:
		_connect_bodies()
		
func _connect_bodies():
	# Instantiate a new Line2D from the scene
	var new_connection_line = connection_line_scene.instantiate()
	# Set rooms for the connection line FIRST before calling any function that uses them.
	new_connection_line.set_rooms(clicked_bodies[0], clicked_bodies[1])
	layout.add_child(new_connection_line)
	
	# Reset for next pair
	clicked_bodies.clear()


func _on_ConnectButton_toggled(button_pressed):
	if button_pressed:
		rearrange_button.button_pressed = false  # Turn off rearrange mode when connect is on
		is_connect_mode = true
		for node in get_tree().get_nodes_in_group("pickable"):
			node.set_pickable(true)  # Enable clicking on the bodies
	else:
		is_connect_mode = false
#		for node in get_tree().get_nodes_in_group("pickable"):
#			node.set_pickable(false)  # Disable clicking on the bodies
	for node in get_tree().get_nodes_in_group("pickable"):
		node.is_connect_mode = is_connect_mode
		node.is_rearrange_mode = is_rearrange_mode
		
	
func _on_RearrangeButton_toggled(button_pressed):
	if button_pressed:
		connect_button.button_pressed = false  # Turn off connect mode when rearrange is on
		is_rearrange_mode = true
		is_connect_mode = false
	else:
		is_rearrange_mode = false
	# Update the mode on all "pickable" bodies
	for node in get_tree().get_nodes_in_group("pickable"):
		node.settled = false
		node.is_connect_mode = is_connect_mode
		node.is_rearrange_mode = is_rearrange_mode

func _on_RotateButton_pressed():
	# You might want to disable other modes when rotation mode is on
	is_connect_mode = false
	is_rearrange_mode = false
	for node in get_tree().get_nodes_in_group("pickable"):
		node.settled = false
	layout.start_rotation()

func _on_SaveButton_pressed():
	$FileDialog.popup_centered()

func _on_file_dialog_file_selected(path: String) -> void:
	layout.save_to_scene(path)
