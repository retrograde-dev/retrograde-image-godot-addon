class_name RetrogradeImageSave

var _configs: Dictionary = {}
var _selected_config_path: String = ""
var _h_split_offsets: PackedInt32Array = []

func load() -> void:
	_configs = ProjectSettings.get_setting("addons/retrograde_image/configs", {})
	_selected_config_path = ProjectSettings.get_setting("addons/retrograde_image/selected_config_path", "")
	_h_split_offsets = ProjectSettings.get_setting("addons/retrograde_image/h_split_offsets", [])

func save() -> void:
	ProjectSettings.set_setting("addons/retrograde_image/configs", _configs)
	ProjectSettings.set_setting("addons/retrograde_image/selected_config_path", _selected_config_path)
	ProjectSettings.set_setting("addons/retrograde_image/h_split_offsets", _h_split_offsets)
	
	ProjectSettings.save()
	
func get_config_paths() -> Array:
	return _configs.keys()

func get_selected_config_path() -> String:
	return _selected_config_path
	
func set_selected_config_path(path_: String) -> void:
	_selected_config_path = path_

func get_config_data(path_: String) -> Dictionary:
	return _configs.get(path_, {})

func set_config_data(path_: String, data_: Dictionary) -> void:
	_configs.set(path_, data_)
	
func erase_config_data(path_: String) -> void:
	_configs.erase(path_)
		
	if get_selected_config_path() == path_:
		set_selected_config_path("")

func get_h_split_offsets() -> PackedInt32Array:
	return _h_split_offsets

func set_h_split_offsets(offsets_: PackedInt32Array) -> void:
	_h_split_offsets = offsets_
