extends FlowContainer

@export var buttonScene: String = "res://scenes/ui/levelbutton.tscn"
@export var levelList: level_list

func _ready():
	var i = 0
	for s in levelList.levels:
		#print(s)
		i += 1
		var con: AspectRatioContainer = ResourceLoader.load(buttonScene).instantiate()
		var btn: Button = con.find_child("Button")
		btn.text = str(i)
		if i <= Startup.levels_unlocked:
			btn.scene = "res://scenes/levels/" + s
			btn.disabled = false
		else:
			btn.disabled = true
			btn.text = ""
			btn.find_child("Lock").visible = true
		if i == Startup.levels_unlocked:
			btn.add_theme_color_override("font_color", Color.BLACK)
			btn.add_theme_color_override("font_hover_color", Color.BLACK)
			btn.add_theme_color_override("font_pressed_color", Color.BLACK)
			var normal := StyleBoxFlat.new()
			normal.bg_color = Color(1, 0.9, 0.2)
			var hover := StyleBoxFlat.new()
			hover.bg_color = Color(0.9, 0.8, 0.0)
			var pressed := StyleBoxFlat.new()
			pressed.bg_color = Color(0.8, 0.7, 0.2)
			btn.add_theme_stylebox_override("normal", normal)
			btn.add_theme_stylebox_override("hover", hover)
			btn.add_theme_stylebox_override("pressed", pressed)
		add_child(con)
	
