extends TextureRect

@export var room: PackedScene

var object_cursor
var curson_sprite
func _ready() -> void:
	object_cursor = get_node("/root/Main/EditorObject")
	curson_sprite = get_node("/root/Main/EditorObject/Sprite2D")
	
func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("mb_left"):
		item_clicked()

func item_clicked():
	object_cursor.current_item = room
	curson_sprite.texture = texture
