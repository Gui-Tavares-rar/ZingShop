class_name MainMenu
extends Control

## Tela inicial: começa a semana de trabalho ou fecha o jogo.

const GAME_SCENE := "res://scenes/main.tscn"

@onready var _start_button: Button = %StartButton
@onready var _how_to_button: Button = %HowToButton
@onready var _quit_button: Button = %QuitButton
@onready var _how_to_play: HowToPlay = %HowToPlay

## O jogador apertou "Iniciar jogo" e está lendo o "Como jogar" antes de começar.
var _starting := false


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_how_to_button.pressed.connect(func() -> void: _open_how_to_play("Voltar", false))
	_how_to_play.closed.connect(_on_how_to_play_closed)
	_quit_button.pressed.connect(get_tree().quit)
	_quit_button.visible = not OS.has_feature("web")
	_start_button.grab_focus()


## Na primeira vez mostra o "Como jogar" antes de começar o dia.
func _on_start_pressed() -> void:
	if GameSession.tutorial_seen:
		_start_game()
	else:
		_open_how_to_play("Entendi, começar!", true)


func _open_how_to_play(button_text: String, then_start: bool) -> void:
	_starting = then_start
	_how_to_play.open(button_text)


func _on_how_to_play_closed() -> void:
	GameSession.tutorial_seen = true
	if _starting:
		_start_game()
	else:
		_start_button.grab_focus()


func _start_game() -> void:
	GameSession.reset()
	get_tree().change_scene_to_file(GAME_SCENE)
