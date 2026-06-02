extends HSlider

func _ready():
	value = Startup.mouse_sens/0.00004

func _value_changed(new_value: float) -> void:
	Startup.mouse_sens = 0.00004 * new_value
	Startup.save_game()
