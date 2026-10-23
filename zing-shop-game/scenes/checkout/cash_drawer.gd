class_name CashDrawer
extends PanelContainer

## Gaveta do caixa. Segure uma moeda/nota, ajuste a quantidade com o scroll ou as
## setas do teclado e solte para colocá-la na mesa. Botão direito ou Esc cancelam.

signal money_taken(value_cents: int, quantity: int)

const MAX_QUANTITY := 20
const HOLD_LABEL_OFFSET := Vector2(20.0, -70.0)
const MONEY_TEXT_COLOR := Color("1c1030")

var enabled := false:
	set(value):
		enabled = value
		for button in _buttons:
			button.disabled = not value
		if not value:
			_cancel_hold()

var _buttons: Array[Button] = []
var _held_value := 0
var _held_quantity := 0

@onready var _coins_row: HBoxContainer = %CoinsRow
@onready var _bills_row: HBoxContainer = %BillsRow
@onready var _hold_label: Label = %HoldLabel


## Aplica a aparência de moeda ou nota a um botão. Também usado pela mesa de troco.
static func style_money_button(button: Button, value_cents: int) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Money.color_of(value_cents)
	normal.border_color = normal.bg_color.darkened(0.45)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(32 if Money.is_coin(value_cents) else 4)
	normal.set_content_margin_all(4.0)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.2)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.15)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = normal.bg_color.darkened(0.5)

	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(color_name, MONEY_TEXT_COLOR)
	button.add_theme_color_override("font_disabled_color", Color(MONEY_TEXT_COLOR, 0.5))
	button.add_theme_font_size_override("font_size", 12)


func _ready() -> void:
	for value in Money.COINS:
		_coins_row.add_child(_make_button(value))
	for value in Money.BILLS:
		_bills_row.add_child(_make_button(value))
	enabled = false


func _input(event: InputEvent) -> void:
	if _held_value == 0:
		return
	if event is InputEventMouseMotion:
		_hold_label.global_position = get_global_mouse_position() + HOLD_LABEL_OFFSET
		return
	var mouse_button := event as InputEventMouseButton
	if mouse_button:
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed:
			_release_hold()
			return
		if not mouse_button.pressed:
			return
		match mouse_button.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_change_quantity(1)
			MOUSE_BUTTON_WHEEL_DOWN:
				_change_quantity(-1)
			MOUSE_BUTTON_RIGHT:
				_cancel_hold()
			_:
				return
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key and key.pressed:
		match key.keycode:
			KEY_UP, KEY_RIGHT:
				_change_quantity(1)
			KEY_DOWN, KEY_LEFT:
				_change_quantity(-1)
			KEY_ESCAPE:
				_cancel_hold()
			_:
				return
		get_viewport().set_input_as_handled()


func _make_button(value_cents: int) -> Button:
	var button := Button.new()
	button.text = Money.format_short(value_cents)
	button.custom_minimum_size = Vector2(44.0, 44.0) if Money.is_coin(value_cents) else Vector2(60.0, 36.0)
	button.tooltip_text = "Segure, ajuste a quantidade no scroll/setas e solte"
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	style_money_button(button, value_cents)
	button.button_down.connect(_start_hold.bind(value_cents))
	_buttons.append(button)
	return button


func _start_hold(value_cents: int) -> void:
	if not enabled:
		return
	_held_value = value_cents
	_held_quantity = 1
	_update_hold_label()
	_hold_label.global_position = get_global_mouse_position() + HOLD_LABEL_OFFSET
	_hold_label.show()


func _change_quantity(delta: int) -> void:
	_held_quantity = clampi(_held_quantity + delta, 0, MAX_QUANTITY)
	_update_hold_label()


func _release_hold() -> void:
	if _held_quantity > 0:
		money_taken.emit(_held_value, _held_quantity)
	_cancel_hold()


func _cancel_hold() -> void:
	_held_value = 0
	_held_quantity = 0
	if _hold_label:
		_hold_label.hide()


func _update_hold_label() -> void:
	if _held_quantity == 0:
		_hold_label.text = "Nenhuma (solte para cancelar)"
	else:
		_hold_label.text = "%d × %s = %s" % [_held_quantity, Money.format_short(_held_value),
			Money.format(_held_value * _held_quantity)]
	_hold_label.text += "\nscroll/setas: quantidade"
