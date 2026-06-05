extends Label

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			OS.shell_open("https://github.com/ghluka/First-Godot-Game/blob/main/LICENSE")
