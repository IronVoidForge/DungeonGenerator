extends TileMap
@onready var connection_points = $ConnectionPoints
@onready var room_area = $ColorRect
func _ready() -> void:
	self.add_to_group("prefabs")
	
func _exit_tree() -> void:
	self.remove_from_group("prefabs")

func _on_player_detector_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
	#spawn enemies
	#close all doors
	
#open_unlocked_doors

#close_all_doors

#on enemy killed
# num_eneies -1
# if num_enemies <= 0
	#open_unlocked_doors
	

