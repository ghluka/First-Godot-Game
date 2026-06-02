@tool
class_name level_list
extends Resource

@export var levels: Array[String] = []

@export_tool_button("phil")
var phil = func():
	levels.clear()
	var files = DirAccess.get_files_at("res://scenes/levels")
	for f in files:
		if f.ends_with(".tscn"):
			levels.append(f)
