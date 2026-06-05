extends Label

func _ready():
	if not DisplayServer.is_touchscreen_available():
		show()
	else:
		hide()
		
