extends Area3D

func _on_body_entered(body):
	if body.is_in_group("player"):
		var scene_name = get_tree().current_scene.scene_file_path.get_file()
		var level_index = int(scene_name.lstrip("level_").rstrip(".tscn"))
		Startup.complete_level(level_index)
		Startup.show_level_select_on_load = true
		get_tree().call_deferred("change_scene_to_file", "res://scenes/panorama.tscn")
