class_name CardMachine
extends Button

## Maquininha de cartão. Quando o cliente paga no cartão, basta clicar nela.

signal payment_approved

const PROCESSING_TIME := 1.2
const TITLE := "MAQUININHA\n\n"

var _active := false


func _ready() -> void:
	pressed.connect(_on_pressed)
	reset()


func activate() -> void:
	_active = true
	disabled = false
	text = TITLE + "Clique para\npassar o cartão"


## Cancela um pagamento em andamento e volta a máquina ao estado inicial.
func reset() -> void:
	_active = false
	disabled = true
	text = TITLE + "- - -"


func _on_pressed() -> void:
	if not _active:
		return
	disabled = true
	text = TITLE + "Processando..."
	await get_tree().create_timer(PROCESSING_TIME).timeout
	if not _active:
		return
	_active = false
	text = TITLE + "APROVADO!"
	payment_approved.emit()
