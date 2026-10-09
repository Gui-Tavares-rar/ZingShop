class_name DaySummary
extends Control

## Tela de fim de expediente com o resultado do dia.

@onready var _title: Label = %Title
@onready var _stats: Label = %Stats
@onready var _restart_button: Button = %RestartButton


func _ready() -> void:
	_restart_button.pressed.connect(func() -> void: get_tree().reload_current_scene())


func present(title: String, lines: PackedStringArray) -> void:
	_title.text = title
	_stats.text = "\n".join(lines)
	show()
