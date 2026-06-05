extends PanelContainer

func _input(event: InputEvent) -> void:
	if not DisplayServer.is_touchscreen_available() and event.is_action_pressed("pause"):
		Input.action_release("pause")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$".".call_deferred("show")

func _physics_process(_delta: float) -> void:
	if visible and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		$".".call_deferred("hide")
		_flush_inputs()

func _flush_inputs() -> void:
	for action in ["pause", "move_forward", "move_back", "move_left", "move_right", "jump", "sprint", "sneak"]:
		Input.action_release(action)
