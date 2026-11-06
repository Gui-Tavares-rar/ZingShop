extends Control

## Controla um dia de expediente: chama os clientes da fila, acompanha a paciência de quem
## está no caixa e aplica as broncas do chefe. A venda em si fica com o Checkout e a
## conversa com o cliente, com o InspectionPanel.

enum State { NO_CUSTOMER, INSPECTING, SERVING, CUSTOMER_LEAVING, DAY_OVER }

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const CUSTOMER_EXIT_DELAY := 1.8
const BATHROOM_METER_MAX := 100.0

@export var day: DayData
## Falas fixas do chefe e dos clientes (data/dialogues.tres).
@export var dialogues: DialogueData = preload("res://data/dialogues.tres")

var _state := State.NO_CUSTOMER
var _queue: CustomerQueue
var _results := DayResults.new()
var _current: CustomerData
var _patience_left := 0.0
var _patience_total := 1.0
## Erro de decisão ao atender (aviso e motivo), cobrado só quando o atendimento termina.
var _pending_mistake := {}
var _bathroom_meter := 0.0

@onready var _hud: Hud = %HUD
@onready var _queue_view: QueueView = %QueueRow
@onready var _customer_view: CustomerView = %CustomerView
@onready var _checkout: Checkout = %Checkout
@onready var _inspection: InspectionPanel = %InspectionPanel
@onready var _bathroom: Bathroom = %Bathroom
@onready var _boss: BossToast = %BossToast
@onready var _day_summary: DaySummary = %DaySummary
@onready var _bell_sound: AudioStreamPlayer = %BellSound
@onready var _alarm_sound: AudioStreamPlayer = %AlarmSound


func _ready() -> void:
	day = GameSession.start(day)
	_queue = CustomerQueue.new(day.arrivals)
	_queue.changed.connect(func() -> void: _queue_view.show_customers(_queue.waiting))
	_inspection.question_asked.connect(_on_question_asked)
	_inspection.serve_chosen.connect(_on_serve_chosen)
	_inspection.security_called.connect(_on_security_called)
	_inspection.document_requested.connect(_on_document_requested)
	_checkout.payment_started.connect(_on_payment_started)
	_checkout.sale_finished.connect(_on_sale_finished)
	_bathroom.cleaned.connect(_on_bathroom_cleaned)
	_day_summary.continue_pressed.connect(_on_next_day_pressed)
	_bathroom.hide()
	_day_summary.hide()
	_refresh_hud()
	_boss_says(dialogues.boss_day_start, {"day": day.day_number})


func _process(delta: float) -> void:
	if _state == State.DAY_OVER:
		return
	_queue.advance(delta)
	match _state:
		State.NO_CUSTOMER:
			if _queue.has_waiting():
				_call_next_customer()
			elif _queue.is_finished() and not _bathroom.visible:
				_end_day()
		State.INSPECTING, State.SERVING:
			_drain_patience(delta)


func _drain_patience(delta: float) -> void:
	var rate := day.bathroom_patience_multiplier if _bathroom.visible else 1.0
	_patience_left = maxf(_patience_left - delta * rate, 0.0)
	var ratio := _patience_left / _patience_total
	_customer_view.set_patience(ratio)
	_bathroom.set_customer_patience(ratio)
	if _patience_left <= 0.0:
		_customer_gives_up()


func _call_next_customer() -> void:
	_current = _queue.next()
	_bell_sound.play()
	_patience_total = day.patience_for(_current)
	_patience_left = _patience_total
	_customer_view.present(_current)
	_customer_view.say(_current.greeting)
	if day.inspection_enabled:
		_inspection.open(_current, day.today_text())
		_state = State.INSPECTING
	else:
		_start_serving()


func _start_serving() -> void:
	_checkout.serve(_current, _customer_view.get_hands_global_position())
	_state = State.SERVING


func _on_question_asked(question: Question) -> void:
	_customer_view.say(question.answer)


func _on_document_requested() -> void:
	_customer_says(dialogues.customer_hands_id)


## O jogador decidiu atender. Se o cliente tinha um problema que o dia manda barrar, o erro
## fica anotado e o chefe cobra quando o atendimento terminar.
func _on_serve_chosen() -> void:
	if _state != State.INSPECTING:
		return
	_inspection.close()
	_start_serving()
	if day.should_bar(_current):
		_pending_mistake = {
			"message": dialogues.pick(dialogues.boss_served_should_bar, {"penalty": Money.format(day.wrong_decision_penalty_cents)}),
			"reason": "Atendeu quem devia barrar",
		}


## O jogador chamou o segurança. Se o cliente não tinha problema nenhum, o chefe cobra.
func _on_security_called() -> void:
	if _state != State.INSPECTING:
		return
	_inspection.close()
	_results.add_removed_customer()
	_customer_view.set_mood(PersonFigure.Mood.ANGRY)
	_customer_says(dialogues.customer_removed)
	if day.should_bar(_current):
		_boss_says(dialogues.boss_praise_barred)
	else:
		_wrong_decision(dialogues.pick(dialogues.boss_barred_wrongly, {"penalty": Money.format(day.wrong_decision_penalty_cents)}),
			"Barrou quem estava certo")
	_dismiss_customer_later()


func _wrong_decision(message: String, reason: String) -> void:
	var report := _book_wrong_decision(message, reason)
	_reprimand(report, day.wrong_decision_bathroom)


## Desconta o erro de decisão do dia e devolve o recado do chefe.
func _book_wrong_decision(message: String, reason: String) -> String:
	_results.add_penalty(day.wrong_decision_penalty_cents, reason)
	return message


## O atendimento terminou: cobra o erro de decisão anotado (se houve) junto com o recado dado.
## Um só recado do chefe e um só aumento do medidor, mesmo com mais de um erro.
func _settle_service(message: String, bathroom_amount: float) -> void:
	if not _pending_mistake.is_empty():
		var report := _book_wrong_decision(_pending_mistake["message"], _pending_mistake["reason"])
		message = report if message.is_empty() else report + "\n" + message
		bathroom_amount += day.wrong_decision_bathroom
		_pending_mistake = {}
	if not message.is_empty():
		_reprimand(message, bathroom_amount)


func _on_payment_started() -> void:
	match _current.payment_method:
		CustomerData.PaymentMethod.CARD:
			_customer_says(dialogues.customer_pays_card)
		CustomerData.PaymentMethod.CASH:
			_customer_says(dialogues.customer_pays_cash, {"cash": Money.format(_current.cash_given_cents)})


func _on_sale_finished(correct: bool, given_cents: int, expected_cents: int) -> void:
	_results.add_sale(_current.get_total_cents(), day.commission_rate)
	_customer_view.set_mood(PersonFigure.Mood.HAPPY if correct else PersonFigure.Mood.ANGRY)
	if _current.payment_method == CustomerData.PaymentMethod.CARD:
		_customer_says(dialogues.customer_thanks_card)
	elif correct:
		_customer_says(dialogues.customer_thanks_cash)
	else:
		_customer_says(dialogues.customer_change_short if given_cents < expected_cents else dialogues.customer_change_wrong)
	_dismiss_customer_later()
	if correct:
		_settle_service("", 0.0)
	else:
		_results.add_penalty(day.wrong_change_penalty_cents, "Troco errado")
		_settle_service(dialogues.pick(dialogues.boss_wrong_change, {
			"expected": Money.format(expected_cents),
			"given": Money.format(given_cents),
			"penalty": Money.format(day.wrong_change_penalty_cents),
		}), day.wrong_change_bathroom)


func _customer_gives_up() -> void:
	_results.add_lost_customer()
	_customer_view.set_mood(PersonFigure.Mood.ANGRY)
	_customer_says(dialogues.customer_gives_up)
	_inspection.close()
	_checkout.abandon()
	_settle_service(dialogues.pick(dialogues.boss_customer_left), day.timeout_bathroom)
	_dismiss_customer_later()


func _dismiss_customer_later() -> void:
	_state = State.CUSTOMER_LEAVING
	_refresh_hud()
	get_tree().create_timer(CUSTOMER_EXIT_DELAY).timeout.connect(_dismiss_customer)


func _dismiss_customer() -> void:
	_checkout.clear()
	_customer_view.leave()
	_bathroom.set_customer_patience(-1.0)
	_current = null
	_state = State.NO_CUSTOMER


## Bronca do chefe. Enche o medidor do banheiro e, se lotar, manda o jogador lavar.
func _reprimand(message: String, bathroom_amount: float) -> void:
	_bathroom_meter = minf(_bathroom_meter + bathroom_amount, BATHROOM_METER_MAX)
	if _bathroom_meter >= BATHROOM_METER_MAX and not _bathroom.visible:
		message += "\n" + dialogues.pick(dialogues.boss_bathroom_start)
		_bathroom.set_customer_patience(-1.0)
		_bathroom.start()
	_alarm_sound.play()
	message = message.strip_edges()
	if not message.is_empty():
		_boss.say(message)
	_refresh_hud()


func _customer_says(lines: Array[String], values: Dictionary = {}) -> void:
	var text := dialogues.pick(lines, values)
	if not text.is_empty():
		_customer_view.say(text)


func _boss_says(lines: Array[String], values: Dictionary = {}) -> void:
	var text := dialogues.pick(lines, values)
	if not text.is_empty():
		_boss.say(text)


func _on_bathroom_cleaned() -> void:
	_bathroom_meter = 0.0
	_refresh_hud()
	_boss_says(dialogues.boss_bathroom_done)


func _end_day() -> void:
	_state = State.DAY_OVER
	var button_text := "Próximo dia" if day.next_day else "Voltar ao menu"
	_day_summary.present("Fim do Dia %d" % day.day_number, _results.summary_lines(day.customer_count()), button_text)


func _on_next_day_pressed() -> void:
	if day.next_day:
		GameSession.finish(day)
		get_tree().reload_current_scene()
	else:
		GameSession.reset()
		get_tree().change_scene_to_file(MENU_SCENE)


func _refresh_hud() -> void:
	_hud.refresh(day.day_number, _results.served, day.customer_count(), _results.earnings_cents(), _bathroom_meter)
