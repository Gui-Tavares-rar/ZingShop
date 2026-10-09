class_name CustomerView
extends Control

## Cliente sendo atendido no caixa: boneco, nome, barra de paciência e balão de fala.

const PATIENCE_LOW := Color("e5484d")
const PATIENCE_MID := Color("f2c14e")
const PATIENCE_HIGH := Color("46c46e")

var _patience_fill := StyleBoxFlat.new()
var _fade_tween: Tween

@onready var _figure: PersonFigure = %Figure
@onready var _name_label: Label = %NameLabel
@onready var _patience_bar: ProgressBar = %PatienceBar
@onready var _speech: PanelContainer = %Speech
@onready var _speech_label: Label = %SpeechLabel


func _ready() -> void:
	_patience_bar.add_theme_stylebox_override("fill", _patience_fill)
	hide()


func present(customer: CustomerData) -> void:
	_figure.body_color = customer.body_color
	_figure.mood = PersonFigure.Mood.NEUTRAL
	_name_label.text = customer.display_name
	_speech.hide()
	set_patience(1.0)
	show()
	modulate.a = 0.0
	_restart_fade().tween_property(self, "modulate:a", 1.0, 0.25)


## De onde o cliente arremessa os itens.
func get_hands_global_position() -> Vector2:
	var body := _figure.get_global_rect()
	return body.position + Vector2(body.size.x * 0.5, body.size.y * 0.35)


func leave() -> void:
	var tween := _restart_fade()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(hide)


func say(text: String) -> void:
	_speech_label.text = text
	_speech.show()


func set_mood(mood: PersonFigure.Mood) -> void:
	_figure.mood = mood


## Cancela a animação de entrada/saída anterior. Sem isso, o hide() da saída do
## cliente anterior roda depois que o próximo já apareceu e o deixa invisível.
func _restart_fade() -> Tween:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	return _fade_tween


func set_patience(ratio: float) -> void:
	_patience_bar.value = ratio * 100.0
	if ratio > 0.5:
		_patience_fill.bg_color = PATIENCE_MID.lerp(PATIENCE_HIGH, (ratio - 0.5) * 2.0)
	else:
		_patience_fill.bg_color = PATIENCE_LOW.lerp(PATIENCE_MID, ratio * 2.0)
