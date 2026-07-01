class_name RetrogradeImage

var _name: String = ""
var _version: String = ""

var _options: Dictionary

var _config_path: String
var _output_path: String = ""

var _input_name: String = ""
var _input_data: Dictionary = {}

var _output_name: String = ""
var _output_data: Dictionary = {}

var _theme_name: String = ""
var _theme_data: Dictionary = {}

var _config_data: Dictionary = {}

var _variant_name: String = ""
var _image_name: String = ""
var _group_name: String = ""
var _layer_name: String = ""
var _frame_index: int = 0
var _frame_width: int = 0
var _frame_height: int = 0
var _image_width: int = 0
var _image_height: int = 0

var _references: Dictionary = {}

var _ora_size: Dictionary = {}
var _ora_layers: Dictionary = {}
var _layer_map: Dictionary = {}

var _errors: Array[String] = []

func run(config_path_: String, options_: Dictionary = {}) -> void:
	_reset()
	
	_config_path = config_path_
	_options = options_
	
	_output_path = options_.get("output_path", "res://")

	var data_: Dictionary = _load_config(config_path_)

	_name = data_.get("name", "Unnamed")
	_version = str(data_.get("version", "v1.0.0"))

	if not data_.has("inputs"):
		_errors.append("No inputs in config (%s)." % config_path_)
		return
	
	if not data_.has("outputs"):
		_errors.append("No outputs in config (%s)." % config_path_)
		return

	for output_name_: String in data_.get("outputs", []).keys():
		if options_.has(&"outputs") and not options_.outputs.has(output_name_):
			continue
			
		var output_data_: Dictionary = data_["outputs"][output_name_]
		var themes_: Array[String]
		
		if options_.has(&"theme"):
			themes_ = [options_.theme]
		elif not data_.has("themes"):
			themes_ = ["Default"]
		else:
			themes_ = output_data_.get("themes", data_.get("themes"))

		for theme_name_: String in themes_:
			for input_name_: String in data_.get("inputs", []).keys():
				if options_.has(&"inputs") and not options_.inputs.has(input_name_):
					continue
		
				if (output_data_.has("inputs") and 
					not output_data_.get("inputs", []).has(input_name_)
				):
					continue

				var input_data_: Dictionary = data_["inputs"][input_name_]
				if (not input_data_.has("paths") or 
					input_data_.get("paths").size() == 0
				):
					continue

				_input_name = input_name_
				_input_data = input_data_
				_output_name = output_name_
				_output_data = output_data_

				for path_: String in input_data_["paths"]:
					path_ = _get_input_path(path_)
					if not FileAccess.file_exists(path_):
						_errors.append("Input path not found. (%s)" % path_)
						continue
						
					_load_layer_map(path_)

				if not _input_data.has("groups"):
					var groups_: Dictionary = {}
					groups_[_input_name] = {}
					
					var variants_: Array[String] = []
					for variant_: String in _layer_map.keys():
						variants_.append(variant_)
						
					groups_[_input_name]["variants"] = variants_
					
					_input_data["groups"] = groups_
	
				if (theme_name_ != "Default" and 
					not data_.get("themes", {}).has(theme_name_)
				): 
					_errors.append("Theme not found. (%s)" % theme_name_)
					continue
					
				_theme_name = theme_name_
				_theme_data = data_.get("themes", {}).get(theme_name_, {})

				for config_data_: Dictionary in output_data_.get("configs", []):
					if (config_data_.has("inputs") and
						not input_name_ in config_data_.get("inputs")
					):
						continue
						
					_config_data = config_data_
					_output_config()

	for error_: String in _errors:
		push_error("Retrograde Image: " + error_)

	EditorInterface.get_resource_filesystem().scan_sources()
	
func _reset() -> void:
	_input_name = ""
	_input_data = {}
	
	_output_name = ""
	_output_data = {}
	
	_theme_name = ""
	_theme_data = {}
	
	_config_data = {}
	
	_variant_name = ""
	_image_name = ""
	_group_name = ""
	_layer_name = ""
	_frame_index = 0
	_frame_width = 0
	_frame_height = 0
	_image_width = 0
	_image_height = 0
	_references = {}
	
	_ora_size = {}
	_ora_layers = {}
	_layer_map = {}
	
	_errors = []

func _output_config() -> void:
	var mode_: String = _config_data.get("mode", "images")

	match mode_:
		"images": _output_images()
		"frames": _output_frames()
		"sheet": _output_sheet()
		"sheet_frames": _output_sheet_frames()
		_: _errors.append("Invalid mode. (%s)" % mode_)

func _get_input_path(path_: String) -> String:
	if path_.begins_with("./"):
		path_ = _config_path.get_base_dir() + path_.lstrip('.')
		
	return path_
	
func _get_output_path() -> String:
	var output_path_: String = _output_path.rstrip("/")
	
	if not _options.get(&"ignore_output_path", false):
		output_path_ += "/" + _output_data.get("path", "") \
			.trim_prefix("res://") \
			.trim_prefix("user://") \
			.lstrip("./").rstrip("/")
		
	if not _options.get(&"ignore_output_config_path", false):
		output_path_ += "/" + _config_data.get("path").lstrip("./")
		
	output_path_ = output_path_.rstrip("/") + ".png"

	if (not output_path_.begins_with("res://") and 
		not output_path_.begins_with("user://")
	):
		output_path_ = "res://" + output_path_.lstrip("/")
	
	return output_path_

func _output_images() -> void:
	var output_path_: String = _get_output_path()

	for group_name_: String in _input_data.get("groups", {}).keys():
		var group_data_: Dictionary = _input_data["groups"][group_name_]
		_group_name = group_name_
		_references = group_data_.get("references", {})

		for variant_name_: String in group_data_.get("variants", []):
			variant_name_ = _get_reference("*", variant_name_)

			if _input_data.get("skip", []).has(variant_name_):
				continue
				
			_variant_name = variant_name_
			
			if _layer_map.has(variant_name_):
				_image_name = _layer_map[variant_name_].get_file().get_basename()
			else:
				_image_name = _input_data.get("paths")[0].get_file().get_basename()

			_frame_index = _config_data.get("start_index", 0)

			var size_with_padding_: Vector2i = _get_size_with_padding(
				_get_size_from_variant(variant_name_),
				_get_padding()
			)
			_frame_width = size_with_padding_.x
			_frame_height = size_with_padding_.y

			var img_: Image = _get_image_from_variant(group_name_, variant_name_)
			
			if img_ == null:
				continue

			_image_width = img_.get_width()
			_image_height = img_.get_height()

			var file_: String = _clean_path(output_path_)
			DirAccess.make_dir_recursive_absolute(file_.get_base_dir())
			img_.save_png(file_)

func _output_frames() -> void:
	var template_: Dictionary = _input_data["templates"][_config_data["template"]]
	var output_path_: String = _get_output_path()

	for group_name_: String in _input_data.get("groups", {}).keys():
		var group_data_: Dictionary = _input_data["groups"][group_name_]
		_group_name = group_name_
		_references = group_data_.get("references", {})

		for variant_name_: String in group_data_.get("variants", []):
			variant_name_ = _get_reference("*", variant_name_)

			if _input_data.get("skip", []).has(variant_name_):
				continue
				
			_variant_name = variant_name_

			if _layer_map.has(variant_name_):
				_image_name = _layer_map[variant_name_].get_file().get_basename()
			else:
				_image_name = _input_data.get("paths")[0].get_file().get_basename()

			_frame_index = _config_data.get("start_index", 0)
			
			var real_frame_index_: int = 0

			var size_with_padding_: Vector2i = _get_size_with_padding(
				_get_size_from_variant(variant_name_),
				_get_padding()
			)
			_frame_width = size_with_padding_.x
			_frame_height = size_with_padding_.y

			for frame_index_: int in template_["frames"].size():
				var img_: Image = _get_image_from_variant(
					group_name_, 
					variant_name_, 
					real_frame_index_
				)
				
				if img_ == null:
					continue

				_image_width = img_.get_width()
				_image_height = img_.get_height()

				var file_: String = _clean_path(output_path_)
				DirAccess.make_dir_recursive_absolute(file_.get_base_dir())
				img_.save_png(file_)

				_frame_index += 1
				real_frame_index_ += 1

func _output_sheet() -> void:
	var output_path_: String = _get_output_path()
	
	var width: int = _config_data.get("sheet_width", 0)
	var height: int = _config_data.get("sheet_height", 0)
	var cols: int = _config_data.get("sheet_cols", 0)
	var rows: int = _config_data.get("sheet_rows", 0)

	if width <= 0 and height <= 0 and rows <= 0 and cols <= 0:
		if "[[group]]" in output_path_:
			_output_sheet_split_directional(output_path_)
		else:
			_output_sheet_grouped_directional(output_path_)
	else:
		if "[[group]]" in output_path_:
			_output_sheet_split_tiled(output_path_)
		else:
			_output_sheet_grouped_tiled(output_path_)

func _output_sheet_frames() -> void:
	var output_path_: String = _get_output_path()
	var template_: Dictionary = _input_data["templates"][_config_data["template"]]

	var width_: int = _config_data.get("sheet_width", 0)
	var height_: int = _config_data.get("sheet_height", 0)
	var cols_: int = _config_data.get("sheet_cols", 0)
	var rows_: int = _config_data.get("sheet_rows", 0)

	_frame_index = _config_data.get("start_index", 0)
	var real_frame_index_: int = 0

	for frame_index_: int in template_["frames"].size():
		if width_ <= 0 and height_ <= 0 and rows_ <= 0 and cols_ <= 0:
			if "[[group]]" in output_path_:
				_output_sheet_split_directional(output_path_, real_frame_index_)
			else:
				_output_sheet_grouped_directional(output_path_, real_frame_index_)
		else:
			if "[[group]]" in output_path_:
				_output_sheet_split_tiled(output_path_, real_frame_index_)
			else:
				_output_sheet_grouped_tiled(output_path_, real_frame_index_)

		_frame_index += 1
		real_frame_index_ += 1

func _output_sheet_split_directional(output_path_: String, frame_index_: int = -1) -> void:
	var sheet_direction_: String = _config_data.get("sheet_direction", "horizontal")
	
	_variant_name = _input_name

	for group_name_: String in _input_data.get("groups", {}).keys():
		var group_data_: Dictionary = _input_data["groups"][group_name_]
		
		_group_name = group_name_
		
		_references = group_data_.get("references", {})

		var img_: Image = null
		
		for variant_name_: String in group_data_.get("variants", []):
			variant_name_ = _get_reference("*", variant_name_)
			
			if _input_data.get("skip", []).has(variant_name_):
				continue

			var variant_img_: Image = _get_image_from_variant(
				group_name_, 
				variant_name_, 
				frame_index_
			)
			
			if variant_img_ == null:
				continue

			if img_ == null:
				if _layer_map.has(variant_name_):
					_image_name = _layer_map[variant_name_].get_file().get_basename()
				else:
					_image_name = _input_data.get("paths")[0].get_file().get_basename()
				
				var size_with_padding_: Vector2i = _get_size_with_padding(
					_get_size_from_variant(variant_name_), 
					_get_padding()
				)
				_frame_width = size_with_padding_.x
				_frame_height = size_with_padding_.y
				
				img_ = variant_img_
				continue

			var new_size_: Vector2i
			var new_position_: Vector2i
			
			if sheet_direction_ == "horizontal":
				new_size_ = Vector2i(
					img_.get_width() + variant_img_.get_width(),
					max(img_.get_height(), variant_img_.get_height())
				)
				new_position_ = Vector2i(img_.get_width(), 0)
			else:
				new_size_ = Vector2i(
					max(img_.get_width(), variant_img_.get_width()),
					img_.get_height() + variant_img_.get_height()
				)
				new_position_ = Vector2i(0, img_.get_height())

			var new_img_: Image = Image.create_empty(
				new_size_.x, 
				new_size_.y, 
				false, 
				Image.FORMAT_RGBA8
			)
			
			new_img_.blit_rect(
				img_, 
				Rect2i(Vector2i.ZERO, img_.get_size()), 
				Vector2i.ZERO
			)
			
			new_img_.blit_rect(
				variant_img_, 
				Rect2i(Vector2i.ZERO, variant_img_.get_size()), 
				new_position_
			)
			
			img_ = new_img_

		if img_ == null:
			return

		_image_width = img_.get_width()
		_image_height = img_.get_height()

		var file_: String = _clean_path(output_path_)
		DirAccess.make_dir_recursive_absolute(file_.get_base_dir())
		img_.save_png(file_)

func _output_sheet_grouped_directional(output_path_: String, frame_index_: int = -1) -> void:
	var sheet_direction_: String = _config_data.get("sheet_direction", "horizontal")
	var group_padding_: bool = _config_data.get("group_padding", false)

	var img_: Image = null
	
	_variant_name = _input_name
	
	var first_group_: bool = true

	for group_name_: String in _input_data.get("groups", {}).keys():
		var group_data_: Dictionary = _input_data["groups"][group_name_]
		
		_group_name = group_name_
		
		_references = group_data_.get("references", {})

		var first_variant_: bool = true
		
		for variant_name_: String in group_data_.get("variants", []):
			variant_name_ = _get_reference("*", variant_name_)
			
			if _input_data.get("skip", []).has(variant_name_):
				continue

			var variant_img_: Image = _get_image_from_variant(
				group_name_, 
				variant_name_, 
				frame_index_
			)
			
			if variant_img_ == null:
				continue

			if img_ == null:
				if _layer_map.has(variant_name_):
					_image_name = _layer_map[variant_name_].get_file().get_basename()
				else:
					_image_name = _input_data.get("paths")[0].get_file().get_basename()
				
				var size_with_padding_: Vector2i = _get_size_with_padding(
					_get_size_from_variant(variant_name_), 
					_get_padding()
				)
				_frame_width = size_with_padding_.x
				_frame_height = size_with_padding_.y
				
				img_ = variant_img_
				continue

			if group_padding_ and not first_group_ and first_variant_:
				var frame_size_: Vector2i = _get_size_with_padding(
					_get_size_from_variant(variant_name_), 
					_get_padding()
				)
				var new_width_: int = img_.get_width()
				var new_height_: int = img_.get_height()
				
				if img_.get_width() % frame_size_.x != 0:
					new_width_ = ceil(img_.get_width() / float(frame_size_.x)) * frame_size_.x
					
				if img_.get_height() % frame_size_.y != 0:
					new_height_ = ceil(img_.get_height() / float(frame_size_.y)) * frame_size_.y
					
				if new_width_ != img_.get_width() or new_height_ != img_.get_height():
					@warning_ignore("confusable_local_declaration")
					var new_img_: Image = Image.create_empty(
						new_width_, 
						new_height_, 
						false, 
						Image.FORMAT_RGBA8
					)
					
					new_img_.blit_rect(
						img_, 
						Rect2i(Vector2i.ZERO, img_.get_size()), 
						Vector2i.ZERO
					)
					
					img_ = new_img_

			var new_size_: Vector2i
			var new_position_: Vector2i
			
			if sheet_direction_ == "horizontal":
				new_size_ = Vector2i(
					img_.get_width() + variant_img_.get_width(),
					max(img_.get_height(), variant_img_.get_height())
				)
				new_position_ = Vector2i(img_.get_width(), 0)
			else:
				new_size_ = Vector2i(
					max(img_.get_width(), variant_img_.get_width()),
					img_.get_height() + variant_img_.get_height()
				)
				new_position_ = Vector2i(0, img_.get_height())

			var new_img_: Image = Image.create_empty(
				new_size_.x, 
				new_size_.y, 
				false, 
				Image.FORMAT_RGBA8
			)
			
			new_img_.blit_rect(
				img_, 
				Rect2i(Vector2i.ZERO, img_.get_size()), 
				Vector2i.ZERO
			)
			
			new_img_.blit_rect(
				variant_img_, 
				Rect2i(Vector2i.ZERO, variant_img_.get_size()), 
				new_position_
			)
			
			img_ = new_img_

			first_variant_ = false
			
		first_group_ = false

	if img_ == null:
		return

	_image_width = img_.get_width()
	_image_height = img_.get_height()

	var file_: String = _clean_path(output_path_)
	DirAccess.make_dir_recursive_absolute(file_.get_base_dir())
	img_.save_png(file_)

func _output_sheet_split_tiled(output_path_: String, frame_index_: int = -1) -> void:
	_variant_name = _input_name

	var sheet_direction_: String = _config_data.get("sheet_direction", "horizontal")

	var frame_len_: int = 1
	if frame_index_ == -1:
		var template_: Dictionary = _input_data["templates"][_config_data["template"]]
		frame_len_ = template_["frames"].size()

	for group_name_: String in _input_data.get("groups", {}).keys():
		var group_data_: Dictionary = _input_data["groups"][group_name_]
		
		_group_name = group_name_
		
		_references = group_data_.get("references", {})

		var tiling_size_: Vector2i = _get_tiling_size(group_name_, frame_len_)
		
		if tiling_size_ == Vector2i.ZERO:
			continue

		var img_: Image = null
		var offset_x_: int = 0
		var offset_y_: int = 0

		var cols_: int = _config_data.get("sheet_cols", 0)
		var rows_: int = _config_data.get("sheet_rows", 0)

		for variant_name_: String in group_data_.get("variants", []):
			variant_name_ = _get_reference("*", variant_name_)
			
			if _input_data.get("skip", []).has(variant_name_):
				continue

			var variant_img_: Image = _get_image_from_variant(
				group_name_, 
				variant_name_, 
				frame_index_
			)
			
			if variant_img_ == null:
				continue

			if img_ == null:
				if _layer_map.has(variant_name_):
					_image_name = _layer_map[variant_name_].get_file().get_basename()
				else:
					_image_name = _input_data.get("paths")[0].get_file().get_basename()
				
				var size_with_padding_: Vector2i = _get_size_with_padding(
					_get_size_from_variant(variant_name_), 
					_get_padding()
				)
				_frame_width = size_with_padding_.x
				_frame_height = size_with_padding_.y

				if rows_ > 0 or cols_ > 0:
					img_ = Image.create_empty(
						variant_img_.get_width(), 
						variant_img_.get_height(), 
						false, 
						Image.FORMAT_RGBA8
					)
				elif tiling_size_.x > 0 and tiling_size_.y > 0:
					img_ = Image.create_empty(
						tiling_size_.x, 
						tiling_size_.y, 
						false, 
						Image.FORMAT_RGBA8
					)
				elif tiling_size_.x > 0:
					img_ = Image.create_empty(
						tiling_size_.x, 
						variant_img_.get_height(), 
						false, 
						Image.FORMAT_RGBA8
					)
				else:
					img_ = Image.create_empty(
						variant_img_.get_width(), 
						tiling_size_.y, 
						false, 
						Image.FORMAT_RGBA8
					)

				img_.blit_rect(
					variant_img_, 
					Rect2i(Vector2i.ZERO, variant_img_.get_size()), 
					Vector2i.ZERO
				)

				if sheet_direction_ == "horizontal":
					offset_x_ += variant_img_.get_width()
				else:
					offset_y_ += variant_img_.get_height()
					
				continue

			var new_width_: int = img_.get_width()
			var new_height_: int = img_.get_height()
			var new_size_: Vector2i = Vector2i.ZERO
			var new_position_: Vector2i = Vector2i.ZERO

			if sheet_direction_ == "horizontal":
				if offset_x_ + variant_img_.get_width() > tiling_size_.x:
					offset_x_ = 0
					offset_y_ += variant_img_.get_height()
				elif offset_x_ + variant_img_.get_width() > img_.get_width():
					new_width_ = offset_x_ + variant_img_.get_width()

				if offset_y_ + variant_img_.get_height() > img_.get_height():
					new_height_ = offset_y_ + variant_img_.get_height()

				if new_width_ != img_.get_width() or new_height_ != img_.get_height():
					new_size_ = Vector2i(new_width_, new_height_)

				new_position_ = Vector2i(offset_x_, offset_y_)
				
				offset_x_ += variant_img_.get_width()
			else:
				if offset_y_ + variant_img_.get_height() > tiling_size_.y:
					offset_y_ = 0
					offset_x_ += variant_img_.get_width()
				elif offset_y_ + variant_img_.get_height() > img_.get_height():
					new_height_ = offset_y_ + variant_img_.get_height()

				if offset_x_ + variant_img_.get_width() > img_.get_width():
					new_width_ = offset_x_ + variant_img_.get_width()

				if new_width_ != img_.get_width() or new_height_ != img_.get_height():
					new_size_ = Vector2i(new_width_, new_height_)

				new_position_ = Vector2i(offset_x_, offset_y_)
				offset_y_ += variant_img_.get_height()

			if new_size_ == Vector2i.ZERO:
				img_.blit_rect(
					variant_img_, 
					Rect2i(Vector2i.ZERO, variant_img_.get_size()), 
					new_position_
				)
			else:
				var new_img_: Image = Image.create_empty(
					new_size_.x, 
					new_size_.y, 
					false, 
					Image.FORMAT_RGBA8
				)
				
				new_img_.blit_rect(
					img_, 
					Rect2i(Vector2i.ZERO, img_.get_size()), 
					Vector2i.ZERO
				)
				new_img_.blit_rect(
					variant_img_, 
					Rect2i(Vector2i.ZERO, variant_img_.get_size()), 
					new_position_
				)
				
				img_ = new_img_

		if img_ == null:
			continue

		_image_width = img_.get_width()
		_image_height = img_.get_height()

		var file_: String = _clean_path(output_path_)
		DirAccess.make_dir_recursive_absolute(file_.get_base_dir())
		img_.save_png(file_)

func _output_sheet_grouped_tiled(output_path_: String, frame_index_: int = -1) -> void:
	var sheet_direction_: String = _config_data.get("sheet_direction", "horizontal")
	var group_padding_: bool = _config_data.get("group_padding", false)
	var continuous_: Variant = _config_data.get("continuous", false)

	var frame_len_: int = 1
	if frame_index_ == -1:
		var template_: Dictionary = _input_data["templates"][_config_data["template"]]
		frame_len_ = template_["frames"].size()
		
	var tiling_size_: Vector2i = _get_tiling_size("", frame_len_)
	if tiling_size_ == Vector2i.ZERO:
		return

	var img_: Image = null
	
	var offset_x_: int = 0
	var offset_y_: int = 0

	var cols_: int = _config_data.get("sheet_cols", 0)
	var rows_: int = _config_data.get("sheet_rows", 0)

	_variant_name = _input_name
	
	var last_img_: Image = null

	for group_name_: String in _input_data.get("groups", {}).keys():
		var group_data_: Dictionary = _input_data["groups"][group_name_]
		_group_name = group_name_
		
		_references = group_data_.get("references", {})

		var first_variant_: bool = true
		
		for variant_name_: String in group_data_.get("variants", []):
			variant_name_ = _get_reference("*", variant_name_)
			
			if _input_data.get("skip", []).has(variant_name_):
				continue

			var variant_img_: Image = _get_image_from_variant(
				group_name_, 
				variant_name_, 
				frame_index_
			)
			
			if variant_img_ == null:
				continue

			if img_ == null:
				if _layer_map.has(variant_name_):
					_image_name = _layer_map[variant_name_].get_file().get_basename()
				else:
					_image_name = _input_data.get("paths")[0].get_file().get_basename()
				
				var size_with_padding_: Vector2i = _get_size_with_padding(
					_get_size_from_variant(variant_name_), 
					_get_padding()
				)
				_frame_width = size_with_padding_.x
				_frame_height = size_with_padding_.y

				if rows_ > 0 or cols_ > 0:
					img_ = Image.create_empty(
						variant_img_.get_width(), 
						variant_img_.get_height(), 
						false, 
						Image.FORMAT_RGBA8
					)
				elif tiling_size_.x > 0 and tiling_size_.y > 0:
					img_ = Image.create_empty(
						tiling_size_.x, 
						tiling_size_.y, 
						false, 
						Image.FORMAT_RGBA8
					)
				elif tiling_size_.x > 0:
					img_ = Image.create_empty(
						tiling_size_.x, 
						variant_img_.get_height(), 
						false, 
						Image.FORMAT_RGBA8
					)
				else:
					img_ = Image.create_empty(
						variant_img_.get_width(), 
						tiling_size_.y, 
						false, 
						Image.FORMAT_RGBA8
					)
				
				img_.blit_rect(
					variant_img_, 
					Rect2i(Vector2i.ZERO, variant_img_.get_size()), 
					Vector2i.ZERO
				)

				if sheet_direction_ == "horizontal":
					offset_x_ += variant_img_.get_width()
				else:
					offset_y_ += variant_img_.get_height()

				last_img_ = variant_img_
				
				first_variant_ = false
				continue

			var group_continuous_: bool = false
			if continuous_ is bool:
				group_continuous_ = continuous_
			elif continuous_ is Array and continuous_.has(group_name_):
				group_continuous_ = true

			if group_continuous_ and not group_data_.get("break", false) and first_variant_:
				if sheet_direction_ == "horizontal":
					if variant_img_.get_height() != last_img_.get_height():
						offset_x_ = 0
						offset_y_ += last_img_.get_height()
					elif group_padding_:
						var frame_size_: Vector2i = _get_size_with_padding(
							_get_size_from_variant(variant_name_), 
							_get_padding()
						)
						
						if offset_x_ % frame_size_.x != 0:
							offset_x_ = int(ceil(offset_x_ / float(frame_size_.x))) * frame_size_.x
				else:
					if variant_img_.get_width() != last_img_.get_width():
						offset_x_ += last_img_.get_width()
						offset_y_ = 0
					elif group_padding_:
						var frame_size_: Vector2i = _get_size_with_padding(
							_get_size_from_variant(variant_name_), 
							_get_padding()
						)
						
						if offset_y_ % frame_size_.y != 0:
							offset_y_ = int(ceil(offset_y_ / float(frame_size_.y))) * frame_size_.y
			elif first_variant_:
				if sheet_direction_ == "horizontal":
					offset_x_ = 0
					offset_y_ += last_img_.get_height()
				else:
					offset_x_ += last_img_.get_width()
					offset_y_ = 0

			first_variant_ = false

			var new_width_: int = img_.get_width()
			var new_height_: int = img_.get_height()
			var new_size_: Vector2i = Vector2i.ZERO
			var new_position_: Vector2i = Vector2i.ZERO

			if sheet_direction_ == "horizontal":
				if offset_x_ + variant_img_.get_width() > tiling_size_.x:
					offset_x_ = 0
					offset_y_ += variant_img_.get_height()
				elif offset_x_ + variant_img_.get_width() > img_.get_width():
					new_width_ = offset_x_ + variant_img_.get_width()

				if offset_y_ + variant_img_.get_height() > img_.get_height():
					new_height_ = offset_y_ + variant_img_.get_height()

				if new_width_ != img_.get_width() or new_height_ != img_.get_height():
					new_size_ = Vector2i(new_width_, new_height_)

				new_position_ = Vector2i(offset_x_, offset_y_)
				
				offset_x_ += variant_img_.get_width()
			else:
				if offset_y_ + variant_img_.get_height() > tiling_size_.y:
					offset_y_ = 0
					offset_x_ += variant_img_.get_width()
				elif offset_y_ + variant_img_.get_height() > img_.get_height():
					new_height_ = offset_y_ + variant_img_.get_height()

				if offset_x_ + variant_img_.get_width() > img_.get_width():
					new_width_ = offset_x_ + variant_img_.get_width()

				if new_width_ != img_.get_width() or new_height_ != img_.get_height():
					new_size_ = Vector2i(new_width_, new_height_)

				new_position_ = Vector2i(offset_x_, offset_y_)
				offset_y_ += variant_img_.get_height()

			if new_size_ == Vector2i.ZERO:
				img_.blit_rect(
					variant_img_, 
					Rect2i(Vector2i.ZERO, variant_img_.get_size()), 
					new_position_
				)
			else:
				var new_img_: Image = Image.create_empty(
					new_size_.x, 
					new_size_.y, 
					false, 
					Image.FORMAT_RGBA8
				)
				new_img_.blit_rect(
					img_, 
					Rect2i(Vector2i.ZERO, img_.get_size()), 
					Vector2i.ZERO
				)
				
				new_img_.blit_rect(
					variant_img_, 
					Rect2i(Vector2i.ZERO, variant_img_.get_size()), 
					new_position_
				)
				
				img_ = new_img_

			last_img_ = variant_img_

	if img_ == null:
		return

	_image_width = img_.get_width()
	_image_height = img_.get_height()

	var file_: String = _clean_path(output_path_)
	DirAccess.make_dir_recursive_absolute(file_.get_base_dir())
	img_.save_png(file_)

func _get_image_from_variant(group_name_: String, variant_name_: String, frame_index_: int = -1) -> Image:
	var template_: Dictionary = _input_data["templates"][_config_data["template"]]
	
	var frames_: Array 
	
	if frame_index_ == -1:
		frames_ = template_["frames"] 
	else:
		frames_ = [template_["frames"][frame_index_]]
	
	frames_ = _get_frames(group_name_, variant_name_, frames_)

	var variant_size_: Vector2i = _get_size_from_variant(variant_name_)
	
	if variant_size_ == Vector2i.ZERO:
		return null

	var frame_direction_: String = _config_data.get("frame_direction", "horizontal")
	var padding_: PackedInt32Array = _get_padding()

	var img_size_: Vector2i = _get_size_from_config(
		variant_size_,
		padding_,
		frames_.size()
	)
	
	var img_: Image = Image.create_empty(
		img_size_.x, 
		img_size_.y, 
		false, 
		Image.FORMAT_RGBA8
	)

	var row_: int = 0
	var col_: int = 0
	
	var padding_x_: int = 0
	var padding_y_: int = 0

	if frame_direction_ == "horizontal":
		padding_y_ = padding_[0]
	else:
		padding_x_ = padding_[3]

	for frame_: Array in frames_:
		var variant_img_: Image = null

		if frame_direction_ == "horizontal":
			padding_x_ += padding_[3]
		else:
			padding_y_ += padding_[0]

		for frame_layer_: Dictionary in frame_:
			if frame_layer_.get("layer", "*") == "*":
				variant_img_ = _get_layer_image(variant_name_)
			else:
				variant_img_ = _get_layer_image(
					_get_reference(frame_layer_.get("layer", "*"), variant_name_)
				)

			if variant_img_ == null:
				continue

			variant_img_ = _process_image(
				variant_img_, 
				frame_layer_.get("alpha", 1.0),
				frame_layer_.get("transforms", [])
			)

			var offset_: Vector2i = Vector2i(
				frame_layer_.get("offset", [0, 0])[0],
				frame_layer_.get("offset", [0, 0])[1]
			)

			var position_: Vector2i = Vector2i(
				(col_ * variant_size_.x) + offset_.x + padding_x_,
				(row_ * variant_size_.y) + offset_.y + padding_y_
			)
			
			img_ = _paste_image(img_, variant_img_, position_)

		if frame_direction_ == "horizontal":
			padding_x_ += padding_[1]
			
			col_ += 1
			if col_ * variant_size_.x > img_size_.x:
				col_ = 0
				row_ += 1
		else:
			padding_y_ += padding_[2]
			
			row_ += 1
			if row_ * variant_size_.y > img_size_.y:
				row_ = 0
				col_ += 1

	return img_

func _process_image(img_: Image, alpha_: float = 1.0, transforms_: Array = []) -> Image:
	var color_map_: Array[Dictionary] = _get_color_map()
	
	img_ = _replace_colors(img_, color_map_, alpha_)
	
	for transform_: String in transforms_:
		if transform_ == "trim":
			var trim_rect_: Rect2i = img_.get_used_rect()
			img_ = img_.get_region(trim_rect_)
		elif transform_ == "flip_h":
			img_.flip_x()
		elif transform_ == "flip_v":
			img_.flip_y()
		elif transform_ == "rotate_right":
			img_.rotate_90(ClockDirection.CLOCKWISE)
		elif transform_ == "rotate_left":
			img_.rotate_90(ClockDirection.COUNTERCLOCKWISE)

	return img_

func _get_color_map() -> Array[Dictionary]:
	var map_: Array[Dictionary] = []
	
	var input_colors_: Dictionary = _input_data.get("colors", {})

	if input_colors_.is_empty():
		return map_
		
	var group_colors_: Dictionary = _input_data.get("groups", {}).get(_group_name, {}).get("colors", {})
		
	for color_name_: String in input_colors_.keys():
		var input_color_: String = input_colors_.get(color_name_, "")
		
		var output_color_: String = input_colors_.get(color_name_)
		
		if group_colors_.has(color_name_):
			output_color_ = _theme_data.get(group_colors_.get(color_name_), output_color_)
		else:
			output_color_ = _theme_data.get(color_name_, output_color_)
		
		map_.append({
			"from": Color(input_color_),
			"to": Color(output_color_),
			"from_alpha": input_color_.lstrip("#").length() == 8,
			"to_alpha": output_color_.lstrip("#").length() == 8,
		})

	return map_

#func _hex_to_color(hex_color_: String) -> Color:
	#hex_color_ = hex_color_.lstrip("#").to_upper()
	#
	#if hex_color_.length() == 6:
		#hex_color_ += "FF"
	#
	#return Color(hex_color_)

func _replace_colors(img_: Image, color_map_: Array[Dictionary], alpha_: float) -> Image:
	var width_: int = img_.get_width()
	var height_: int = img_.get_height()

	for x_: int in width_:
		for y_: int in height_:
			var pixel_: Color = img_.get_pixel(x_, y_)

			for map_: Dictionary in color_map_:
				if (pixel_.r8 != map_.from.r8 ||
					pixel_.g8 != map_.from.g8 ||
					pixel_.b8 != map_.from.b8
				):
					continue
					
				if map_.from_alpha && pixel_.a8 != map_.from.a8:
					continue
				
				var new_color_: Color = Color(map_.to)
				
				if not map_.to_alpha:
					new_color_.a8 = pixel_.a8
				
				new_color_.a8 = roundi(float(new_color_.a8) * alpha_)
				
				img_.set_pixel(x_, y_, new_color_)
				break

	return img_

func _paste_image(img_: Image, variant_img_: Image, position_: Vector2i) -> Image:
	var img_size_: Vector2i = Vector2i(img_.get_size())
	var variant_img_size_: Vector2i = Vector2i(variant_img_.get_size())

	var layer_img_: Image = Image.create_empty(
		img_size_.x, 
		img_size_.y, 
		false, 
		Image.FORMAT_RGBA8
	)
	
	layer_img_.blit_rect(
		variant_img_, 
		Rect2i(Vector2i.ZERO, variant_img_size_), 
		position_
	)

	for y_: int in img_size_.y:
		for x_: int in img_size_.x:
			var bg_: Color = img_.get_pixel(x_, y_)
			var fg_: Color = layer_img_.get_pixel(x_, y_)

			var a_fg_: float = fg_.a
			var a_bg_: float = bg_.a * (1.0 - a_fg_)
			var out_a_: float = a_fg_ + a_bg_

			var out_r_: float = fg_.r * a_fg_ + bg_.r * a_bg_
			var out_g_: float = fg_.g * a_fg_ + bg_.g * a_bg_
			var out_b_: float = fg_.b * a_fg_ + bg_.b * a_bg_

			if out_a_ > 0.0:
				img_.set_pixel(
					x_, 
					y_, 
					Color(
						out_r_ / out_a_, 
						out_g_ / out_a_, 
						out_b_ / out_a_, 
						out_a_
					)
				)
			else:
				img_.set_pixel(x_, y_, Color(0, 0, 0, 0))

	return img_

func _get_layer_image(layer_name_: String) -> Image:
	var path_: String = _layer_map.get(layer_name_, "")
	
	if path_.is_empty():
		return null

	var layers_: Array = _get_layers_from_ora(path_)
	
	for layer_: Array in layers_:
		if layer_[0] == layer_name_:
			var zip_: ZIPReader = ZIPReader.new()
			if zip_.open(path_) != OK:
				return null
				
			var data_: PackedByteArray = zip_.read_file(layer_[1])
			
			zip_.close()
			
			var img_: Image = Image.new()
			img_.load_png_from_buffer(data_)
			return img_
			
	return null

func _get_layers_from_ora(path_: String) -> Array:
	if _ora_layers.has(path_):
		return _ora_layers.get(path_)

	var layers_: Array = []
	
	var zip_: ZIPReader = ZIPReader.new()
	if zip_.open(path_) != OK:
		return layers_

	var stack_data_: PackedByteArray = zip_.read_file("stack.xml")
	
	zip_.close()

	var xml_: XMLParser = XMLParser.new()
	xml_.open_buffer(stack_data_)

	while xml_.read() == OK:
		if (xml_.get_node_type() == XMLParser.NODE_ELEMENT and 
			xml_.get_node_name().ends_with("layer")
		):
			var name_: String = xml_.get_named_attribute_value_safe("name")
			var src_: String = xml_.get_named_attribute_value_safe("src")
			
			if not name_.is_empty() and not src_.is_empty():
				layers_.append([name_, src_])

	_ora_layers[path_] = layers_
	
	return layers_

func _get_size_from_variant(variant_name_: String) -> Vector2i:
	for group_name_: String in _input_data.get("groups", {}).keys():
		var group_data_: Dictionary = _input_data["groups"][group_name_]
		
		if group_data_.get("variants", []).has(variant_name_) and group_data_.has("size"):
			return Vector2i(group_data_["size"][0], group_data_["size"][1])

	if not _layer_map.has(variant_name_):
		_errors.append("Variant not found. (%s)" % variant_name_)
		return Vector2i.ZERO

	return _get_size_from_ora(_layer_map[variant_name_])

func _get_size_from_ora(path_: String) -> Vector2i:
	if _ora_size.has(path_):
		return _ora_size[path_]

	var zip_: ZIPReader = ZIPReader.new()
	if zip_.open(path_) != OK:
		return Vector2i.ZERO

	if zip_.file_exists("mergedimage.png"):
		var data_: PackedByteArray = zip_.read_file("mergedimage.png")
		
		zip_.close()
		
		var img_: Image = Image.new()
		img_.load_png_from_buffer(data_)
		
		_ora_size[path_] = Vector2i(img_.get_width(), img_.get_height())
		
		return _ora_size[path_]

	for file_name: String in zip_.get_files():
		if file_name.begins_with("data/") and file_name.ends_with(".png"):
			var data_: PackedByteArray = zip_.read_file(file_name)
			
			zip_.close()
			
			var img_: Image = Image.new()
			img_.load_png_from_buffer(data_)
			
			_ora_size[path_] = Vector2i(img_.get_width(), img_.get_height())
			
			return _ora_size[path_]

	zip_.close()
	
	_ora_size[path_] = Vector2i.ZERO
	
	return Vector2i.ZERO

func _get_size_from_config(
	ora_size_: Vector2i, 
	padding_: PackedInt32Array, 
	frame_len_: int
) -> Vector2i:
	var mode_: String = _config_data.get("mode", "images")
	
	var real_size_: Vector2i = _get_size_with_padding(ora_size_, padding_)

	if mode_ == "frames":
		return real_size_

	var frame_direction_: String = _config_data.get("frame_direction", "horizontal")

	var width_: int = _config_data.get("frame_width", 0)
	var height_: int = _config_data.get("frame_height", 0)
	var cols_: int = _config_data.get("frame_cols", 0)
	var rows_: int = _config_data.get("frame_rows", 0)

	if width_ <= 0 and height_ <= 0 and rows_ <= 0 and cols_ <= 0:
		if frame_direction_ == "horizontal":
			return Vector2i(real_size_.x * frame_len_, real_size_.y)
		else:
			return Vector2i(real_size_.x, real_size_.y * frame_len_)

	var frame_cols_: int = 0
	var frame_rows_: int = 0

	if width_ <= 0 and height_ <= 0:
		if rows_ > 0:
			if cols_ > 0:
				if frame_direction_ == "horizontal":
					frame_cols_ = min(cols_, frame_len_)
					frame_rows_ = int(ceil(frame_len_ / float(cols_)))
				else:
					frame_cols_ = int(ceil(frame_len_ / float(rows_)))
					frame_rows_ = min(cols_, frame_len_)
			else:
				frame_cols_ = int(ceil(frame_len_ / float(rows_)))
				frame_rows_ = min(cols_, frame_len_)
		else:
			frame_cols_ = min(cols_, frame_len_)
			frame_rows_ = int(ceil(frame_len_ / float(cols_)))
			
		return Vector2i(real_size_.x * frame_cols_, real_size_.y * frame_rows_)
	
	if width_ > 0 and height_ > 0:
		if frame_direction_ == "horizontal":
			frame_cols_ = int(floor(width_ / float(real_size_.x)))
			frame_rows_ = int(ceil(frame_len_ / float(frame_cols_)))
		else:
			frame_cols_ = int(floor(height_ / float(real_size_.y)))
			frame_rows_ = int(ceil(frame_len_ / float(frame_cols_)))
	elif width_ > 0:
		frame_cols_ = int(floor(width_ / float(real_size_.x)))
		frame_rows_ = int(ceil(frame_len_ / float(frame_cols_)))
	else:
		frame_rows_ = int(floor(height_ / float(real_size_.y)))
		frame_cols_ = int(ceil(frame_len_ / float(frame_rows_)))

	return Vector2i(real_size_.x * frame_cols_, real_size_.y * frame_rows_)

func _get_padding() -> PackedInt32Array:
	var padding_: Variant = _config_data.get("padding", 0)
	
	if _options.get("padding", -1) != -1:
		padding_ = _options.get("padding")
	
	if padding_ is int:
		return PackedInt32Array([padding_, padding_, padding_, padding_])
	elif padding_ is Array:
		match padding_.size():
			2: return PackedInt32Array([padding_[0], padding_[1], padding_[0], padding_[1]])
			3: return PackedInt32Array([padding_[0], padding_[1], padding_[2], padding_[1]])
			4: return PackedInt32Array(padding_)
			_: 
				_errors.append("Invalid padding. (%s)" % _output_name)
				return PackedInt32Array([0, 0, 0, 0])
	else:
		_errors.append("Invalid padding. (%s)" % _output_name)
		return PackedInt32Array([0, 0, 0, 0])

func _get_size_with_padding(
	size_: Vector2i, 
	padding_: PackedInt32Array, 
	frames_: int = 1
) -> Vector2i:
	var new_size_: Vector2i = Vector2i(
		size_.x + padding_[1] + padding_[3], 
		size_.y + padding_[0] + padding_[2]
	)

	if frames_ > 1:
		var frame_direction_: String = _config_data.get("frame_direction", "horizontal")
		
		if frame_direction_ == "horizontal":
			new_size_ = Vector2i(
				new_size_.x * frames_, 
				new_size_.y
			)
		else:
			new_size_ = Vector2i(
				new_size_.x, 
				new_size_.y * frames_
			)

	return new_size_

func _get_tiling_size(group_name_: String = "", frame_len_: int = 1) -> Vector2i:
	var width_: int = _config_data.get("sheet_width", 0)
	var height_: int = _config_data.get("sheet_height", 0)
	var cols_: int = _config_data.get("sheet_cols", 0)
	var rows_: int = _config_data.get("sheet_rows", 0)

	if width_ <= 0 and height_ <= 0 and rows_ <= 0 and cols_ <= 0:
		return Vector2i.ZERO

	var min_size_: Vector2i = _get_min_group_size(group_name_, frame_len_, false)

	if width_ > 0:
		if height_ > 0:
			return Vector2i(max(width_, min_size_.x), max(height_, min_size_.y))
		else:
			return Vector2i(max(width_, min_size_.x), 0)
	elif height_ > 0:
		return Vector2i(0, max(height_, min_size_.y))

	var first_min_size_: Vector2i = _get_min_group_size(group_name_, frame_len_, true)

	if cols_ > 0:
		if rows_ > 0:
			return Vector2i(
				max(cols_ * first_min_size_.x, min_size_.x),
				max(rows_ * first_min_size_.y, min_size_.y)
			)
		else:
			return Vector2i(max(cols_ * first_min_size_.x, min_size_.x), 0)
	else:
		return Vector2i(0, max(rows_ * first_min_size_.y, min_size_.y))

func _get_min_group_size(
	group_name_: String = "", 
	frame_len_: int = 1, 
	first_: bool = false
) -> Vector2i:
	var width_:  int = 0
	var height_: int = 0

	for current_group_name_: String in _input_data.get("groups", {}).keys():
		if group_name_ != "" and group_name_ != current_group_name_:
			continue

		var group_data_: Dictionary = _input_data["groups"][current_group_name_]
		
		_references = group_data_.get("references", {})

		for variant_name_: String in group_data_.get("variants", []):
			variant_name_ = _get_reference("*", variant_name_)

			if _input_data.get("skip", []).has(variant_name_):
				continue

			var variant_size_: Vector2i = _get_size_from_variant(variant_name_)
			
			if variant_size_ == Vector2i.ZERO:
				continue

			variant_size_ = _get_size_with_padding(
				variant_size_,
				_get_padding(),
				frame_len_
			)

			if variant_size_.x > width_:
				width_ = variant_size_.x
				
			if variant_size_.y > height_:
				height_ = variant_size_.y

			break

		if first_ and (width_ > 0 or height_ > 0):
			break

	return Vector2i(width_, height_)
	
func _get_reference(layer_name_: String, variant_name_: String) -> String:
	var ref_: Variant = _references.get(layer_name_, layer_name_)
	
	if ref_ is Dictionary:
		if ref_.has(variant_name_):
			ref_ = ref_.get(variant_name_)
		else:
			var result_: String = layer_name_

			for s: String in ref_:
				if not s.begins_with("/") or not s.ends_with("/"):
					continue

				var pattern_: String = s.substr(1, s.length() - 2)

				var regex_: RegEx = RegEx.new()
				
				if regex_.compile(pattern_) != OK:
					continue

				var match_: RegExMatch = regex_.search(variant_name_)
				if match_ == null:
					continue

				result_ = ref_.get(s, layer_name_)

				for i: int in range(1, match_.get_group_count() + 1):
					result_ = result_.replace(
						"$" + str(i), 
						match_.get_string(i)
					)

				break
			
			ref_ = result_
	
	if ref_ == "*":
		return variant_name_
	
	return ref_

func _get_frames(group_name_: String, variant_name_: String, frames_: Array) -> Array:
	var frame_references_: Dictionary = _input_data.get("frames", {})
	
	var new_frames_: Array = []

	for frame_: Array in frames_:
		var new_frame_layers_: Array = []
		
		for frame_layer_: Variant in frame_:
			if frame_layer_ is String:
				if not frame_references_.has(frame_layer_):
					new_frame_layers_.append({"layer": frame_layer_})
					continue
				
				for frame_reference_: Dictionary in frame_references_[frame_layer_]:
					if (frame_reference_.get("groups", null) != null and
						not _matches_values(
							group_name_,
							frame_reference_.get("groups", [])
						)
					):
						continue
					
					if (frame_reference_.get("variants", null) != null and
						not _matches_values(
							variant_name_,
							frame_reference_.get("variants", [])
						)
					):
						continue
						
					new_frame_layers_.append({
						"layer": frame_reference_.get("layer", "*"),
						"offset": frame_reference_.get("offset", [0, 0]),
						"alpha": frame_reference_.get("alpha", 1.0),
						"transforms": frame_reference_.get("transforms", [])
					})
			else:
				if (frame_layer_.get("groups", null) != null and
					not _matches_values(
						group_name_,
						frame_layer_.get("groups", [])
					)
				):
					continue
					
				if (frame_layer_.get("variants", null) != null and
					not _matches_values(
						variant_name_,
						frame_layer_.get("variants", [])
					)
				):
					continue
					
				new_frame_layers_.append({
					"layer": frame_layer_.get("layer", "*"),
					"offset": frame_layer_.get("offset", [0, 0]),
					"alpha": frame_layer_.get("alpha", 1.0),
					"transforms": frame_layer_.get("transforms", [])
				})
				
		new_frames_.append(new_frame_layers_)
		
	return new_frames_

func _matches_values(s: String, values: Array) -> bool:
	if values.has(s):
		return true
	
	for value: String in values:
		if value.begins_with("/") and value.ends_with("/"):
			var pattern: String = value.substr(1, value.length() - 2)
			var regex: RegEx = RegEx.new()
			if regex.compile(pattern) == OK:
				var match_: RegExMatch = regex.search(s)
				if match_ != null:
					return true
		
		var parts: PackedStringArray = value.split("*", true, 1)
		if parts.size() == 2 and s.begins_with(parts[0]) and s.ends_with(parts[1]):
			return true
	
	return false

func _clean_path(s_: String) -> String:
	var replace_: Dictionary = {
		"[[name]]": _clean_value(_name),
		"[[version]]": _clean_value(_version),
		"[[theme]]": _clean_value(_theme_name),
		"[[variant]]": _clean_value(_variant_name),
		"[[input]]": _clean_value(_input_name),
		"[[output]]": _clean_value(_output_name),
		"[[image]]": _clean_value(_image_name),
		"[[group]]": _clean_value(_group_name),
		"[[template]]": _clean_value(_config_data["template"]),
		"[[mode]]": _config_data.get("mode", "images"),
		"[[sheet_direction]]": _config_data.get("sheet_direction", "horizontal"),
		"[[frame_direction]]": _config_data.get("frame_direction", "horizontal"),
		"[[frame]]": str(_frame_index),
		"[[frame_width]]": str(_frame_width),
		"[[frame_height]]": str(_frame_height),
		"[[image_width]]": str(_image_width),
		"[[image_height]]": str(_image_height),
		
		"[[^name]]": _clean_value(_name, true),
		"[[^version]]": _clean_value(_version, true),
		"[[^theme]]": _clean_value(_theme_name, true),
		"[[^variant]]": _clean_value(_variant_name, true),
		"[[^input]]": _clean_value(_input_name, true),
		"[[^output]]": _clean_value(_output_name, true),
		"[[^image]]": _clean_value(_image_name, true),
		"[[^group]]": _clean_value(_group_name, true),
		"[[^template]]": _clean_value(_config_data["template"], true),
		"[[^mode]]": _config_data.get("mode", "images").replace("_", " ").capitalize(),
		"[[^sheet_direction]]": _config_data.get("sheet_direction", "horizontal").capitalize(),
		"[[^frame_direction]]": _config_data.get("frame_direction", "horizontal").capitalize(),
		"[[^frame]]": str(_frame_index),
		"[[^frame_width]]": str(_frame_width),
		"[[^frame_height]]": str(_frame_height),
		"[[^image_width]]": str(_image_width),
		"[[^image_height]]": str(_image_height),
	}
	
	for key_: String in replace_.keys():
		s_ = s_.replace(key_, replace_[key_])
		
	return s_
	
func _clean_value(value_: String, title_: bool = false) -> String:
	if not title_:
		value_ = value_.to_lower()
	
	var regex_: RegEx = RegEx.new()
	
	regex_.compile("[^a-zA-Z0-9-_ /.()\\[\\]]")
	value_ = regex_.sub(value_, "", true)
	
	if title_:
		regex_.compile("[_]")
		value_ = regex_.sub(value_, " ", true)
		
		regex_.compile(" +")
		value_ = regex_.sub(value_, " ", true)
		
		value_ = value_.lstrip(" ").rstrip(" ")
	else:
		regex_.compile("[- ()\\[\\]]")
		value_ = regex_.sub(value_, "_", true)
		
		regex_.compile("_+")
		value_ = regex_.sub(value_, "_", true)
		
		value_ = value_.lstrip("_").rstrip("_")
	
	return value_

func _load_config(path_: String) -> Dictionary:
	var file_: FileAccess = FileAccess.open(path_, FileAccess.READ)
	if file_ == null:
		_errors.append("Cannot open config (%s)." % path_)
		return {}
		
	var config_json_: String = file_.get_as_text()
	
	file_.close()
	
	var json_: JSON = JSON.new()

	if json_.parse(config_json_) != OK:
		_errors.append("JSON parse error (%s)." % path_)
		return {}
		
	return json_.data as Dictionary

func _load_layer_map(path_: String) -> void:
	var layers_: Array = _get_layers_from_ora(path_)

	for layer_: Array in layers_:
		_layer_map[layer_[0]] = path_
