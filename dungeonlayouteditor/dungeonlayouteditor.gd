@tool
extends EditorPlugin

const main = preload("res://addons/dungeonlayouteditor/main.tscn")
var main_instance
func _enter_tree():
	main_instance = main.instantiate()
	get_editor_interface().get_editor_main_screen().add_child(main_instance)
	_make_visible(false)
	
func _exit_tree():
	if main_instance:
		main_instance.queue_free()

func _has_main_screen():
	return true

func _make_visible(visible):
	if main_instance:
		main_instance.visible = visible

func _get_plugin_name():
	return "DungeonLayout"
	
func _get_plugin_icon():
	return get_editor_interface().get_base_control().get_theme_icon("Node", "EditorIcons")
