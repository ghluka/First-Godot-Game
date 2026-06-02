extends Camera3D

@export var rotation_speed: float = 30.0
@export var radius: float = 12.0
@export var height: float = 6.0

var angle: float = 0.0
var center: Vector3 = Vector3.ZERO

func _ready():
	if Startup.show_level_select_on_load:
		$"../MainMenu".hide()
		$"../LevelSelect".show()
	Startup.show_level_select_on_load = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	center = Vector3(0, height, 0)

func _process(delta):
	angle += rotation_speed * delta
	var rad = deg_to_rad(angle)
	
	var x = center.x + radius * cos(rad)
	var z = center.z + radius * sin(rad)
	global_position = Vector3(x, center.y, z)
	
	look_at(center, Vector3.UP)
