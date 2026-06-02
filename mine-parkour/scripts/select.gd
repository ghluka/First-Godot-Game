extends Button

@export var scene: String = "res://scenes/levels/level_01.tscn"

func _pressed() -> void:
	var res: PackedScene = ResourceLoader.load(scene)
	var lvl = res.instantiate()
	get_tree().root.add_child(lvl)
	get_tree().current_scene = lvl
	$"../../../../../..".queue_free()
