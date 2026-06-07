extends Label

const SPLASHES: Array[String] = [
	"luka.onl!",
	"Made in GDScript!",
	"Hello world!",
	"Redistribute!",
	"Avoid the lava!",
]

func splash():
	var date = Time.get_date_dict_from_system()
	var month = date["month"]
	var day = date["day"]

	if month == 12 and day == 25:
		text = "Merry Christmas!"
	elif month == 10 and day == 31:
		text = "Happy Halloween!"
	else:
		text = SPLASHES[randi() % SPLASHES.size()]

func _ready() -> void:
	splash()
	start_animation()

func _on_visibility_changed() -> void:
	splash()

@export var max_scale: Vector2 = Vector2(1.05, 1.05)
@export var min_scale: Vector2 = Vector2(1, 1)
@export var length: float = 0.5
func start_animation() -> void:
	var tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", max_scale, length)
	tween.tween_property(self, "scale", min_scale, length)
