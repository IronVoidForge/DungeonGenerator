extends Node2D
var can_place = true
@onready var level = get_node("/root/Main/Layout")
var current_item
var cursor_sprite

func _ready():
	cursor_sprite = $Sprite2D  # Assuming the Sprite2D node is a direct child of EditorObject

	
func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()
	
	if(current_item != null and can_place and Input.is_action_just_pressed("mb_left")):
		var new_item = current_item.instantiate()
		level.add_child(new_item)
		new_item.global_position = get_global_mouse_position()
		# Reset current_item after placement
		current_item = null
		cursor_sprite.texture = null

