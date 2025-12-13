class_name RetrogradeImageConfig

var path: String
var data: Dictionary = {}

func _init(path_: String) -> void:
	path = path_
	
func load() -> void:
	var file_: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file_ == null:
		return
		
	var data_: String = file_.get_as_text()
	
	file_.close()
	
	var json_: JSON = JSON.new()

	if json_.parse(data_) != OK:
		return
		
	data = json_.data as Dictionary
	
func is_empty() -> bool:
	return data.is_empty()
	
func get_name() -> String:
	return data.get("name", path.get_file().get_basename())

func get_version() -> String:
	return str(data.get("version", "v1.0.0"))

func get_outputs() -> Array:
	return data.get("outputs", {}).keys()
	
func get_inputs() -> Array:
	return data.get("inputs", {}).keys()

func get_themes() -> Array:
	var themes_: Array = data.get("themes", {}).keys()
	themes_.push_front("Default")
	return themes_
