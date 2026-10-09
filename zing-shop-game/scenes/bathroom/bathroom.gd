class_name Bathroom
extends Control

## Minigame do banheiro: segure o botão esquerdo e passe a mangueira sobre a sujeira.
## A fila continua andando enquanto isso, só que mais devagar (ver DayData).

signal cleaned

const SPOT_COUNT := 8
const SPRAY_RADIUS := 36.0
## Quanto de sujeira (0 a 1) a água remove por segundo.
const CLEAN_RATE := 0.9
const TILE_SIZE := 64.0
const TILE_COLOR := Color("d6e6f0")
const GROUT_COLOR := Color("b3c7d6")
const DIRT_COLOR := Color("5c4022")
const HOSE_COLOR := Color("2f7d4a")
const WATER_COLOR := Color(0.55, 0.8, 1.0, 0.55)


class DirtSpot:
	var center: Vector2
	var dirt := 1.0
	## x, y = deslocamento a partir do centro; z = raio.
	var blobs: Array[Vector3] = []
	## Distância do centro até a borda mais longe da mancha.
	var reach := 0.0


var _spots: Array[DirtSpot] = []
var _spraying := false

@onready var _progress_label: Label = %ProgressLabel
@onready var _patience_box: Control = %PatienceBox
@onready var _patience_bar: ProgressBar = %PatienceBar


func start() -> void:
	_spots.clear()
	for i in SPOT_COUNT:
		var spot := DirtSpot.new()
		spot.center = Vector2(randf_range(120.0, size.x - 280.0), randf_range(270.0, size.y - 110.0))
		for j in randi_range(4, 7):
			var offset := Vector2.from_angle(randf() * TAU) * randf_range(0.0, 34.0)
			var radius := randf_range(14.0, 30.0)
			spot.blobs.append(Vector3(offset.x, offset.y, radius))
			spot.reach = maxf(spot.reach, offset.length() + radius)
		_spots.append(spot)
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
	for spot in _spots:
		if spot.dirt > 0.0 and nozzle.distance_to(spot.center) <= spot.reach + SPRAY_RADIUS:
			spot.dirt = maxf(spot.dirt - CLEAN_RATE * delta, 0.0)
	_update_progress()
	if _spots.all(func(spot: DirtSpot) -> bool: return spot.dirt <= 0.0):
		_spraying = false
		hide()
		cleaned.emit()


func _update_progress() -> void:
	var remaining := 0.0
	for spot in _spots:
		remaining += spot.dirt
	var percent := roundi((1.0 - remaining / _spots.size()) * 100.0)
	_progress_label.text = "Limpo: %d%%" % percent


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), TILE_COLOR)
	for x in range(0, int(size.x) + 1, int(TILE_SIZE)):
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), GROUT_COLOR, 2.0)
	for y in range(0, int(size.y) + 1, int(TILE_SIZE)):
		draw_line(Vector2(0.0, y), Vector2(size.x, y), GROUT_COLOR, 2.0)
	_draw_toilet(Vector2(size.x - 220.0, 260.0))

	for spot in _spots:
		var color := Color(DIRT_COLOR, spot.dirt * 0.9)
		for blob in spot.blobs:
			draw_circle(spot.center + Vector2(blob.x, blob.y), blob.z, color)

	var nozzle := get_local_mouse_position()
	draw_line(Vector2(size.x * 0.5, size.y + 20.0), nozzle + Vector2(0.0, 28.0), HOSE_COLOR, 10.0)
	draw_rect(Rect2(nozzle + Vector2(-6.0, 6.0), Vector2(12.0, 24.0)), Color("444450"))
	if _spraying:
		draw_circle(nozzle, SPRAY_RADIUS, WATER_COLOR)
		for i in 8:
			var drop := nozzle + Vector2.from_angle(randf() * TAU) * randf() * SPRAY_RADIUS * 1.3
			draw_circle(drop, randf_range(2.0, 5.0), Color.WHITE)


func _draw_toilet(origin: Vector2) -> void:
	var porcelain := Color("fafafa")
	var shadow := Color("c9d3da")
	draw_rect(Rect2(origin, Vector2(110.0, 70.0)), porcelain)
	draw_rect(Rect2(origin, Vector2(110.0, 70.0)), shadow, false, 3.0)
	draw_rect(Rect2(origin + Vector2(20.0, 120.0), Vector2(70.0, 90.0)), porcelain)
	draw_circle(origin + Vector2(55.0, 115.0), 55.0, porcelain)
	draw_arc(origin + Vector2(55.0, 115.0), 55.0, 0.0, TAU, 40, shadow, 3.0)
	draw_circle(origin + Vector2(55.0, 115.0), 34.0, Color("bfe0f2"))
