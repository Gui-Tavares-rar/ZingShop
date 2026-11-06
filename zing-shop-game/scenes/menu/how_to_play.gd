class_name HowToPlay
extends Control

## Tela "Como jogar": explica os controles e as regras. O texto fica no nó Text, editável no Godot.

signal closed

@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	_close_button.pressed.connect(_close)
	hide()


## Mostra a tela. `button_text` é o texto do botão que a fecha.
func open(button_text: String) -> void:
	_close_button.text = button_text
	show()
	_close_button.grab_focus()


func _close() -> void:
	hide()
	closed.emit()
