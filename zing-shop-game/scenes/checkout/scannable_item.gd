class_name ScannableItem
extends TextureRect

## Item do cliente. O jogador segura com o mouse e passa na frente do scanner.
## Tem uma física simples, só visual: é arremessado, cai na mesa, quica e para.

signal scanned(item: ScannableItem)
signal released(item: ScannableItem)

const SCANNED_TINT := Color(0.8, 1.0, 0.8)
const GRAVITY := 1800.0
## Fração da velocidade vertical que sobra a cada quique.
const BOUNCE := 0.35
## Abaixo desta velocidade de impacto o item para de quicar.
const MIN_BOUNCE_SPEED := 150.0
## Fração da velocidade horizontal que sobra a cada quique (baixa, para o item não escorregar longe).
const BOUNCE_SLIDE := 0.1
## Fração do giro que sobra a cada quique.
const BOUNCE_SPIN := 0.4
const MAX_SPIN := 7.0

var data: ItemData
var is_scanned := false

## O item é registrado quando o centro dele passa por cima deste nó.
var _scanner: Control
var _dragging := false
var _grab_offset := Vector2.ZERO
var _airborne := false
var _velocity := Vector2.ZERO
var _spin := 0.0
## Altura (position.y) da superfície onde o item vai parar.
var _floor_y := 0.0


func setup(item_data: ItemData, scanner: Control) -> void:
	data = item_data
	_scanner = scanner
	texture = item_data.texture
	tooltip_text = item_data.display_name


## Arremessa o item em arco de `from` até `landing` (posições no pai), levando `flight_time` segundos.
func throw_to(from: Vector2, landing: Vector2, flight_time: float) -> void:
	position = from
	_floor_y = landing.y
	_velocity = Vector2(
		(landing.x - from.x) / flight_time,
		(landing.y - from.y - 0.5 * GRAVITY * flight_time * flight_time) / flight_time)
	# Mira um pouco antes para compensar o deslize do primeiro quique e parar perto de `landing`.
	var impact_speed := _velocity.y + GRAVITY * flight_time
	var slide := _velocity.x * BOUNCE_SLIDE * (2.0 * impact_speed * BOUNCE / GRAVITY)
	_velocity.x = (landing.x - slide - from.x) / flight_time
	_spin = randf_range(-MAX_SPIN, MAX_SPIN)
	_airborne = true
	show()


## Deixa o item cair reto até `floor_y`, se estiver acima dela.
func drop_to(floor_y: float) -> void:
	if position.y >= floor_y:
		return
	_floor_y = floor_y
	_velocity = Vector2.ZERO
	_spin = randf_range(-MAX_SPIN, MAX_SPIN) * 0.3
	_airborne = true


## Centro do item na tela. Como o pivô é o centro, ele não muda com a rotação
## (ao contrário de global_position e get_global_rect()).
func get_center() -> Vector2:
	return get_global_transform() * (size * 0.5)


func _set_center(global_center: Vector2) -> void:
	# Transformação do espaço do pai, obtida sem acessar o nó pai.
	var parent_transform := get_global_transform() * get_transform().affine_inverse()
	position = parent_transform.affine_inverse() * global_center - size * 0.5


func _gui_input(event: InputEvent) -> void:
	var mouse_button := event as InputEventMouseButton
	if mouse_button == null or mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_button.pressed:
		_dragging = true
		_airborne = false
		_grab_offset = get_center() - get_global_mouse_position()
		scale = Vector2.ONE * 1.15
		create_tween().tween_property(self, "rotation", 0.0, 0.1)
		move_to_front()
	elif _dragging:
		_dragging = false
		scale = Vector2.ONE
		released.emit(self)
	accept_event()


func _process(delta: float) -> void:
	if _dragging:
		_follow_mouse()
	elif _airborne:
		_simulate(delta)


func _follow_mouse() -> void:
	var half_size := size * 0.5
	_set_center((get_global_mouse_position() + _grab_offset).clamp(half_size, get_viewport_rect().size - half_size))
	if not is_scanned and _scanner.get_global_rect().has_point(get_center()):
		is_scanned = true
		modulate = SCANNED_TINT
		scanned.emit(self)


func _simulate(delta: float) -> void:
	_velocity.y += GRAVITY * delta
	position += _velocity * delta
	position.x = clampf(position.x, 0.0, get_viewport_rect().size.x - size.x)
	rotation += _spin * delta
	if position.y < _floor_y or _velocity.y < 0.0:
		return
	position.y = _floor_y
	if _velocity.y > MIN_BOUNCE_SPEED:
		_velocity = Vector2(_velocity.x * BOUNCE_SLIDE, -_velocity.y * BOUNCE)
		_spin *= BOUNCE_SPIN
	else:
		_airborne = false
		_velocity = Vector2.ZERO
		_spin = 0.0
