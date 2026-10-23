class_name ChangeTray
extends PanelContainer

## Mesa onde o troco é montado antes de entregar. Clicar numa pilha devolve uma unidade à gaveta.

signal change_delivered(total_cents: int)

var enabled := false:
	set(value):
		enabled = value
		if is_node_ready():
			_refresh()

var _pieces: Dictionary[int, int] = {}

@onready var _total_label: Label = %TotalLabel
@onready var _pieces_flow: HFlowContainer = %Pieces
@onready var _clear_button: Button = %ClearButton
@onready var _deliver_button: Button = %DeliverButton


func _ready() -> void:
	_clear_button.pressed.connect(clear)
	_deliver_button.pressed.connect(func() -> void: change_delivered.emit(get_total()))
	_refresh()


func add_money(value_cents: int, quantity: int) -> void:
	_pieces[value_cents] = _pieces.get(value_cents, 0) + quantity
	_refresh()


func clear() -> void:
	_pieces.clear()
	_refresh()


func get_total() -> int:
	var total := 0
	for value in _pieces:
		total += value * _pieces[value]
	return total


func _remove_one(value_cents: int) -> void:
	if not enabled:
		return
	_pieces[value_cents] -= 1
	if _pieces[value_cents] <= 0:
		_pieces.erase(value_cents)
	_refresh()


func _refresh() -> void:
	for chip in _pieces_flow.get_children():
		chip.queue_free()
	var values := _pieces.keys()
	values.sort()
	values.reverse()
	for value: int in values:
		var chip := Button.new()
		chip.text = "%d× %s" % [_pieces[value], Money.format_short(value)]
		chip.tooltip_text = "Clique para devolver uma à gaveta"
		chip.disabled = not enabled
		CashDrawer.style_money_button(chip, value)
		chip.pressed.connect(_remove_one.bind(value))
		_pieces_flow.add_child(chip)
	_total_label.text = "Troco na mesa: " + Money.format(get_total())
	_clear_button.disabled = not enabled or _pieces.is_empty()
	_deliver_button.disabled = not enabled
