class_name MainMenu
extends Control

## Tela inicial: começa a semana de trabalho ou fecha o jogo.
## Quem nunca jogou começa pelo Prólogo, o treinamento guiado. Quem já terminou o Prólogo vai
## direto para o Dia 1, mas pode jogar o Prólogo de novo.

const GAME_SCENE := "res://scenes/main.tscn"

@onready var _start_button: Button = %StartButton
@onready var _prologue_button: Button = %PrologueButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	var prologue_done := GameSession.is_prologue_done()
	_start_button.pressed.connect(_start_game.bind(prologue_done))
	_prologue_button.pressed.connect(_start_game.bind(false))
	_prologue_button.visible = prologue_done
	_quit_button.pressed.connect(get_tree().quit)
	_quit_button.visible = not OS.has_feature("web")
	_start_button.grab_focus()


func _start_game(skip_prologue: bool) -> void:
	GameSession.reset()
	GameSession.skip_prologue = skip_prologue
	get_tree().change_scene_to_file(GAME_SCENE)
