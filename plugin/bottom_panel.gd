@tool
extends Control

func _ready() -> void:
	var tab: Control = preload("res://addons/retrograde_image/plugin/tabs/retrograde_image_tab.tscn").instantiate()
	add_child(tab)
