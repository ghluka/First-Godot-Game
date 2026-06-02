extends Node3D

@export var swing_speed: float = 12.0
@export var swing_angle: float = -25.0
@export var return_speed: float = 8.0

var is_swinging: bool = false
var rest_rotation: Vector3
var target_rotation: Vector3

func _ready():
	rest_rotation = rotation_degrees
	target_rotation = rest_rotation

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			swing()

func swing():
	if is_swinging:
		return
	is_swinging = true

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	var swung = rest_rotation + Vector3(swing_angle, -swing_angle, 0)
	tween.tween_property(self, "rotation_degrees", swung, 0.08)
	tween.tween_property(self, "rotation_degrees", rest_rotation, 0.18)\
		 .set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func(): is_swinging = false)
