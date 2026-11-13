class_name DaySummary
extends Control

## Tela de fim de expediente com o resultado do dia.

signal continue_pressed

@onready var _title: Label = %Title
@onready var _stats: Label = %Stats
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	_continue_button.pressed.connect(continue_pressed.emit)


func present(title: String, lines: PackedStringArray, button_text: String) -> void:
	_title.text = title
	_continue_button.text = button_text
	_stats.text = "\n".join(lines)
	show()
