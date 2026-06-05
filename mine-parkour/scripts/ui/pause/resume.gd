extends Button

func _pressed() -> void:
	Input.action_release("pause")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if DisplayServer.is_touchscreen_available():
		for action in ["pause", "move_forward", "move_back", "move_left", "move_right", "jump", "sprint", "sneak"]:
			Input.action_release(action)
		$"../..".call_deferred("hide")
