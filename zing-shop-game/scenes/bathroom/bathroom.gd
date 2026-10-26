class_name Bathroom
extends Control

## Minigame do banheiro: segure o botão esquerdo e passe a mangueira sobre a sujeira.
## O fundo é uma foto; a sujeira e a mangueira ficam em nós próprios por cima dela.
## A fila continua andando enquanto isso, só que mais devagar (ver DayData).

signal cleaned

const SPOT_COUNT := 9
## Quanto de sujeira (0 a 1) a água remove por segundo de cada pixel.
const CLEAN_RATE := 2.2
## Fração de sujeira que pode sobrar, para o jogador não caçar pixel solto.
const CLEAN_TOLERANCE := 0.03

@onready var _dirt: BathroomDirt = %Dirt
@onready var _hose: Hose = %Hose
@onready var _progress_label: Label = %ProgressLabel
@onready var _patience_box: Control = %PatienceBox
@onready var _patience_bar: ProgressBar = %PatienceBar


func start() -> void:
	_dirt.spawn(SPOT_COUNT)
	_hose.spraying = false
	_update_progress()
	show()


## Mostra a paciência do cliente que está no caixa; um valor negativo esconde a barra.
func set_customer_patience(ratio: float) -> void:
	_patience_box.visible = ratio >= 0.0
	_patience_bar.value = ratio * 100.0


func _gui_input(event: InputEvent) -> void:
	var mouse_button := event as InputEventMouseButton
	if mouse_button and mouse_button.button_index == MOUSE_BUTTON_LEFT:
		_hose.spraying = mouse_button.pressed
		accept_event()


func _process(delta: float) -> void:
	if not visible or not _hose.spraying:
		return
	_dirt.clean_at(get_global_mouse_position(), Hose.SPRAY_RADIUS, CLEAN_RATE * delta)
	_update_progress()
	if _dirt.remaining() <= CLEAN_TOLERANCE:
		_hose.spraying = false
		hide()
		cleaned.emit()


func _update_progress() -> void:
	var cleaned_ratio := clampf((1.0 - _dirt.remaining()) / (1.0 - CLEAN_TOLERANCE), 0.0, 1.0)
	_progress_label.text = "Limpo: %d%%" % roundi(cleaned_ratio * 100.0)
