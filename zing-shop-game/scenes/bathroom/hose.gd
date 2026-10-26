class_name Hose
extends Control

## Mangueira em pixel art que segue o mouse, vinda da borda de baixo. Solta água enquanto `spraying`.

## Alcance do jato de água a partir do bico.
const SPRAY_RADIUS := 44.0
## Tamanho de um "pixel" da mangueira e da água.
const PIXEL := 10.0
const HOSE_COLOR := Color("2f7d4a")
const NOZZLE_COLOR := Color("444450")
const WATER_COLOR := Color(0.55, 0.8, 1.0, 0.6)

var spraying := false


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var nozzle := get_local_mouse_position()
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
	if spraying:
		for i in 18:
			var drop := nozzle + Vector2.from_angle(randf() * TAU) * randf() * SPRAY_RADIUS
			draw_rect(Rect2(_snap(drop), Vector2(PIXEL, PIXEL)), WATER_COLOR if i % 4 else Color.WHITE)


func _snap(point: Vector2) -> Vector2:
	return (point / PIXEL).floor() * PIXEL
