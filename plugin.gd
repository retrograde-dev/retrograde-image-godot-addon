@tool
extends EditorPlugin

var bottom_panel: Control = null

func _enter_tree() -> void:
	_load_bottom_panel()

func _exit_tree() -> void:
	if bottom_panel != null:
		remove_control_from_bottom_panel(bottom_panel)
	
func _load_bottom_panel() -> void:
	if ProjectSettings.has_setting("editor_plugins/enabled"):
		var enabled_: PackedStringArray = ProjectSettings.get_setting("editor_plugins/enabled")
	
		# If the retrograde addon is installed/enabled then let it handle the integration
		if enabled_.has("res://addons/retrograde/plugin.cfg"):
			return

	bottom_panel = preload("res://addons/retrograde_image/plugin/bottom_panel.tscn").instantiate()
			
	add_control_to_bottom_panel(bottom_panel, "Retrograde")
