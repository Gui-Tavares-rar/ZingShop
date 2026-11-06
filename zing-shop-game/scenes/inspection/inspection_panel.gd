class_name InspectionPanel
extends PanelContainer

## Mesa de inspeção: documento do cliente, perguntas e a decisão entre atender e chamar o segurança.
## Só mostra o que o cliente tem; quem julga a decisão é o dia (ver DayData.active_rules).

## O jogador fez uma pergunta; a resposta deve ser dita pelo cliente.
signal question_asked(question: Question)
signal serve_chosen
signal security_called
## O jogador pediu o documento a um cliente que não o entregou.
signal document_requested

var _customer: CustomerData

@onready var _document_title: Label = %DocumentTitle
@onready var _document: Control = %Document
@onready var _holder_label: Label = %HolderLabel
@onready var _birth_label: Label = %BirthLabel
@onready var _photo_figure: PersonFigure = %PhotoFigure
@onready var _photo_texture: TextureRect = %PhotoTexture
@onready var _no_document_label: Label = %NoDocumentLabel
@onready var _request_button: Button = %RequestButton
@onready var _cart_label: Label = %CartLabel
@onready var _questions: VBoxContainer = %Questions
@onready var _serve_button: Button = %ServeButton
@onready var _security_button: Button = %SecurityButton


func _ready() -> void:
	_serve_button.pressed.connect(serve_chosen.emit)
	_security_button.pressed.connect(security_called.emit)
	_request_button.pressed.connect(_on_request_pressed)
	hide()


func open(customer: CustomerData, today: String) -> void:
	_customer = customer
	_document_title.text = "DOCUMENTO  ·  hoje: " + today
	_cart_label.text = _cart_text(customer)
	if customer.id_card != null and not customer.hands_over_id:
		_show_missing_document("O cliente não entregou o documento.", true)
	elif customer.id_card == null:
		_show_missing_document("Este cliente não tem documento.", false)
	else:
		_show_document(customer)
	for button in _questions.get_children():
		button.queue_free()
	for question in customer.questions:
		var button := Button.new()
		button.text = question.prompt
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_question_pressed.bind(question, button))
		_questions.add_child(button)
	show()


func close() -> void:
	hide()


func _show_missing_document(message: String, can_request: bool) -> void:
	_document.hide()
	_no_document_label.text = message
	_no_document_label.show()
	_request_button.visible = can_request


func _show_document(customer: CustomerData) -> void:
	var id_card := customer.id_card
	_document.show()
	_no_document_label.hide()
	_request_button.hide()
	_holder_label.text = id_card.holder_name
	_birth_label.text = id_card.birth_text()
	# A foto mostra o próprio cliente, a menos que o documento seja de outra pessoa.
	var shown := id_card.photo_of if id_card.photo_of else customer
	_photo_texture.texture = shown.portrait
	_photo_texture.visible = shown.portrait != null
	_photo_figure.body_color = shown.body_color
	_photo_figure.visible = shown.portrait == null


## "2× Cerveja (lata), Maçã": o que o cliente quer comprar, agrupando repetidos.
func _cart_text(customer: CustomerData) -> String:
	var counts := {}
	for item in customer.items:
		counts[item.display_name] = counts.get(item.display_name, 0) + 1
	var parts := PackedStringArray()
	for item_name: String in counts:
		parts.append(item_name if counts[item_name] == 1 else "%d× %s" % [counts[item_name], item_name])
	return ", ".join(parts)


func _on_request_pressed() -> void:
	_show_document(_customer)
	document_requested.emit()


## Cada pergunta só pode ser feita uma vez.
func _on_question_pressed(question: Question, button: Button) -> void:
	button.disabled = true
	question_asked.emit(question)
