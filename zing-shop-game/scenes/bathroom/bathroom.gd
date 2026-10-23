class_name Bathroom
extends Control

## Minigame do banheiro: segure o botão esquerdo e passe a mangueira sobre a sujeira.
## O fundo é uma foto; a sujeira, a mangueira e a água são pixel art desenhada por cima.
## A fila continua andando enquanto isso, só que mais devagar (ver DayData).

signal cleaned

const SPOT_COUNT := 9
## Tamanho de um "pixel" da sujeira, da mangueira e da água.
const PIXEL := 10.0
const SPRAY_RADIUS := 44.0
## Quanto de sujeira (0 a 1) a água remove por segundo de cada pixel.
const CLEAN_RATE := 2.2
## Fração de sujeira que pode sobrar, para o jogador não caçar pixel solto.
const CLEAN_TOLERANCE := 0.03
## Onde a sujeira aparece, em frações do tamanho da tela: corredor do vaso e paredes dos lados.
const DIRT_AREAS: Array[Rect2] = [
	Rect2(0.36, 0.22, 0.27, 0.72),
	Rect2(0.77, 0.18, 0.13, 0.62),
	Rect2(0.21, 0.12, 0.08, 0.72),
]
## Cores-base das manchas: marrom, verde-limo e amarelo-xixi.
const DIRT_PALETTES: Array[Color] = [Color("5c3a1e"), Color("6fae2e"), Color("d9b326")]
const HOSE_COLOR := Color("2f7d4a")
const NOZZLE_COLOR := Color("444450")
const WATER_COLOR := Color(0.55, 0.8, 1.0, 0.6)

@export var photo: Texture2D

## Pixels de sujeira em listas paralelas: canto superior esquerdo, cor e quanto falta limpar (0 a 1).
var _dirt_positions: PackedVector2Array = []
var _dirt_colors: PackedColorArray = []
var _dirt_amounts: PackedFloat32Array = []
var _spraying := false

@onready var _progress_label: Label = %ProgressLabel
@onready var _patience_box: Control = %PatienceBox
@onready var _patience_bar: ProgressBar = %PatienceBar


func start() -> void:
	_dirt_positions.clear()
	_dirt_colors.clear()
	_dirt_amounts.clear()
	var taken := {}
	for i in SPOT_COUNT:
		_add_spot(_random_spot_center(), DIRT_PALETTES.pick_random(), taken)
	_spraying = false
	_update_progress()
	show()


## Mostra a paciência do cliente que está no caixa; um valor negativo esconde a barra.
func set_customer_patience(ratio: float) -> void:
	_patience_box.visible = ratio >= 0.0
	_patience_bar.value = ratio * 100.0


func _gui_input(event: InputEvent) -> void:
	var mouse_button := event as InputEventMouseButton
	if mouse_button and mouse_button.button_index == MOUSE_BUTTON_LEFT:
		_spraying = mouse_button.pressed
		accept_event()


func _process(delta: float) -> void:
	if not visible:
		return
	queue_redraw()
	if not _spraying:
		return
	var nozzle := get_local_mouse_position()
	var half_pixel := Vector2(PIXEL, PIXEL) * 0.5
	for i in _dirt_amounts.size():
		if _dirt_amounts[i] > 0.0 and nozzle.distance_to(_dirt_positions[i] + half_pixel) <= SPRAY_RADIUS:
			_dirt_amounts[i] = maxf(_dirt_amounts[i] - CLEAN_RATE * delta, 0.0)
	_update_progress()
	if _remaining_dirt() <= CLEAN_TOLERANCE:
		_spraying = false
		hide()
		cleaned.emit()


## Sorteia o centro de uma mancha numa das áreas, com chance proporcional ao tamanho da área.
func _random_spot_center() -> Vector2:
	var total := 0.0
	for area in DIRT_AREAS:
		total += area.get_area()
	var roll := randf() * total
	for area in DIRT_AREAS:
		roll -= area.get_area()
		if roll <= 0.0:
			return (area.position + area.size * Vector2(randf(), randf())) * size
	return DIRT_AREAS[0].get_center() * size


## Uma mancha é um punhado de círculos rasterizados na grade de pixels, com contorno escuro.
func _add_spot(center: Vector2, base_color: Color, taken: Dictionary) -> void:
	var origin := Vector2i((center / PIXEL).floor())
	var blobs: Array[Vector3] = []
	for i in randi_range(3, 6):
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(0.0, 3.0)
		blobs.append(Vector3(offset.x, offset.y, randf_range(1.5, 3.5)))
	var cells := {}
	for y in range(-7, 8):
		for x in range(-7, 8):
			for blob in blobs:
				if Vector2(x, y).distance_to(Vector2(blob.x, blob.y)) <= blob.z:
					cells[origin + Vector2i(x, y)] = true
					break
	var outline := {}
	for cell: Vector2i in cells:
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not cells.has(cell + side):
				outline[cell + side] = true
	for cell: Vector2i in outline:
		_add_dirt_pixel(cell, base_color.darkened(0.6), taken)
	for cell: Vector2i in cells:
		var shade := base_color.lightened(0.35) if randf() < 0.08 else base_color.darkened(randf_range(0.0, 0.2))
		_add_dirt_pixel(cell, shade, taken)


## Pixels de manchas diferentes podem se sobrepor; o último desenhado vence.
func _add_dirt_pixel(cell: Vector2i, color: Color, taken: Dictionary) -> void:
	if taken.has(cell):
		_dirt_colors[taken[cell]] = color
		return
	taken[cell] = _dirt_amounts.size()
	_dirt_positions.append(Vector2(cell) * PIXEL)
	_dirt_colors.append(color)
	_dirt_amounts.append(1.0)


func _remaining_dirt() -> float:
	if _dirt_amounts.is_empty():
		return 0.0
	var remaining := 0.0
	for amount in _dirt_amounts:
		remaining += amount
	return remaining / _dirt_amounts.size()


func _update_progress() -> void:
	var cleaned_ratio := clampf((1.0 - _remaining_dirt()) / (1.0 - CLEAN_TOLERANCE), 0.0, 1.0)
	_progress_label.text = "Limpo: %d%%" % roundi(cleaned_ratio * 100.0)


func _draw() -> void:
	_draw_photo()
	var pixel_size := Vector2(PIXEL, PIXEL)
	for i in _dirt_amounts.size():
		if _dirt_amounts[i] > 0.0:
			# A sujeira some em degraus, para continuar com cara de pixel art.
			var alpha := ceilf(_dirt_amounts[i] * 4.0) / 4.0
			draw_rect(Rect2(_dirt_positions[i], pixel_size), Color(_dirt_colors[i], alpha))
	_draw_hose(get_local_mouse_position())


## A foto preenche a tela inteira, cortando as sobras para não distorcer.
func _draw_photo() -> void:
	if photo == null:
		return
	var texture_size := photo.get_size()
	var scale_factor := maxf(size.x / texture_size.x, size.y / texture_size.y)
	var source_size := size / scale_factor
	draw_texture_rect_region(photo, Rect2(Vector2.ZERO, size),
		Rect2((texture_size - source_size) * 0.5, source_size))


func _draw_hose(nozzle: Vector2) -> void:
	var hose_start := Vector2(size.x * 0.5, size.y + PIXEL * 2.0)
	var end := nozzle + Vector2(0.0, PIXEL * 3.0)
	# A mangueira cai um pouco entre a borda da tela e a mão.
	var sag := (hose_start + end) * 0.5 + Vector2(0.0, 120.0)
	var steps := int(hose_start.distance_to(end) / (PIXEL * 0.5)) + 2
	for i in steps + 1:
		var t := float(i) / steps
		var point := hose_start.lerp(sag, t).lerp(sag.lerp(end, t), t)
		draw_rect(Rect2(_snap(point), Vector2(PIXEL, PIXEL)), HOSE_COLOR)
	draw_rect(Rect2(_snap(nozzle + Vector2(-PIXEL * 0.5, PIXEL * 0.5)), Vector2(PIXEL, PIXEL * 2.5)), NOZZLE_COLOR)
	if _spraying:
		for i in 18:
			var drop := nozzle + Vector2.from_angle(randf() * TAU) * randf() * SPRAY_RADIUS
			draw_rect(Rect2(_snap(drop), Vector2(PIXEL, PIXEL)), WATER_COLOR if i % 4 else Color.WHITE)


func _snap(point: Vector2) -> Vector2:
	return (point / PIXEL).floor() * PIXEL
