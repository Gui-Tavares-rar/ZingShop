extends Control

## Controla um dia de expediente: fila, atendimento, pagamento, paciência e banheiro.

enum State { NO_CUSTOMER, SCANNING, AWAITING_CARD, MAKING_CHANGE, CUSTOMER_LEAVING, DAY_OVER }

const ITEM_SCENE := preload("res://scenes/checkout/scannable_item.tscn")
const ITEM_SPACING := Vector2(84.0, 84.0)
const ITEM_THROW_INTERVAL := 0.15
const ITEM_FLIGHT_TIME := 0.6
const BAG_FLIGHT_TIME := 0.35
const CUSTOMER_EXIT_DELAY := 1.8
const BATHROOM_METER_MAX := 100.0
const BOSS_MESSAGE_TIME := 4.0
const QUEUE_FIGURE_SIZE := Vector2(52.0, 116.0)

@export var day: DayData

var _state := State.NO_CUSTOMER
var _clock := 0.0
## Clientes que ainda não chegaram, em ordem de chegada.
var _arrivals: Array[CustomerData] = []
var _queue: Array[CustomerData] = []
var _current: CustomerData
var _patience_left := 0.0
var _items: Array[ScannableItem] = []
var _scanned_count := 0
var _commission_cents := 0
var _penalty_cents := 0
var _served_count := 0
var _lost_count := 0
var _bathroom_meter := 0.0
var _boss_tween: Tween

@onready var _day_label: Label = %DayLabel
@onready var _served_label: Label = %ServedLabel
@onready var _earnings_label: Label = %EarningsLabel
@onready var _bathroom_bar: ProgressBar = %BathroomBar
@onready var _queue_row: HBoxContainer = %QueueRow
@onready var _customer_view: CustomerView = %CustomerView
@onready var _monitor: PosMonitor = %Monitor
@onready var _desk: Control = %Desk
@onready var _landing_area: Control = %ItemLandingArea
@onready var _scanner: Scanner = %Scanner
@onready var _bag: Control = %Bag
@onready var _card_machine: CardMachine = %CardMachine
@onready var _cash_drawer: CashDrawer = %CashDrawer
@onready var _change_tray: ChangeTray = %ChangeTray
@onready var _item_layer: Control = %ItemLayer
@onready var _bathroom: Bathroom = %Bathroom
@onready var _boss_toast: Control = %BossToast
@onready var _boss_label: Label = %BossLabel
@onready var _day_summary: DaySummary = %DaySummary


func _ready() -> void:
	_arrivals = day.customers.duplicate()
	_arrivals.sort_custom(func(a: CustomerData, b: CustomerData) -> bool: return a.arrival_time < b.arrival_time)
	_monitor.charge_requested.connect(_on_charge_requested)
	_card_machine.payment_approved.connect(_on_card_payment_approved)
	_cash_drawer.money_taken.connect(_change_tray.add_money)
	_change_tray.change_delivered.connect(_on_change_delivered)
	_bathroom.cleaned.connect(_on_bathroom_cleaned)
	_bathroom.hide()
	_day_summary.hide()
	_refresh_hud()
	_boss_says("Dia %d! Escaneie tudo, cobre certo e não deixe ninguém esperando." % day.day_number)


func _process(delta: float) -> void:
	if _state == State.DAY_OVER:
		return
	_clock += delta
	_admit_arrivals()
	match _state:
		State.NO_CUSTOMER:
			if not _queue.is_empty():
				_call_next_customer()
			elif _arrivals.is_empty() and not _bathroom.visible:
				_end_day()
		State.SCANNING, State.AWAITING_CARD, State.MAKING_CHANGE:
			_drain_patience(delta)


func _admit_arrivals() -> void:
	var changed := false
	while not _arrivals.is_empty() and _arrivals[0].arrival_time <= _clock:
		_queue.append(_arrivals.pop_front())
		changed = true
	if changed:
		_refresh_queue()


func _drain_patience(delta: float) -> void:
	var rate := day.bathroom_patience_multiplier if _bathroom.visible else 1.0
	_patience_left = maxf(_patience_left - delta * rate, 0.0)
	var ratio := _patience_left / _current.patience_seconds
	_customer_view.set_patience(ratio)
	_bathroom.set_customer_patience(ratio)
	if _patience_left <= 0.0:
		_customer_gives_up()


func _call_next_customer() -> void:
	_current = _queue.pop_front()
	_refresh_queue()
	_patience_left = _current.patience_seconds
	_scanned_count = 0
	_customer_view.present(_current)
	_customer_view.say(_current.greeting)
	_monitor.reset("Escaneie os itens")
	_spawn_items()
	_state = State.SCANNING


## O cliente arremessa os itens, um por um, em cima da mesa.
func _spawn_items() -> void:
	var landings := _pick_landing_spots(_current.items.size())
	var hands := _customer_view.get_hands_global_position()
	for i in _current.items.size():
		var item: ScannableItem = ITEM_SCENE.instantiate()
		item.hide()
		_item_layer.add_child(item)
		item.setup(_current.items[i], _scanner)
		item.scanned.connect(_on_item_scanned)
		item.released.connect(_on_item_released)
		_items.append(item)
		var from := hands - item.size / 2.0
		get_tree().create_timer(i * ITEM_THROW_INTERVAL).timeout.connect(
			item.throw_to.bind(from, landings[i], ITEM_FLIGHT_TIME))


## Sorteia onde cada item cai, sem empilhar: divide a área de pouso em células e embaralha.
func _pick_landing_spots(count: int) -> Array[Vector2]:
	var area := _landing_area.get_global_rect()
	var columns := maxi(int(area.size.x / ITEM_SPACING.x), 1)
	var rows := maxi(int(area.size.y / ITEM_SPACING.y), 1)
	var cells: Array[Vector2] = []
	for row in rows:
		for column in columns:
			cells.append(area.position + Vector2(column, row) * ITEM_SPACING)
	cells.shuffle()
	var spots: Array[Vector2] = []
	for i in count:
		spots.append(cells[i % cells.size()] + Vector2(randf_range(0.0, 12.0), randf_range(0.0, 12.0)))
	return spots


func _on_item_scanned(item: ScannableItem) -> void:
	if _state != State.SCANNING:
		return
	_scanner.beep()
	_monitor.add_item(item.data)
	_scanned_count += 1
	if _scanned_count == _items.size():
		_monitor.set_status("Todos os itens registrados")
		_monitor.set_charge_enabled(true)


## Item escaneado é jogado na sacola ao soltar; os outros caem de volta na mesa se forem soltos no ar.
func _on_item_released(item: ScannableItem) -> void:
	if not item.is_scanned:
		item.drop_to(_desk.get_global_rect().position.y + randf_range(8.0, 40.0))
		return
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bag := _bag.get_global_rect()
	var target := Vector2(
		randf_range(bag.position.x + 8.0, bag.end.x - item.size.x - 8.0),
		randf_range(bag.position.y + 36.0, bag.end.y - item.size.y - 8.0))
	item.throw_to(item.position, target, BAG_FLIGHT_TIME)


func _on_charge_requested() -> void:
	if _state != State.SCANNING or _scanned_count < _items.size():
		return
	_monitor.set_charge_enabled(false)
	match _current.payment_method:
		CustomerData.PaymentMethod.CARD:
			_customer_view.say("Vou pagar no cartão.")
			_monitor.set_status("Pagamento: cartão")
			_card_machine.activate()
			_state = State.AWAITING_CARD
		CustomerData.PaymentMethod.CASH:
			_customer_view.say("Aqui, %s em dinheiro." % Money.format(_current.cash_given_cents))
			_monitor.show_received(_current.cash_given_cents)
			_monitor.set_status("Pagamento: dinheiro. Separe o troco.")
			_cash_drawer.enabled = true
			_change_tray.enabled = true
			_state = State.MAKING_CHANGE


func _on_card_payment_approved() -> void:
	if _state == State.AWAITING_CARD:
		_finish_sale(true, "Obrigado, tchau!")


func _on_change_delivered(given_cents: int) -> void:
	if _state != State.MAKING_CHANGE:
		return
	var expected := _current.cash_given_cents - _current.get_total_cents()
	if given_cents == expected:
		_finish_sale(true, "Obrigado! Até mais.")
		return
	_finish_sale(false, "Ei, tá faltando troco!" if given_cents < expected else "Hã? Esse troco tá errado!")
	_penalty_cents += day.wrong_change_penalty_cents
	_reprimand("Troco errado! Era %s e você deu %s. Vou descontar %s do seu dia." % [
		Money.format(expected), Money.format(given_cents), Money.format(day.wrong_change_penalty_cents)],
		day.wrong_change_bathroom)


func _finish_sale(happy: bool, line: String) -> void:
	_served_count += 1
	_commission_cents += roundi(_current.get_total_cents() * day.commission_rate)
	_customer_view.set_mood(PersonFigure.Mood.HAPPY if happy else PersonFigure.Mood.ANGRY)
	_customer_view.say(line)
	_monitor.set_status("Venda concluída")
	_cash_drawer.enabled = false
	_change_tray.enabled = false
	_dismiss_customer_later()


func _customer_gives_up() -> void:
	_lost_count += 1
	_customer_view.set_mood(PersonFigure.Mood.ANGRY)
	_customer_view.say("Cansei de esperar! Tô indo embora.")
	_monitor.set_status("VENDA CANCELADA")
	_card_machine.reset()
	_cash_drawer.enabled = false
	_change_tray.enabled = false
	for item in _items:
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.create_tween().tween_property(item, "modulate:a", 0.0, 0.4)
	_reprimand("Você deixou o cliente ir embora sem pagar! Assim não dá.", day.timeout_bathroom)
	_dismiss_customer_later()


func _dismiss_customer_later() -> void:
	_state = State.CUSTOMER_LEAVING
	_refresh_hud()
	get_tree().create_timer(CUSTOMER_EXIT_DELAY).timeout.connect(_dismiss_customer)


func _dismiss_customer() -> void:
	for item in _items:
		item.queue_free()
	_items.clear()
	_change_tray.clear()
	_card_machine.reset()
	_customer_view.leave()
	_bathroom.set_customer_patience(-1.0)
	_monitor.reset()
	_current = null
	_state = State.NO_CUSTOMER


## Bronca do chefe. Enche o medidor do banheiro e, se lotar, manda o jogador lavar.
func _reprimand(message: String, bathroom_amount: float) -> void:
	_bathroom_meter = minf(_bathroom_meter + bathroom_amount, BATHROOM_METER_MAX)
	if _bathroom_meter >= BATHROOM_METER_MAX and not _bathroom.visible:
		message += "\nE agora vai lavar o banheiro!"
		_bathroom.set_customer_patience(-1.0)
		_bathroom.start()
	_boss_says(message)
	_refresh_hud()


func _on_bathroom_cleaned() -> void:
	_bathroom_meter = 0.0
	_refresh_hud()
	_boss_says("Banheiro limpo. Volta pro caixa!")


func _boss_says(message: String) -> void:
	_boss_label.text = "CHEFE: " + message
	_boss_toast.modulate.a = 1.0
	_boss_toast.show()
	if _boss_tween:
		_boss_tween.kill()
	_boss_tween = create_tween()
	_boss_tween.tween_interval(BOSS_MESSAGE_TIME)
	_boss_tween.tween_property(_boss_toast, "modulate:a", 0.0, 0.4)
	_boss_tween.tween_callback(_boss_toast.hide)


func _end_day() -> void:
	_state = State.DAY_OVER
	_day_summary.present("Fim do Dia %d" % day.day_number, PackedStringArray([
		"Clientes atendidos: %d de %d" % [_served_count, day.customers.size()],
		"Foram embora: %d" % _lost_count,
		"Comissões: %s" % Money.format(_commission_cents),
		"Descontos do chefe: %s" % Money.format(-_penalty_cents),
		"",
		"Ganho do dia: %s" % Money.format(_commission_cents - _penalty_cents),
	]))


func _refresh_hud() -> void:
	_day_label.text = "Dia %d" % day.day_number
	_served_label.text = "Atendidos: %d/%d" % [_served_count, day.customers.size()]
	_earnings_label.text = "Ganho do dia: " + Money.format(_commission_cents - _penalty_cents)
	_bathroom_bar.value = _bathroom_meter


func _refresh_queue() -> void:
	for figure in _queue_row.get_children():
		_queue_row.remove_child(figure)
		figure.queue_free()
	# A fila cresce para a esquerda: o primeiro da fila fica mais perto do caixa.
	for i in range(_queue.size() - 1, -1, -1):
		var figure := PersonFigure.new()
		figure.body_color = _queue[i].body_color
		figure.custom_minimum_size = QUEUE_FIGURE_SIZE
		figure.size_flags_vertical = Control.SIZE_SHRINK_END
		figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_queue_row.add_child(figure)
