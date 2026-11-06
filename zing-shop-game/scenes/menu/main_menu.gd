class_name MainMenu
extends Control

## Tela inicial: começa a semana de trabalho ou fecha o jogo.

const GAME_SCENE := "res://scenes/main.tscn"

@onready var _start_button: Button = %StartButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_start_button.pressed.connect(_start_game)
	_quit_button.pressed.connect(get_tree().quit)
	_quit_button.visible = not OS.has_feature("web")
	_start_button.grab_focus()


func _start_game() -> void:
	GameSession.reset()
	get_tree().change_scene_to_file(GAME_SCENE)
