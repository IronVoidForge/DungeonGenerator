extends TileMap

func _ready() -> void:
	self.add_to_group("prefabs")
	
func _exit_tree() -> void:
	self.remove_from_group("prefabs")
