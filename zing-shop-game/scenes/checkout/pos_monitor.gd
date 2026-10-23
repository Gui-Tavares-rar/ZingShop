class_name PosMonitor
extends PanelContainer

## Tela do computador do caixa: itens registrados, total, valor recebido e botão de cobrar.

signal charge_requested

const TEXT_COLOR := Color("7dffa8")

var _total_cents := 0

@onready var _scroll: ScrollContainer = %Scroll
@onready var _lines: VBoxContainer = %Lines
@onready var _total_label: Label = %TotalLabel
@onready var _received_label: Label = %ReceivedLabel
@onready var _status_label: Label = %StatusLabel
@onready var _charge_button: Button = %ChargeButton


func _ready() -> void:
	_charge_button.pressed.connect(charge_requested.emit)
	reset()


func reset(status: String = "Aguardando cliente...") -> void:
	for line in _lines.get_children():
		line.queue_free()
	_total_cents = 0
	_total_label.text = "TOTAL  " + Money.format(0)
	_received_label.hide()
	_status_label.text = status
	_charge_button.disabled = true


func add_item(item: ItemData) -> void:
	var line := HBoxContainer.new()
	var name_label := _make_label(item.display_name)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name_label)
	line.add_child(_make_label(Money.format(item.price_cents)))
	_lines.add_child(line)
	_total_cents += item.price_cents
	_total_label.text = "TOTAL  " + Money.format(_total_cents)
	await get_tree().process_frame
	if is_instance_valid(line):
		_scroll.ensure_control_visible(line)


func show_received(cents: int) -> void:
	_received_label.text = "RECEBIDO  " + Money.format(cents)
	_received_label.show()


func set_status(text: String) -> void:
	_status_label.text = text


func set_charge_enabled(enabled: bool) -> void:
	_charge_button.disabled = not enabled


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label
