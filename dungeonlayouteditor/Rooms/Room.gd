extends RigidBody2D

var is_being_dragged = false
var is_connect_mode = false
var is_rearrange_mode = false
var last_position = Vector2()
var grid_size = 16
var spacing = 128

@onready var connection_container = $Connections
@onready var timer = $Timer
@onready var collision_shape =$CollisionShape2D
@onready var room_envelope = $ColorRect.size

@export_enum("Start", "Normal", "Boss") var room_type: String
signal clicked
signal body_added_to_tree
signal position_changed

func _ready():
	collision_shape.shape.size = Vector2(room_envelope.x+ spacing*2, room_envelope.y + spacing*2)
	add_to_group("pickable")
	emit_signal("body_added_to_tree", self)

func _physics_process(_delta):
	if last_position != global_position:
		emit_signal("position_changed")
		last_position = global_position
		_wake_all_rigid_bodies()
	if is_being_dragged and is_rearrange_mode:
		global_position = get_global_mouse_position()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if is_connect_mode:
				emit_signal("clicked", self)
			elif is_rearrange_mode:
				is_being_dragged = true
		else:
			if is_being_dragged:
				timer.start()
			is_being_dragged = false

func _wake_all_rigid_bodies():
	for i in range(5):  # Wake up 3 times
		for node in get_tree().get_nodes_in_group("pickable"):
			if node is RigidBody2D:
				collision_shape.disabled = false
				node.sleeping = false
		await get_tree().create_timer(0.125).timeout
#	snap_to_grid()

func get_unused_connections():
	var unused: Array =[]
	for i in connection_container.get_children():
		if not i.get_in_use():
			unused.append(i)
	return unused

func _exit_tree() -> void:
	remove_from_group("pickable")

func _on_timer_timeout() -> void:
	_wake_all_rigid_bodies()

func snap_to_grid():
	for node in get_tree().get_nodes_in_group("pickable"):
		if node is RigidBody2D:
			collision_shape.disabled = false
			var snapped_x = round(node.global_position.x / grid_size) * grid_size
			var snapped_y = round(node.global_position.y / grid_size) * grid_size
			node.global_position = Vector2(snapped_x, snapped_y)
		
