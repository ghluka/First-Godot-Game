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

func _on_visibility_changed() -> void:
	splash()
