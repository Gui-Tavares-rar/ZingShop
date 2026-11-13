class_name BathroomDirt
extends Control

## Sujeira em pixel art espalhada por cima da foto do banheiro. Cada pixel some aos poucos
## quando a água passa por ele.

## Tamanho de um "pixel" da sujeira.
const PIXEL := 10.0
## Onde a sujeira aparece, em frações do tamanho do nó: corredor do vaso e paredes dos lados.
const AREAS: Array[Rect2] = [
	Rect2(0.36, 0.22, 0.27, 0.72),
	Rect2(0.77, 0.18, 0.13, 0.62),
	Rect2(0.21, 0.12, 0.08, 0.72),
]
## Cores-base das manchas: marrom, verde-limo e amarelo-xixi.
const PALETTES: Array[Color] = [Color("5c3a1e"), Color("6fae2e"), Color("d9b326")]

## Pixels de sujeira em listas paralelas: canto superior esquerdo, cor e quanto falta limpar (0 a 1).
var _positions: PackedVector2Array = []
var _colors: PackedColorArray = []
var _amounts: PackedFloat32Array = []


## Troca a sujeira atual por `spot_count` manchas novas em lugares aleatórios.
func spawn(spot_count: int) -> void:
	_positions.clear()
	_colors.clear()
	_amounts.clear()
	var taken := {}
	for i in spot_count:
		_add_spot(_random_spot_center(), PALETTES.pick_random(), taken)
	queue_redraw()


## Tira `amount` de sujeira de cada pixel a até `radius` de `global_point`.
func clean_at(global_point: Vector2, radius: float, amount: float) -> void:
	var point := get_global_transform().affine_inverse() * global_point
	var half_pixel := Vector2(PIXEL, PIXEL) * 0.5
	for i in _amounts.size():
		if _amounts[i] > 0.0 and point.distance_to(_positions[i] + half_pixel) <= radius:
			_amounts[i] = maxf(_amounts[i] - amount, 0.0)
	queue_redraw()


## Fração da sujeira que ainda falta limpar, de 0 a 1.
func remaining() -> float:
	if _amounts.is_empty():
		return 0.0
	var total := 0.0
	for amount in _amounts:
		total += amount
	return total / _amounts.size()


func _draw() -> void:
	var pixel_size := Vector2(PIXEL, PIXEL)
	for i in _amounts.size():
		if _amounts[i] > 0.0:
			# A sujeira some em degraus, para continuar com cara de pixel art.
			var alpha := ceilf(_amounts[i] * 4.0) / 4.0
			draw_rect(Rect2(_positions[i], pixel_size), Color(_colors[i], alpha))


## Sorteia o centro de uma mancha numa das áreas, com chance proporcional ao tamanho da área.
func _random_spot_center() -> Vector2:
	var total := 0.0
	for area in AREAS:
		total += area.get_area()
	var roll := randf() * total
	for area in AREAS:
		roll -= area.get_area()
		if roll <= 0.0:
			return (area.position + area.size * Vector2(randf(), randf())) * size
	return AREAS[0].get_center() * size


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
		_add_pixel(cell, base_color.darkened(0.6), taken)
	for cell: Vector2i in cells:
		var shade := base_color.lightened(0.35) if randf() < 0.08 else base_color.darkened(randf_range(0.0, 0.2))
		_add_pixel(cell, shade, taken)


## Pixels de manchas diferentes podem se sobrepor; o último desenhado vence.
func _add_pixel(cell: Vector2i, color: Color, taken: Dictionary) -> void:
	if taken.has(cell):
		_colors[taken[cell]] = color
		return
	taken[cell] = _amounts.size()
	_positions.append(Vector2(cell) * PIXEL)
	_colors.append(color)
	_amounts.append(1.0)
