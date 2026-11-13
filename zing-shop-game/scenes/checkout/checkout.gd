class_name Checkout
extends Control

## Balcão do caixa: itens do cliente, scanner, sacola, monitor, maquininha, gaveta e mesa de troco.
## Conduz uma venda do escaneamento até o pagamento e avisa o resultado por sinais.

## Todos os itens foram registrados e o jogador cobrou; o pagamento começou.
signal payment_started
## A venda terminou. No dinheiro, traz o troco dado e o esperado; no cartão, os dois são 0.
signal sale_finished(correct: bool, given_cents: int, expected_cents: int)
## Todos os itens do cliente passaram pelo scanner.
signal all_items_scanned
## Com retry_wrong_change ligado: o troco entregue estava errado e o jogador pode tentar de novo.
signal change_rejected(given_cents: int, expected_cents: int)

enum State { IDLE, SCANNING, AWAITING_CARD, MAKING_CHANGE }

const ITEM_SCENE := preload("res://scenes/checkout/scannable_item.tscn")
const ITEM_SPACING := Vector2(84.0, 84.0)
const ITEM_THROW_INTERVAL := 0.15
const ITEM_FLIGHT_TIME := 0.6
const BAG_FLIGHT_TIME := 0.35

## Troco errado não encerra a venda: o troco volta para a mesa e o jogador corrige.
## Usado no treinamento (Prólogo).
var retry_wrong_change := false

var _state := State.IDLE
var _customer: CustomerData
var _items: Array[ScannableItem] = []
var _scanned_count := 0

@onready var _monitor: PosMonitor = %Monitor
@onready var _desk: Control = %Desk
@onready var _landing_area: Control = %ItemLandingArea
@onready var _scanner: Scanner = %Scanner
@onready var _bag: Control = %Bag
@onready var _card_machine: CardMachine = %CardMachine
@onready var _cash_drawer: CashDrawer = %CashDrawer
@onready var _change_tray: ChangeTray = %ChangeTray
@onready var _item_layer: Control = %ItemLayer


func _ready() -> void:
	_monitor.charge_requested.connect(_on_charge_requested)
	_card_machine.payment_approved.connect(_on_card_payment_approved)
	_cash_drawer.money_taken.connect(_change_tray.add_money)
	_change_tray.change_delivered.connect(_on_change_delivered)


## Começa a atender `customer`, que arremessa os itens a partir de `throw_from` (posição global).
func serve(customer: CustomerData, throw_from: Vector2) -> void:
	_customer = customer
	_scanned_count = 0
	_monitor.reset("Escaneie os itens")
	_spawn_items(throw_from)
	_state = State.SCANNING


## O cliente desistiu: cancela o pagamento e some com os itens da mesa.
func abandon() -> void:
	_state = State.IDLE
	_monitor.set_status("VENDA CANCELADA")
	_card_machine.reset()
	_set_cash_enabled(false)
	for item in _items:
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.create_tween().tween_property(item, "modulate:a", 0.0, 0.4)


## Limpa o balcão para o próximo cliente.
func clear() -> void:
	for item in _items:
		item.queue_free()
	_items.clear()
	_change_tray.clear()
	_card_machine.reset()
	_monitor.reset()
	_customer = null
	_state = State.IDLE


## O cliente arremessa os itens, um por um, em cima da mesa.
func _spawn_items(throw_from: Vector2) -> void:
	var landings := _pick_landing_spots(_customer.items.size())
	for i in _customer.items.size():
		var item: ScannableItem = ITEM_SCENE.instantiate()
		item.hide()
		_item_layer.add_child(item)
		item.setup(_customer.items[i], _scanner)
		item.scanned.connect(_on_item_scanned)
		item.released.connect(_on_item_released)
		_items.append(item)
		var from := throw_from - item.size / 2.0
		get_tree().create_timer(i * ITEM_THROW_INTERVAL, false).timeout.connect(
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
		all_items_scanned.emit()


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
	match _customer.payment_method:
		CustomerData.PaymentMethod.CARD:
			_monitor.set_status("Pagamento: cartão")
			_card_machine.activate()
			_state = State.AWAITING_CARD
		CustomerData.PaymentMethod.CASH:
			_monitor.show_received(_customer.cash_given_cents)
			_monitor.set_status("Pagamento: dinheiro. Separe o troco.")
			_set_cash_enabled(true)
			_state = State.MAKING_CHANGE
	payment_started.emit()


func _on_card_payment_approved() -> void:
	if _state == State.AWAITING_CARD:
		_finish(true, 0, 0)


func _on_change_delivered(given_cents: int) -> void:
	if _state != State.MAKING_CHANGE:
		return
	var expected := _customer.cash_given_cents - _customer.get_total_cents()
	if retry_wrong_change and given_cents != expected:
		change_rejected.emit(given_cents, expected)
		return
	_finish(given_cents == expected, given_cents, expected)


func _finish(correct: bool, given_cents: int, expected_cents: int) -> void:
	_state = State.IDLE
	_monitor.set_status("Venda concluída")
	_set_cash_enabled(false)
	sale_finished.emit(correct, given_cents, expected_cents)


func _set_cash_enabled(enabled: bool) -> void:
	_cash_drawer.enabled = enabled
	_change_tray.enabled = enabled
