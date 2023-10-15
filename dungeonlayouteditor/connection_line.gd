extends Line2D

@export var room1_path : String = ""
@export var room2_path : String = ""
var room1 : Node = null  # The first room
var room2 : Node = null  # The second room
var current_point1 : Node = null
var current_point2 : Node = null
 
func _ready():
	add_to_group("connections")
	# Restore the references from the paths
	if room1_path != "" and has_node(room1_path):
		room1 = get_node(room1_path)
	if room2_path != "" and has_node(room2_path):
		room2 = get_node(room2_path)
	if room1 and room2:
		set_rooms(room1, room2)

func set_rooms(node1: Node, node2: Node):
	if room1:
		room1.disconnect("position_changed", Callable(self, "update_line"))
	if room2:
		room2.disconnect("position_changed", Callable(self, "update_line"))
	room1 = node1
	room2 = node2
	# Save the paths so they can be used after loading the scene
	room1_path = room1.get_path()
	room2_path = room2.get_path()

	room1.connect("position_changed", Callable(self, "update_line"))
	room2.connect("position_changed", Callable(self, "update_line"))
	# Update the line immediately
	update_line()

func update_line():
	# Clear previous connection points
	if current_point1:
		current_point1.in_use = false
	if current_point2:
		current_point2.in_use = false

	var closest_points = find_closest_points(room1, room2)

	var point1 = closest_points[0]
	var point2 = closest_points[1]
	if point1 and point2:
		if self.get_point_count() == 0:
			# If no points in the Line2D, add two new ones
			self.add_point(point1.global_position)
			self.add_point(point2.global_position)
		else:
			# Otherwise, just set their positions
			self.set_point_position(0, point1.global_position)
			self.set_point_position(1, point2.global_position)

		# Set the current connection points as used and store them
		point1.in_use = true
		point2.in_use = true
		current_point1 = point1
		current_point2 = point2

func find_closest_points(r1, r2):
	var min_distance = INF
	var closest_pair = [null, null]
	var room1_points = r1.get_unused_connections()
	var room2_points = r2.get_unused_connections()
	for point1 in room1_points:
		for point2 in room2_points:
			var distance = point1.global_position.distance_to(point2.global_position)
#			print(point1.global_position, " to ", point2.global_position, " distance: ", distance)
			if distance < min_distance:
				min_distance = distance
				closest_pair = [point1, point2]
#	print(min_distance)
	return closest_pair

func _exit_tree() -> void:
	remove_from_group("connections")
