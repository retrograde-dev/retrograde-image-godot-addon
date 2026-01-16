class_name RetrogradeImageSave

const FILE_PATH: String = "user://retrograde_image.json"

var data: Dictionary = {}

func load() -> void:
	if ProjectSettings.has_setting("addons/retrograde_image"):
		data = ProjectSettings.get_setting("addons/retrograde_image")
		ProjectSettings.clear("addons/retrograde_image")
		save()
	else:
		data.set("configs", ProjectSettings.get_setting("addons/retrograde_image/configs", {}))
		data.set("selected_config_path", ProjectSettings.get_setting("addons/retrograde_image/selected_config_path", ""))

func save() -> void:
	ProjectSettings.set_setting("addons/retrograde_image/configs", data.get("configs", {}))
	ProjectSettings.set_setting("addons/retrograde_image/selected_config_path", get_selected_config_path())
	ProjectSettings.save()
	
func get_config_paths() -> Array:
	return data.get("configs", {}).keys()

func get_selected_config_path() -> String:
	return data.get("selected_config_path", "")
	
func set_selected_config_path(path_: String) -> void:
	data.set("selected_config_path", path_)

func get_config_data(path_: String) -> Dictionary:
	return data.get("configs", {}).get(path_, {})

func set_config_data(path_: String, data_: Dictionary) -> void:
	if not data.has("configs"):
		data.set("configs", {})
		
	data.configs.set(path_, data_)
	
func erase_config_data(path_: String) -> void:
	if data.has("configs"):
		data.configs.erase(path_)
		
	if get_selected_config_path() == path_:
		set_selected_config_path("")
