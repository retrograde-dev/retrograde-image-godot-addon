class_name RetrogradeImageSaveFile

const FILE_PATH: String = "user://retrograde_image.json"

var data: Dictionary = {}

func load() -> void:
	if not FileAccess.file_exists(FILE_PATH):
		return

	var handle_: FileAccess = FileAccess.open(FILE_PATH, FileAccess.READ)

	assert(handle_ != null, "File could not be read from. (" + FILE_PATH + ")")
	
	if handle_ == null:
		return

	var contents: String = handle_.get_as_text(true)
	handle_.close()

	var json: JSON = JSON.new()

	if json.parse(contents) != OK:
		@warning_ignore("assert_always_true")
		assert(true, "File could not be parsed. (" + FILE_PATH + ")")
		return

	data = json.data as Dictionary

func save() -> void:
	var handle_: FileAccess = FileAccess.open(FILE_PATH, FileAccess.WRITE)
	
	assert(handle_ != null, "File could not be written to. (" + FILE_PATH + ")")

	if handle_ == null:
		return

	handle_.store_string(JSON.stringify(data))
	handle_.close()
	
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
