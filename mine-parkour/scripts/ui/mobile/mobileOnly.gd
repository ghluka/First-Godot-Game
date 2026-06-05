extends Control

func _ready():
	if DisplayServer.is_touchscreen_available():
		show()
	else:
		hide()
		
