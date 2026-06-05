extends Button

func _pressed() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/panorama.tscn")
