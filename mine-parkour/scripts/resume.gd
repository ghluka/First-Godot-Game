extends Button

func _pressed() -> void:
	Input.action_release("pause")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
