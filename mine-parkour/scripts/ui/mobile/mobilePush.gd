extends Label

func _ready():
	if DisplayServer.is_touchscreen_available():
		offset_top = 88
		
