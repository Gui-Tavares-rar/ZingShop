class_name BossToast
extends PanelContainer

## Recado do chefe: aparece por alguns segundos e some.

const MESSAGE_TIME := 4.0

var _tween: Tween

@onready var _label: Label = %BossLabel


func say(message: String) -> void:
	_label.text = "CHEFE: " + message
	modulate.a = 1.0
	show()
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(MESSAGE_TIME)
	_tween.tween_property(self, "modulate:a", 0.0, 0.4)
	_tween.tween_callback(hide)
