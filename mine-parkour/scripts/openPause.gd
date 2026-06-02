extends PanelContainer

func _input(event: InputEvent) -> void:
	if not visible and event.is_action_pressed("pause"):
		$".".show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
