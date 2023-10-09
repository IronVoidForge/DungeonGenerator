extends Node2D

var target_rotation = 0.0
var rotation_done = 0.0
var rotate_speed = PI / 3
var is_rotate_mode = false

func _process(delta: float) -> void:
	if is_rotate_mode:
		var rotate_this_frame = rotate_speed * delta
		if rotation_done + rotate_this_frame >= target_rotation:
			rotate_this_frame = target_rotation - rotation_done
			is_rotate_mode = false
			if lines_crossed():
				start_rotation()
		_rotate_rooms(rotate_this_frame)
		rotation_done += rotate_this_frame
		if get_parent().name == "Main" and get_parent().is_rotate_mode == true:
			get_parent().is_rotate_mode = false

func save_to_scene(path: String):
	var layout_to_save = self.duplicate()
	for child_node in layout_to_save.get_children():
		child_node.set_owner(layout_to_save)
	var packed_scene = PackedScene.new()
	packed_scene.pack(layout_to_save)
	ResourceSaver.save(packed_scene, path)

func _rotate_rooms(rotate_amount):
	var center = Vector2.ZERO  # Global origin
	for node in get_tree().get_nodes_in_group("pickable"):
		var direction = node.global_position - center
		direction = direction.rotated(rotate_amount)
		node.global_position = center + direction

func start_rotation():
	if not is_rotate_mode:  # Only start rotation if not already rotating
		target_rotation = (randf() * 1.5) * PI + rotation_done
		is_rotate_mode = true

func lines_crossed() -> bool:
	var connections = get_tree().get_nodes_in_group("connections")
	for i in range(connections.size()):
		for j in range(i+1, connections.size()):
			if _do_intersect(connections[i].get_point_position(0), connections[i].get_point_position(1), connections[j].get_point_position(0), connections[j].get_point_position(1)):
				return true
	return false

func _orientation(p, q, r) -> int:
	var val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
	if val == 0:
		return 0  # collinear
	return 1 if val > 0 else 2  # clock or counterclockwise

func _do_intersect(p1, q1, p2, q2) -> bool:
	var o1 = _orientation(p1, q1, p2)
	var o2 = _orientation(p1, q1, q2)
	var o3 = _orientation(p2, q2, p1)
	var o4 = _orientation(p2, q2, q1)
	
	if o1 != o2 and o3 != o4:
		return true
	
	if o1 == 0 and _on_segment(p1, p2, q1):
		return true
	
	if o2 == 0 and _on_segment(p1, q2, q1):
		return true
	
	if o3 == 0 and _on_segment(p2, p1, q2):
		return true
	
	if o4 == 0 and _on_segment(p2, q1, q2):
		return true
	
	return false

func _on_segment(p, q, r) -> bool:
	return q.x <= max(p.x, r.x) and q.x >= min(p.x, r.x) and q.y <= max(p.y, r.y) and q.y >= min(p.y, r.y)
