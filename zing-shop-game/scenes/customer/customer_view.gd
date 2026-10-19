class_name CustomerView
extends Control

## Cliente sendo atendido no caixa: boneco, nome, barra de paciência e balão de fala.
## As falas são digitadas letra por letra, com os blips da voz do cliente.

const PATIENCE_LOW := Color("e5484d")
const PATIENCE_MID := Color("f2c14e")
const PATIENCE_HIGH := Color("46c46e")
const CHARACTERS_PER_SECOND := 40.0
## Segundos de pausa depois de vírgula, ponto e vírgula ou dois-pontos.
const COMMA_PAUSE := 0.12
## Segundos de pausa depois de ponto, ! ou ?.
const STOP_PAUSE := 0.3
## Blips se sobrepõem na velocidade de digitação, então tocam em players alternados.
const BLIP_PLAYER_COUNT := 4

var _patience_fill := StyleBoxFlat.new()
var _fade_tween: Tween
var _voice: BlipVoice
var _voice_pitch := 1.0
var _blip_players: Array[AudioStreamPlayer] = []
var _next_blip_player := 0
var _letters_typed := 0
## Tempo até a próxima letra aparecer.
var _typing_clock := 0.0
## 1 nas letras da última palavra de uma pergunta, que sobem de tom.
var _question_lifts := PackedFloat32Array()

@onready var _figure: PersonFigure = %Figure
@onready var _name_label: Label = %NameLabel
@onready var _patience_bar: ProgressBar = %PatienceBar
@onready var _speech: PanelContainer = %Speech
@onready var _speech_label: Label = %SpeechLabel


func _ready() -> void:
	_patience_bar.add_theme_stylebox_override("fill", _patience_fill)
	# O balão já nasce do tamanho da fala inteira, em vez de crescer enquanto ela é digitada.
	_speech_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	for i in BLIP_PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_blip_players.append(player)
	hide()


func _process(delta: float) -> void:
	if not _is_typing():
		return
	_typing_clock -= delta
	while _is_typing() and _typing_clock <= 0.0:
		_type_next_letter()


func present(customer: CustomerData) -> void:
	_voice = customer.voice
	_voice_pitch = customer.voice_pitch
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
	_speech_label.visible_characters = -1
	var tween := _restart_fade()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(hide)


## Começa a digitar `text` no balão, interrompendo a fala anterior.
func say(text: String) -> void:
	_speech_label.text = text
	_speech_label.visible_characters = 0
	_question_lifts = _mark_question_lifts(text)
	_letters_typed = 0
	_typing_clock = 0.0
	_speech.show()


func set_mood(mood: PersonFigure.Mood) -> void:
	_figure.mood = mood

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


## visible_characters = -1 mostra o texto inteiro, ou seja, a digitação acabou.
func _is_typing() -> bool:
	return _speech_label.visible_characters >= 0


func _type_next_letter() -> void:
	var text := _speech_label.text
	var i := _speech_label.visible_characters
	if i >= text.length():
		_speech_label.visible_characters = -1
		return
	_speech_label.visible_characters = i + 1
	var letter := text[i]
	if _is_letter(letter):
		_blip(letter, _question_lifts[i])
	var after := text[i + 1] if i + 1 < text.length() else " "
	var pause := 0.0
	if letter in ".!?" and after in " \n.!?\"')":
		pause = STOP_PAUSE
	elif letter in ",;:" and after in " \n":
		pause = COMMA_PAUSE
	_typing_clock += 1.0 / CHARACTERS_PER_SECOND + pause


func _blip(letter: String, lift: float) -> void:
	_letters_typed += 1
	if _voice == null or _voice.sounds.is_empty() or (_letters_typed - 1) % _voice.every != 0:
		return
	var pick := _voice.pick(letter, lift * _voice.question_lift)
	var player := _blip_players[_next_blip_player]
	_next_blip_player = (_next_blip_player + 1) % _blip_players.size()
	player.stream = pick[0]
	player.pitch_scale = pick[1] * _voice_pitch
	player.volume_db = _voice.volume_db
	player.play()


## Marca as letras da última palavra antes de cada "?", para a pergunta subir de tom.
static func _mark_question_lifts(text: String) -> PackedFloat32Array:
	var lifts := PackedFloat32Array()
	lifts.resize(text.length())
	lifts.fill(0.0)
	var lifting := false
	var in_word := false
	for i in range(text.length() - 1, -1, -1):
		var c := text[i]
		if c == "?":
			lifting = true
			in_word = false
		elif lifting:
			if _is_letter(c):
				lifts[i] = 1.0
				in_word = true
			elif in_word:
				lifting = false
	return lifts


static func _is_letter(c: String) -> bool:
	return c.to_upper() != c.to_lower() or (c >= "0" and c <= "9")
