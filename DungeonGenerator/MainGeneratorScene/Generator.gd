extends Node2D

@export var layout: PackedScene
@onready var floor_tilemap = $Floors
@onready var wall_tilemap = $Walls
@onready var door = preload("res://dungeon_building_blocks/door.tscn")
@onready var doors = $Doors

var wall_thickness = 1
var layout_instance: Node
var current_level = 1
var surrounding_offsets = [
	Vector2i(0, -1),  # Above
	Vector2i(1, 0),   # Right
	Vector2i(-1, 0),  # Left
	Vector2i(0, 1),   # Below
	Vector2i(1, 1),   # Bottom-right
	Vector2i(-1, 1),  # Bottom-left
	Vector2i(1, -1),  # Top-right
	Vector2i(-1, -1)  # Top-left
]
var ROOM_MAP = {
	"Start": START_ROOM,
	"Normal": NORMAL_ROOM,
	"Boss": BOSS_ROOM,
	"Exit": EXIT_ROOM,
	"Key": KEY_ROOM,
	"NPC": NPC_ROOM,
	"PreBoss": PREBOSS_ROOM,
	"Secret": SECRET_ROOM,
	"Shop": SHOP_ROOM,
	"Treasure": TREASURE_ROOM
}
var all_connection_points: Array = []
var astar_grid = AStarGrid2D.new()
var astar = AStar2D.new()
var astar_rect : Rect2i
# Preload room prefabs
const BOSS_ROOM = preload("res://DungeonGenerator/RoomPrefabs/LVL1/Boss/boss_prefab_1.tscn")
const EXIT_ROOM = preload("res://DungeonGenerator/RoomPrefabs/LVL1/Exit/exit_prefab_1.tscn")
const KEY_ROOM = preload("res://DungeonGenerator/RoomPrefabs/LVL1/Key/key_prefab_1.tscn")
const NORMAL_ROOM = preload("res://DungeonGenerator/RoomPrefabs/LVL1/Normal/normal_prefab_1.tscn")
const NPC_ROOM = preload("res://DungeonGenerator/RoomPrefabs/LVL1/NPC/npc_prefab_1.tscn")
const PREBOSS_ROOM = preload("res://DungeonGenerator/RoomPrefabs/LVL1/PreBoss/pre_boss_prefab_1.tscn")
const SECRET_ROOM = preload("res://DungeonGenerator/RoomPrefabs/LVL1/Secret/secret_prefab_1.tscn")
const SHOP_ROOM = preload("res://DungeonGenerator/RoomPrefabs/LVL1/Shop/shop_prefab_1.tscn")
const START_ROOM = preload("res://DungeonGenerator/RoomPrefabs/LVL1/Start/start_prefab_1.tscn")
const TREASURE_ROOM = preload("res://DungeonGenerator/RoomPrefabs/LVL1/Treasure/treasure_prefab_1.tscn")

func _ready() -> void:
	add_layout_to_scene()
	for room in get_tree().get_nodes_in_group("pickable"):
		for point in room.get_unused_connections():
			all_connection_points.append(point)
	for con in get_tree().get_nodes_in_group("connections"): # Get closest connection points for each endpoint of the connection line
		var start_point_room = _get_room_with_closest_connection_point(con.get_point_position(0), all_connection_points)
		var end_point_room = _get_room_with_closest_connection_point(con.get_point_position(1), all_connection_points)
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
func initialize_astar_grid():
	var rect = floor_tilemap.get_used_rect()
	rect.position -= Vector2i(5, 5)
	rect.size += Vector2i(10, 10)
	astar_grid.region = Rect2i(rect.position, rect.size)
	astar_grid.cell_size = Vector2(floor_tilemap.cell_quadrant_size, floor_tilemap.cell_quadrant_size)
	astar_grid.update()
	print("AStarGrid initialized with region:", astar_grid.region)

func update_astar_grid_for_tilemap():
	for cell in floor_tilemap.get_used_cells(0):
		# Ensure cell is Vector2i for consistent operations
		cell = Vector2i(cell.x/16, cell.y/16)
		var neighbors = [
			cell + Vector2i(1, 0),
			cell + Vector2i(-1, 0),
			cell + Vector2i(0, 1),
			cell + Vector2i(0, -1),
			cell + Vector2i(1, 1),
			cell + Vector2i(-1, -1),
			cell + Vector2i(1, -1),
			cell + Vector2i(-1, 1)
		]
		for neighbor in neighbors:
			if floor_tilemap.get_cell_source_id(0, neighbor) == -1:
				astar_grid.set_point_solid(neighbor, true)
	astar_grid.update()

func create_hallways() -> void:
	initialize_astar_grid()
	var cells_to_update = []
	for con in get_tree().get_nodes_in_group("connections"):
		update_astar_grid_for_tilemap()
		var start_point = con.get_point_position(0)
		var end_point = con.get_point_position(1)
		room_extension(con)
	# Get the cell positions for the start and end points
		var start_cell = floor_tilemap.local_to_map(floor_tilemap.to_local(start_point))
		var end_cell = floor_tilemap.local_to_map(floor_tilemap.to_local(end_point))
	# Find the path using AStarGrid2D
		var path = astar_grid.get_point_path(start_cell, end_cell)
		for point in path:
			var offsets = [
				Vector2(0, 0),  # Central point
				Vector2(-1, 0),  # Right of the central point
				Vector2(0, -1),  # Above the central point
				Vector2(-1, -1)   # Diagonally top-right from the central point
				]
			for offset in offsets:
				var stamp_point = point + offset * 16  # multiplying by 16 if necessary
				# Here, check if the cell at 'stamp_point' is open before placing a tile
				if floor_tilemap.get_cell_source_id(0, stamp_point) == -1:
					cells_to_update.append(floor_tilemap.local_to_map(stamp_point))
	set_tile_at_world_positions(cells_to_update)

func extend_room_from_point(point, direction):
	var extension_length_cells = 8  # 8 cells
	var hallway_width_cells = 2
	var start_cell = Vector2()
	var end_cell = Vector2()
	point = floor_tilemap.local_to_map(point)  # Convert point from world position to cell position

	if direction == "DOWN":
		start_cell = point + Vector2i(-hallway_width_cells/2, 0)
		end_cell = point + Vector2i(hallway_width_cells/2, -extension_length_cells)
	elif direction == "LEFT":
		start_cell = point + Vector2i(0, -hallway_width_cells/2)
		end_cell = point + Vector2i(extension_length_cells, hallway_width_cells/2)
	elif direction == "UP":
		start_cell = point + Vector2i(-hallway_width_cells/2, 0)
		end_cell = point + Vector2i(hallway_width_cells/2, extension_length_cells)
	elif direction == "RIGHT":
		start_cell = point + Vector2i(0, -hallway_width_cells/2)
		end_cell = point + Vector2i(-extension_length_cells, hallway_width_cells/2)
	# Create a rectangle from the start to end cell positions
	var top_left_cell = Vector2i(min(start_cell.x, end_cell.x), min(start_cell.y, end_cell.y))
	var bottom_right_cell = Vector2i(max(start_cell.x, end_cell.x), max(start_cell.y, end_cell.y))

	var cells_to_update = []
	for x in range(top_left_cell.x, bottom_right_cell.x):  # "+ 1" to include the end cell
		for y in range(top_left_cell.y, bottom_right_cell.y):
			cells_to_update.append(Vector2(x, y))
	set_tile_at_world_positions(cells_to_update)

func room_extension(con):
	# Extend from first connection point
	extend_room_from_point(con.get_point_position(0), con.current_point1.direction)
	# Extend from second connection point
	extend_room_from_point(con.get_point_position(1), con.current_point2.direction)
func set_tile_at_world_positions(cells: Array):
	floor_tilemap.set_cells_terrain_connect(0, cells, 0, 0, true)
	
func set_tile_at_world_position(pos: Vector2):
	# Convert the snapped world position to the TileMap's cell position
	var cell_position = floor_tilemap.local_to_map(pos)
	var cells_to_update =[]
	cells_to_update.append(cell_position)
#	floor_tilemap.set_cell(0, cell_position, 0, Vector2(0,0))
	floor_tilemap.set_cells_terrain_connect(0, cells_to_update, 0,0, true)

func generate() -> void:
	for room in get_tree().get_nodes_in_group("pickable"):
		if ROOM_MAP.has(room.room_type):
			instantiate_and_reparent(room, ROOM_MAP[room.room_type])
	draw_full_dungeon()
	
func instantiate_and_reparent(room, room_node):
	var instance = room_node.instantiate()
	self.add_child(instance)
	instance.add_to_group("rooms")
	instance.global_position = room.global_position
	var connections = room.connection_container
	if connections:
		while connections.get_child_count() > 0:
			var child = connections.get_child(0)
			connections.remove_child(child)
			instance.connection_points.add_child(child)
			
func draw_full_dungeon():
	for prefab in get_tree().get_nodes_in_group("prefabs"):
		draw_from_prefab(prefab)
		prefab.clear()
		prefab.room_area.visible = false
	create_hallways()
	print("hallways done")
	create_walls()
	print("walls done")
	expand_border(wall_thickness)
	print("walls thick done")
	place_doors()
	for room in get_tree().get_nodes_in_group("pickable"):
		room.queue_free()

func draw_from_prefab(prefab: Node2D):
	var cells_to_update = []
	if prefab and prefab is TileMap:
		var layer = 0 # Assuming we're working with the first layer, change as needed
		for cell in prefab.get_used_cells(layer):
			var tile_source_id = prefab.get_cell_source_id(layer, cell)
			if tile_source_id != -1: # Check if the cell is set
				# Translate the prefab cell position to its local world position
				var local_pos = prefab.map_to_local(cell)
				# Adjust for the prefab's global position
				var global_pos = prefab.global_position + local_pos
				# Use the provided function to set the tile at the given world position
				cells_to_update.append(floor_tilemap.local_to_map(global_pos))
	set_tile_at_world_positions(cells_to_update)
	
func place_doors():
	for con in get_tree().get_nodes_in_group("connections"):
		var door1 = door.instantiate()
		var door2 = door.instantiate()
		var connection_point1 = con.current_point1
		var connection_point2 = con.current_point2
		doors.add_child(door1)
		doors.add_child(door2)
		turn_doors(connection_point1, door1)
		turn_doors(connection_point2, door2)

func turn_doors(connection, mydoor):
	mydoor.global_position = connection.global_position
	if connection.direction == "DOWN":
		mydoor.rotation = 0
	if connection.direction == "LEFT":
		mydoor.rotation = PI/2
	if connection.direction == "UP":
		mydoor.rotation = PI
	if connection.direction == "RIGHT":
		mydoor.rotation = 3*PI/2

func create_walls() -> void:
	for cell in floor_tilemap.get_used_cells(0):
			var cells_to_update = []
			# Check each surrounding cell
			for offset in surrounding_offsets:
				var adjacent_cell = cell + offset
				# If the surrounding cell is unoccupied in the hallway_tilemap
				if floor_tilemap.get_cell_source_id(0, adjacent_cell) == -1:
					# Place a wall tile in the wall_tilemap at that cell
					cells_to_update.append(adjacent_cell)
			wall_tilemap.set_cells_terrain_connect(0, cells_to_update, 0,0, true)
			
func expand_border(thickness: int) -> void:
	var original_wall_cells = Dictionary()
	for cell in wall_tilemap.get_used_cells(0):
		original_wall_cells[cell] = true
	for i in range(thickness):
		var new_wall_cells = Dictionary()
		for cell in original_wall_cells.keys():
			for offset in surrounding_offsets:
				var adjacent_cell = cell + offset
				if floor_tilemap.get_cell_source_id(0, adjacent_cell) == -1 and wall_tilemap.get_cell_source_id(0, adjacent_cell) == -1 and not new_wall_cells.has(adjacent_cell):
					new_wall_cells[adjacent_cell] = true
		# Merge the new cells with the original cells
		original_wall_cells.merge(new_wall_cells)
	# Update the wall_tilemap cells with terrain connectivity for all wall cells
	var all_wall_cells = original_wall_cells.keys()
	wall_tilemap.set_cells_terrain_connect(0, all_wall_cells, 0, 0, true)

