@tool
extends Control

var _file_dialog: EditorFileDialog
var _folder_dialog: EditorFileDialog

@onready var _header_labels: Array[Label] = [
	%LabelConfigurations,
	%LabelInputs,
	%LabelOutputs,
	%LabelGenerate,
	%LabelPath,
]

var _configs: Array[RetrogradeImageConfig] = []
var _selected_index: int = -1
var _save: RetrogradeImageSave = RetrogradeImageSave.new()

func _notification(what: int) -> void:
	# Prevent theme from being saved to scene
	match what:
		NOTIFICATION_READY, NOTIFICATION_THEME_CHANGED:
			_add_theme()
		NOTIFICATION_EDITOR_PRE_SAVE:
			_remove_theme()
			_remove_configs()
		NOTIFICATION_EDITOR_POST_SAVE:
			_add_theme()
			_add_configs()

func _add_theme() -> void:
	var theme_: Theme = EditorInterface.get_editor_theme()
	
	#for label_: Label in _subheader_labels:
		#label_.add_theme_font_override("font", theme_.get_font("bold", "EditorFonts"))
		
	for label_: Label in _header_labels:
		label_.add_theme_font_override("font", theme_.get_font("title", "EditorFonts"))
		label_.add_theme_font_size_override("font_size", theme_.get_font_size("title_size", "EditorFonts"))
		label_.add_theme_color_override("font_color", theme_.get_color("font_color", "Editor"))
		
	%ButtonAddConfig.icon = theme_.get_icon("Add", "EditorIcons")
	%ButtonRemoveConfig.icon = theme_.get_icon("Remove", "EditorIcons")
	%ButtonSelectAllInputs.icon = theme_.get_icon("ListSelect", "EditorIcons")
	%ButtonSelectAllOutputs.icon = theme_.get_icon("ListSelect", "EditorIcons")
	%ButtonGenerate.icon = theme_.get_icon("Bake", "EditorIcons")
	%ButtonSelectOutputPath.icon = theme_.get_icon("Folder", "EditorIcons")

func _remove_theme() -> void:
	for label_: Label in _header_labels:
		label_.remove_theme_font_override("font")
		label_.remove_theme_font_size_override("font_size")
		label_.remove_theme_color_override("font_color")
		
	%ButtonAddConfig.icon = null
	%ButtonRemoveConfig.icon = null
	%ButtonSelectAllInputs.icon = null
	%ButtonSelectAllOutputs.icon = null
	%ButtonGenerate.icon = null
	%ButtonSelectOutputPath.icon = null
	
func _ready() -> void:
	_file_dialog = EditorFileDialog.new()
	_file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.current_dir = "res://"
	_file_dialog.add_filter("*.json; Retrograde Image JSON")
	_file_dialog.connect("file_selected", _on_file_selected)
	add_child(_file_dialog)
	
	_folder_dialog = EditorFileDialog.new()
	_folder_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_folder_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	_folder_dialog.current_dir = "res://"
	_folder_dialog.connect("dir_selected", _on_folder_selected)
	add_child(_folder_dialog)
	
	_save.load()
	
	_add_configs()

func _add_configs() -> void:
	for path_: String in _save.get_config_paths():
		_add_config(path_)
		
	_update_configs_list()
	_select_configuration(_get_config_index_from_path(_save.get_selected_config_path()))

func _remove_configs() -> void:
	_configs.clear()
	_update_configs_list()
	_select_configuration(-1)

func _on_file_selected(path_: String) -> void:
	_add_config(path_)
	_update_configs_list()
	_select_configuration(_get_config_index_from_path(path_))
	save_selected_config()

func _on_folder_selected(path_: String) -> void:
	%LineEditOutputPath.text = path_

func _on_button_add_config_pressed() -> void:
	_file_dialog.popup_file_dialog()
	
func _on_button_remove_config_pressed() -> void:
	_remove_configuration(_selected_index)

func _on_item_list_configs_item_selected(index: int) -> void:
	_select_configuration(index)

func _add_config(path_: String) -> void:
	var config_: RetrogradeImageConfig = RetrogradeImageConfig.new(path_)
	config_.load()

	if config_.is_empty():
		return

	for item_: RetrogradeImageConfig in _configs:
		if item_.path == path_:
			return

	_configs.push_back(config_)
	_configs.sort_custom(_sort_configs_callback)
		
func _sort_configs_callback(a: RetrogradeImageConfig, b: RetrogradeImageConfig) -> bool:
	return a.get_name().naturalnocasecmp_to(b.get_name()) < 0
	
func _update_configs_list() -> void:
	%ItemListConfigs.clear()
	
	for config_: RetrogradeImageConfig in _configs:
		%ItemListConfigs.add_item(config_.get_name() + " (" + config_.get_version() + ")")

func _get_config_index_from_path(path_: String) -> int:
	if _configs.size() == 0:
		return -1
		
	for index_: int in _configs.size():
		if _configs[index_].path == path_:
			return index_
	
	return 0

func _select_configuration(index_: int) -> void:
	_selected_index = index_
		
	while %VBoxContainerInputs.get_child_count() > 0:
		%VBoxContainerInputs.remove_child(%VBoxContainerInputs.get_child(0))
		
	while %VBoxContainerOutputs.get_child_count() > 0:
		%VBoxContainerOutputs.remove_child(%VBoxContainerOutputs.get_child(0))
		
	%OptionButtonTheme.clear()
	
	if index_ < 0:
		%LineEditOutputPath.text = "res://assets"
		%SpinBoxPadding.value = -1.0
		%CheckBoxIgnoreOutputPath.button_pressed = false
		%CheckBoxIgnoreOutputConfigPath.button_pressed = false
		
		%ButtonRemoveConfig.disabled = true
		%ButtonSelectOutputPath.disabled = true
		%ButtonSelectAllInputs.disabled = true
		%ButtonSelectAllOutputs.disabled = true
		%CheckBoxIgnoreOutputPath.disabled = true
		%CheckBoxIgnoreOutputConfigPath.disabled = true
		%LineEditOutputPath.editable = false
		%SpinBoxPadding.editable = false
		%OptionButtonTheme.disabled = true
		%ButtonGenerate.disabled = true
		return
		
	%ItemListConfigs.select(index_)
	
	%ButtonRemoveConfig.disabled = false
	%ButtonSelectOutputPath.disabled = false
	%ButtonSelectAllInputs.disabled = false
	%ButtonSelectAllOutputs.disabled = false
	%CheckBoxIgnoreOutputPath.disabled = false
	%CheckBoxIgnoreOutputConfigPath.disabled = false
	%LineEditOutputPath.editable = true
	%SpinBoxPadding.editable = true
	%OptionButtonTheme.disabled = false
	%ButtonGenerate.disabled = true
	
	var config_: RetrogradeImageConfig = _configs[index_]

	var save_data_: Dictionary = _save.get_config_data(config_.path)

	var inputs_: Array = config_.get_inputs()
	
	for i: int in inputs_.size():
		var check_box_: CheckBox = CheckBox.new()
		check_box_.text = inputs_[i]
		if save_data_.get("inputs", []).has(inputs_[i]):
			check_box_.button_pressed = true
		check_box_.toggled.connect(_on_check_box_toggled)
		%VBoxContainerInputs.add_child(check_box_)
		
	var outputs_: Array = config_.get_outputs()
	
	for i: int in outputs_.size():
		var check_box_: CheckBox = CheckBox.new()
		check_box_.text = outputs_[i]
		if save_data_.get("outputs", []).has(outputs_[i]):
			check_box_.button_pressed = true
			%ButtonGenerate.disabled = false
		check_box_.toggled.connect(_on_check_box_toggled)
		%VBoxContainerOutputs.add_child(check_box_)
		
	var themes_: Array = config_.get_themes()
	var theme_index_: int = 0
		
	for i: int in themes_.size():
		%OptionButtonTheme.add_item(themes_[i])
		if save_data_.get("theme", "") == themes_[i]:
			theme_index_ = i
	
	_save.set_selected_config_path(config_.path)

	%OptionButtonTheme.selected = theme_index_
	%LineEditOutputPath.text = save_data_.get("output_path", "res://assets")
	%SpinBoxPadding.value = save_data_.get("padding", -1)
	%CheckBoxIgnoreOutputPath.button_pressed = save_data_.get("ignore_output_path", false)
	%CheckBoxIgnoreOutputConfigPath.button_pressed = save_data_.get("ignore_output_config_path", false)
		
func _remove_configuration(index_: int) -> void:
	if _selected_index < 0:
		return
		
	_save.erase_config_data(_configs[index_].path)
	
	_configs.remove_at(index_)
	
	if _selected_index >= index_:
		index_ -= 1
	elif _configs.size() == 0:
		index_ = -1
	
	_update_configs_list()
	_select_configuration(index_)
	_save.save()

func _on_button_select_all_inputs_pressed() -> void:
	var all_selected_: bool = true
	
	for child_: CheckBox in %VBoxContainerInputs.get_children():
		if not child_.button_pressed:
			all_selected_ = false
			
	if all_selected_:
		for child_: CheckBox in %VBoxContainerInputs.get_children():
			child_.button_pressed = false
	else:
		for child_: CheckBox in %VBoxContainerInputs.get_children():
			child_.button_pressed = true


func _on_button_select_all_outputs_pressed() -> void:
	var all_selected_: bool = true
	
	for child_: CheckBox in %VBoxContainerOutputs.get_children():
		if not child_.button_pressed:
			all_selected_ = false
			
	if all_selected_:
		for child_: CheckBox in %VBoxContainerOutputs.get_children():
			child_.button_pressed = false
	else:
		for child_: CheckBox in %VBoxContainerOutputs.get_children():
			child_.button_pressed = true

func _on_button_generate_pressed() -> void:
	var retrogrde_image_: RetrogradeImage = RetrogradeImage.new()
	var config_: RetrogradeImageConfig = _configs[_selected_index]
	
	retrogrde_image_.run(config_.path, {
		&"inputs": _get_selected_inputs() ,
		&"outputs": _get_selected_outputs(),
		&"theme": %OptionButtonTheme.get_item_text(%OptionButtonTheme.selected),
		&"padding": int(%SpinBoxPadding.value),
		&"ignore_output_path": %CheckBoxIgnoreOutputPath.button_pressed,
		&"ignore_output_config_path": %CheckBoxIgnoreOutputConfigPath.button_pressed,
		&"output_path": %LineEditOutputPath.text
	})

func _on_button_select_output_path_pressed() -> void:
	_folder_dialog.popup_file_dialog()

func _get_selected_inputs() -> Array[String]:
	var inputs_: Array[String]
	
	for child_: CheckBox in %VBoxContainerInputs.get_children():
		if child_.button_pressed:
			inputs_.push_back(child_.text)
	
	return inputs_
	
func _get_selected_outputs() -> Array[String]:
	var outputs_: Array[String]
	
	for child_: CheckBox in %VBoxContainerOutputs.get_children():
		if child_.button_pressed:
			outputs_.push_back(child_.text)
	
	return outputs_
	
func save_selected_config() -> void:
	if _selected_index < 0:
		return
		
	var path_: String = _configs[_selected_index].path
	var data_: Dictionary = {
		"inputs": _get_selected_inputs(),
		"outputs": _get_selected_outputs(),
		"theme": %OptionButtonTheme.get_item_text(%OptionButtonTheme.selected),
		"padding": %SpinBoxPadding.value,
		"ignore_output_path": %CheckBoxIgnoreOutputPath.button_pressed,
		"ignore_output_config_path": %CheckBoxIgnoreOutputConfigPath.button_pressed,
		"output_path": %LineEditOutputPath.text
	}

	_save.set_config_data(path_, data_)
	_save.save()

func _on_line_edit_output_path_text_changed(_new_text: String) -> void:
	save_selected_config()

func _on_option_button_theme_item_selected(_index: int) -> void:
	save_selected_config()
	
func _on_spin_box_padding_value_changed(value_: float) -> void:
	if value_ == -1.0:
		%SpinBoxPadding.suffix = "(Use Default)"
	else:
		%SpinBoxPadding.suffix = "px"
		
	save_selected_config()

func _on_check_box_ignore_output_path_toggled(_toggled_on: bool) -> void:
	save_selected_config()

func _on_check_box_ignore_output_config_path_toggled(_toggled_on: bool) -> void:
	save_selected_config()

func _on_check_box_toggled(_toogled_on: bool ) -> void:
	save_selected_config()
	
	if _get_selected_inputs().size() == 0 or _get_selected_outputs().size() == 0:
		%ButtonGenerate.disabled = true
	else:
		%ButtonGenerate.disabled = false
