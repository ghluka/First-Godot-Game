extends Node

const SAVE_PATH = "user://save.cfg"

var levels_unlocked: int = 1
var mouse_sens: float = 0.002

var show_level_select_on_load = false

var music_player: AudioStreamPlayer

func _ready():
	load_game()
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.stream = preload("res://sounds/menu.ogg")
	music_player.volume_db = 0.0
	music_player.play()

func save_game():
	var cfg = ConfigFile.new()
	cfg.set_value("progress", "levels_unlocked", levels_unlocked)
	cfg.set_value("settings", "sensitivity", mouse_sens)
	cfg.save(SAVE_PATH)

func load_game():
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		levels_unlocked = cfg.get_value("progress", "levels_unlocked", 1)
		mouse_sens = cfg.get_value("settings", "sensitivity", 0.002)

func complete_level(level_index: int):
	if level_index >= levels_unlocked:
		levels_unlocked = level_index + 1
	save_game()
