extends Node2D

@export var layout: PackedScene
@onready var hallway_tilemap = $TileMap  

var layout_instance: Node
var current_level = 1
var all_connection_points: Array = []
# Preload room prefabs
const START_ROOM = preload("res://DungeonGenerator/RoomPrefabs/LVL1/Start/start_prefab_1.tscn")
const NORMAL_ROOM = preload("res://DungeonGenerator/RoomPrefabs/LVL1/Normal/normal_prefab_1.tscn")
const BOSS_ROOM = preload("res://DungeonGenerator/RoomPrefabs/LVL1/Boss/boss_prefab_1.tscn")

func _ready() -> void:
	add_layout_to_scene()
	for room in get_tree().get_nodes_in_group("pickable"):
		for point in room.get_unused_connections():
			all_connection_points.append(point)
	for con in get_tree().get_nodes_in_group("connections"):
		# Get closest connection points for each endpoint of the connection line
		var start_point_room = _get_room_with_closest_connection_point(con.get_point_position(0), all_connection_points)
		var end_point_room = _get_room_with_closest_connection_point(con.get_point_position(1), all_connection_points)
		
		# Set these rooms as room1 and room2 for the connection
		con.set_rooms(start_point_room, end_point_room)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("generate"):
		generate()
	if Input.is_action_just_pressed("rotate"):
		rotate_rooms()
# Helper function to get the room with the closest connection point to a given point
func _get_room_with_closest_connection_point(point: Vector2, connection_points: Array) -> Node:
	var closest_distance = INF
	var closest_room = null
	for connection_point in connection_points:
		var distance = connection_point.global_position.distance_to(point)
		if distance < closest_distance:
			closest_distance = distance
			closest_room = connection_point.get_parent().get_parent()
	return closest_room
	
func add_layout_to_scene():
	layout_instance = layout.instantiate()
	self.add_child(layout_instance)

func rotate_rooms() -> void:
	layout_instance.start_rotation()

func create_hallways() -> void:
	for con in get_tree().get_nodes_in_group("connections"):
		var start_point = con.get_point_position(0)
		var end_point = con.get_point_position(1)
		
		var start_type = con.current_point1.direction
		var end_type = con.current_point2.direction
		if start_type in ["UP", "DOWN"]:
			if end_type in ["UP", "DOWN"]:
				create_vertical_hallway(start_point, Vector2(start_point.x, (start_point.y + end_point.y) / 2))
				create_horizontal_hallway(Vector2(start_point.x, (start_point.y + end_point.y) / 2), end_point)
				create_vertical_hallway(Vector2(end_point.x, (start_point.y + end_point.y) / 2), end_point)
			elif end_type in ["LEFT", "RIGHT"]:
				create_vertical_hallway(start_point, Vector2(start_point.x, end_point.y))
				create_horizontal_hallway(Vector2(start_point.x, end_point.y), end_point)
		if start_type in ["LEFT", "RIGHT"]:
			if end_type in ["UP", "DOWN"]:
				print("wow")
				create_horizontal_hallway(start_point, Vector2(end_point.x, start_point.y))
				create_vertical_hallway(Vector2(end_point.x, start_point.y), end_point)
			elif end_type in ["LEFT", "RIGHT"]:
				create_horizontal_hallway(start_point, end_point)
				
func create_vertical_hallway(start: Vector2, end: Vector2):
	var step = 1 if start.y < end.y else -1
	var current_y = start.y
	while current_y != end.y:
		set_tile_at_world_position(Vector2(start.x, current_y))
		current_y += step * 16  # 16 being the size of your tile.
	set_tile_at_world_position(end)

func create_horizontal_hallway(start: Vector2, end: Vector2):
	var step = 1 if start.x < end.x else -1
	var current_x = start.x
	while current_x != end.x:
		set_tile_at_world_position(Vector2(current_x, start.y))
		current_x += step * 16  # 16 being the size of your tile.
	set_tile_at_world_position(end)
	
func set_tile_at_world_position(pos: Vector2):
	# Convert the world position to the TileMap's cell position.
	var cell_position = hallway_tilemap.local_to_map(pos)
	hallway_tilemap.set_cell(0, cell_position, 1)
  # Assumes you're using tile index 0 for your hallway.
	
	
func generate() -> void:
	for room in get_tree().get_nodes_in_group("pickable"):
		match room.room_type:
			"Start":
				var instance = START_ROOM.instantiate()
				self.add_child(instance)
				instance.add_to_group("rooms")
				instance.global_position = room.global_position
			"Normal":
				var instance = NORMAL_ROOM.instantiate()
				self.add_child(instance)
				instance.add_to_group("rooms")
				instance.global_position = room.global_position
			"Boss":
				var instance = BOSS_ROOM.instantiate()
				self.add_child(instance)
				instance.add_to_group("rooms")
				instance.global_position = room.global_position
	create_hallways()
