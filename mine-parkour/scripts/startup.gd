extends Node

const SAVE_PATH = "user://save.cfg"

var levels_unlocked: int = 1

var show_level_select_on_load = false

func _ready():
	load_game()

func save_game():
	var cfg = ConfigFile.new()
	cfg.set_value("progress", "levels_unlocked", levels_unlocked)
	cfg.save(SAVE_PATH)

func load_game():
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		levels_unlocked = cfg.get_value("progress", "levels_unlocked", 1)

func complete_level(level_index: int):
	if level_index >= levels_unlocked:
		levels_unlocked = level_index + 1
	save_game()
