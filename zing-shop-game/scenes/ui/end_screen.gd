class_name EndScreen
extends Control

## Tela final da semana: só diz se o jogador venceu ou perdeu.

signal menu_requested

const WIN_COLOR := Color("7dffa8")
const LOSE_COLOR := Color("ff6b6b")

@onready var _title: Label = %Title
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	_menu_button.pressed.connect(menu_requested.emit)
	hide()


func present(won: bool) -> void:
	_title.text = "Você Venceu" if won else "Você Perdeu"
	_title.add_theme_color_override("font_color", WIN_COLOR if won else LOSE_COLOR)
	show()
	_menu_button.grab_focus()
