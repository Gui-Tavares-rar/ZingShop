class_name PauseMenu
extends Control

## Atalhos de teclado do jogo: P pausa e continua, M volta ao menu e zera a semana.
## Pausa a árvore inteira enquanto a tela está aberta; por isso este nó continua rodando na pausa.

signal leave_requested


func _ready() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode != KEY_P and key.keycode != KEY_M:
		return
	# Antes de agir: voltar ao menu tira este nó da árvore.
	get_viewport().set_input_as_handled()
	if key.keycode == KEY_P:
		_set_paused(not visible)
	else:
		leave_requested.emit()


func _set_paused(paused: bool) -> void:
	visible = paused
	get_tree().paused = paused
