extends Control

## Controla um dia de expediente: chama os clientes da fila, acompanha a paciência de quem
## está no caixa e aplica as broncas do chefe. A venda em si fica com o Checkout.

enum State { NO_CUSTOMER, SERVING, CUSTOMER_LEAVING, DAY_OVER }

const CUSTOMER_EXIT_DELAY := 1.8
const BATHROOM_METER_MAX := 100.0

@export var day: DayData

var _state := State.NO_CUSTOMER
var _queue: CustomerQueue
var _results := DayResults.new()
var _current: CustomerData
var _patience_left := 0.0
var _bathroom_meter := 0.0

@onready var _hud: Hud = %HUD
@onready var _queue_view: QueueView = %QueueRow
@onready var _customer_view: CustomerView = %CustomerView
@onready var _checkout: Checkout = %Checkout
@onready var _bathroom: Bathroom = %Bathroom
@onready var _boss: BossToast = %BossToast
@onready var _day_summary: DaySummary = %DaySummary


func _ready() -> void:
	_queue = CustomerQueue.new(day.customers)
	_queue.changed.connect(func() -> void: _queue_view.show_customers(_queue.waiting))
	_checkout.payment_started.connect(_on_payment_started)
	_checkout.sale_finished.connect(_on_sale_finished)
	_bathroom.cleaned.connect(_on_bathroom_cleaned)
	_bathroom.hide()
	_day_summary.hide()
	_refresh_hud()
	_boss.say("Dia %d! Escaneie tudo, cobre certo e não deixe ninguém esperando." % day.day_number)


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
		State.SERVING:
			_drain_patience(delta)


func _drain_patience(delta: float) -> void:
	var rate := day.bathroom_patience_multiplier if _bathroom.visible else 1.0
	_patience_left = maxf(_patience_left - delta * rate, 0.0)
	var ratio := _patience_left / _current.patience_seconds
	_customer_view.set_patience(ratio)
	_bathroom.set_customer_patience(ratio)
	if _patience_left <= 0.0:
		_customer_gives_up()


func _call_next_customer() -> void:
	_current = _queue.next()
	_patience_left = _current.patience_seconds
	_customer_view.present(_current)
	_customer_view.say(_current.greeting)
	_checkout.serve(_current, _customer_view.get_hands_global_position())
	_state = State.SERVING


func _on_payment_started() -> void:
	match _current.payment_method:
		CustomerData.PaymentMethod.CARD:
			_customer_view.say("Vou pagar no cartão.")
		CustomerData.PaymentMethod.CASH:
			_customer_view.say("Aqui, %s em dinheiro." % Money.format(_current.cash_given_cents))


func _on_sale_finished(correct: bool, given_cents: int, expected_cents: int) -> void:
	_results.add_sale(_current.get_total_cents(), day.commission_rate)
	_customer_view.set_mood(PersonFigure.Mood.HAPPY if correct else PersonFigure.Mood.ANGRY)
	if _current.payment_method == CustomerData.PaymentMethod.CARD:
		_customer_view.say("Obrigado, tchau!")
	elif correct:
		_customer_view.say("Obrigado! Até mais.")
	else:
		_customer_view.say("Ei, tá faltando troco!" if given_cents < expected_cents else "Hã? Esse troco tá errado!")
	_dismiss_customer_later()
	if not correct:
		_results.add_penalty(day.wrong_change_penalty_cents)
		_reprimand("Troco errado! Era %s e você deu %s. Vou descontar %s do seu dia." % [
			Money.format(expected_cents), Money.format(given_cents), Money.format(day.wrong_change_penalty_cents)],
			day.wrong_change_bathroom)


func _customer_gives_up() -> void:
	_results.add_lost_customer()
	_customer_view.set_mood(PersonFigure.Mood.ANGRY)
	_customer_view.say("Cansei de esperar! Tô indo embora.")
	_checkout.abandon()
	_reprimand("Você deixou o cliente ir embora sem pagar! Assim não dá.", day.timeout_bathroom)
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
		message += "\nE agora vai lavar o banheiro!"
		_bathroom.set_customer_patience(-1.0)
		_bathroom.start()
	_boss.say(message)
	_refresh_hud()


func _on_bathroom_cleaned() -> void:
	_bathroom_meter = 0.0
	_refresh_hud()
	_boss.say("Banheiro limpo. Volta pro caixa!")


func _end_day() -> void:
	_state = State.DAY_OVER
	_day_summary.present("Fim do Dia %d" % day.day_number, _results.summary_lines(day.customers.size()))


func _refresh_hud() -> void:
	_hud.refresh(day.day_number, _results.served, day.customers.size(), _results.earnings_cents(), _bathroom_meter)
